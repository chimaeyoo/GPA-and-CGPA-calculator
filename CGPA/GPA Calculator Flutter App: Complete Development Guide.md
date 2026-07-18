# CGPA/GPA Calculator Flutter App: Complete Development Guide

This document provides a comprehensive guide for building a Flutter-based CGPA/GPA calculator mobile application tailored for Nigerian universities and polytechnics. The app will feature local data storage using Hive, AdMob integration for monetization, and advanced calculation capabilities including grade replacement and degree classification.

## Project Structure

```
cgpa_calculator/
├── lib/
│   ├── models/
│   │   ├── academic_record.dart
│   │   ├── course.dart
│   │   ├── enums.dart
│   │   └── semester.dart
│   ├── screens/
│   │   ├── add_course_screen.dart
│   │   ├── home_screen.dart
│   │   ├── semester_detail_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── ad_manager.dart
│   │   ├── calculation_engine.dart
│   │   ├── feature_access_manager.dart
│   │   ├── pdf_generator.dart
│   │   └── storage_service.dart
│   └── main.dart
├── pubspec.yaml
├── README.md
└── build.yaml
```

## Complete Code Files Required:

### 1. `pubspec.yaml`

This file defines the project's dependencies and metadata. It includes packages for local storage (Hive), advertising (Google Mobile Ads), PDF generation, file sharing, and state management.

```yaml
name: cgpa_calculator
description: A CGPA/GPA calculator for Nigerian universities and polytechnics.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  hive_generator: ^2.0.1

  # State Management
  provider: ^6.0.5

  # Ads
  google_mobile_ads: ^5.0.0

  # PDF Generation
  pdf: ^3.10.8
  path_provider: ^2.1.3

  # Sharing
  share_plus: ^9.0.0

  # Utilities
  shared_preferences: ^2.2.3
  uuid: ^4.4.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.9

flutter:
  uses-material-design: true

  assets:
    - assets/images/

```

### 2. `lib/models/enums.dart`

This file defines the enums used throughout the application, specifically for grading scales.

```dart
import 'package:hive/hive.dart';

part 'enums.g.dart';

@HiveType(typeId: 0)
enum GradingScale {
  @HiveField(0)
  nuc5_0,
  @HiveField(1)
  nbte4_0,
}

```

### 3. `lib/models/academic_record.dart`

This Hive model represents an academic record, containing a unique ID, a user-defined name, the selected grading scale, and a flag for grade replacement.

```dart
import 'package:hive/hive.dart';
import 'package:cgpa_calculator/models/enums.dart';

part 'academic_record.g.dart';

@HiveType(typeId: 1)
class AcademicRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String recordName;

  @HiveField(2)
  GradingScale gradingScale;

  @HiveField(3)
  bool gradeReplacementEnabled;

  AcademicRecord({
    required this.id,
    required this.recordName,
    this.gradingScale = GradingScale.nuc5_0,
    this.gradeReplacementEnabled = false,
  });
}

```

### 4. `lib/models/semester.dart`

This Hive model represents a semester within an academic record, including its ID, name, year, and a reference to its parent academic record.

```dart
import 'package:hive/hive.dart';

part 'semester.g.dart';

@HiveType(typeId: 2)
class Semester extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int year;

  @HiveField(3)
  String academicRecordId;

  Semester({
    required this.id,
    required this.name,
    required this.year,
    required this.academicRecordId,
  });
}

```

### 5. `lib/models/course.dart`

This Hive model represents a single course, storing details such as course code, title, credit units, score, and its associated semester and attempt number.

```dart
import 'package:hive/hive.dart';

part 'course.g.dart';

@HiveType(typeId: 3)
class Course extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String courseCode;

  @HiveField(2)
  String courseTitle;

  @HiveField(3)
  double creditUnits;

  @HiveField(4)
  double score;

  @HiveField(5)
  String semesterId;

  @HiveField(6)
  int attemptNumber;

  Course({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnits,
    required this.score,
    required this.semesterId,
    this.attemptNumber = 1,
  });
}

```

### 6. `lib/services/calculation_engine.dart`

This service provides the core logic for GPA and CGPA calculations, handles different grading scales, grade replacement, credit load validation, and degree classification.

```dart
import 'dart:math';

import 'package:cgpa_calculator/models/academic_record.dart';
import 'package:cgpa_calculator/models/course.dart';
import 'package:cgpa_calculator/models/enums.dart';
import 'package:cgpa_calculator/models/semester.dart';

class CalculationEngine {
  // NUC 5.0 Grading Scale
  static const Map<String, double> _nuc5_0GradePoints = {
    'A': 5.0,
    'B': 4.0,
    'C': 3.0,
    'D': 2.0,
    'E': 1.0,
    'F': 0.0,
  };

  // NBTE 4.0 Grading Scale
  static const Map<String, double> _nbte4_0GradePoints = {
    'A': 4.0,
    'AB': 3.5,
    'B': 3.0,
    'BC': 2.5,
    'C': 2.0,
    'CD': 1.5,
    'D': 1.0,
    'F': 0.0,
  };

  // NUC 5.0 Score to Letter Grade
  static String _getNuc5_0LetterGrade(double score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  // NBTE 4.0 Score to Letter Grade
  static String _getNbte4_0LetterGrade(double score) {
    if (score >= 70) return 'A';
    if (score >= 65) return 'AB';
    if (score >= 60) return 'B';
    if (score >= 55) return 'BC';
    if (score >= 50) return 'C';
    if (score >= 45) return 'CD';
    if (score >= 40) return 'D';
    return 'F';
  }

  static double getQualityPoint(double score, GradingScale scale) {
    String letterGrade;
    Map<String, double> gradePointsMap;

    if (scale == GradingScale.nuc5_0) {
      letterGrade = _getNuc5_0LetterGrade(score);
      gradePointsMap = _nuc5_0GradePoints;
    } else {
      letterGrade = _getNbte4_0LetterGrade(score);
      gradePointsMap = _nbte4_0GradePoints;
    }
    return gradePointsMap[letterGrade] ?? 0.0;
  }

  static String getLetterGrade(double score, GradingScale scale) {
    if (scale == GradingScale.nuc5_0) {
      return _getNuc5_0LetterGrade(score);
    } else {
      return _getNbte4_0LetterGrade(score);
    }
  }

  static double calculateGPA(List<Course> courses, GradingScale scale) {
    if (courses.isEmpty) return 0.0;

    double totalQualityPoints = 0.0;
    double totalCreditUnits = 0.0;

    for (var course in courses) {
      totalQualityPoints += getQualityPoint(course.score, scale) * course.creditUnits;
      totalCreditUnits += course.creditUnits;
    }

    return totalCreditUnits == 0 ? 0.0 : totalQualityPoints / totalCreditUnits;
  }

  static double calculateCGPA(
    List<AcademicRecord> academicRecords,
    String currentRecordId,
    List<Semester> allSemesters,
    List<Course> allCourses,
  ) {
    double cumulativeQualityPoints = 0.0;
    double cumulativeCreditUnits = 0.0;

    AcademicRecord? currentRecord = academicRecords.firstWhere(
      (record) => record.id == currentRecordId,
    );

    List<Semester> semestersInRecord = allSemesters
        .where((semester) => semester.academicRecordId == currentRecordId)
        .toList();

    for (var semester in semestersInRecord) {
      List<Course> coursesInSemester = allCourses
          .where((course) => course.semesterId == semester.id)
          .toList();

      List<Course> effectiveCourses = _applyGradeReplacement(
        coursesInSemester,
        currentRecord.gradeReplacementEnabled,
      );

      for (var course in effectiveCourses) {
        cumulativeQualityPoints +=
            getQualityPoint(course.score, currentRecord.gradingScale) *
                course.creditUnits;
        cumulativeCreditUnits += course.creditUnits;
      }
    }

    return cumulativeCreditUnits == 0
        ? 0.0
        : cumulativeQualityPoints / cumulativeCreditUnits;
  }

  static List<Course> _applyGradeReplacement(List<Course> courses, bool enabled) {
    if (!enabled) return courses;

    Map<String, Course> bestAttempts = {};
    for (var course in courses) {
      String courseIdentifier = course.courseCode.toLowerCase();
      if (!bestAttempts.containsKey(courseIdentifier) ||
          bestAttempts[courseIdentifier]!.score < course.score) {
        bestAttempts[courseIdentifier] = course;
      }
    }
    return bestAttempts.values.toList();
  }

  static bool validateCreditLoad(List<Course> courses, GradingScale scale) {
    double totalCreditUnits = courses.fold(0.0, (sum, course) => sum + course.creditUnits);
    if (scale == GradingScale.nuc5_0) {
      return totalCreditUnits >= 15 && totalCreditUnits <= 24;
    } else if (scale == GradingScale.nbte4_0) {
      return totalCreditUnits >= 12 && totalCreditUnits <= 24;
    }
    return false; // Should not happen
  }

  static String getDegreeClassification(double cgpa, GradingScale scale) {
    if (scale == GradingScale.nuc5_0) {
      if (cgpa >= 4.50) return 'First Class Honours';
      if (cgpa >= 3.50) return 'Second Class Honours (Upper Division)';
      if (cgpa >= 2.40) return 'Second Class Honours (Lower Division)';
      if (cgpa >= 1.50) return 'Third Class Honours';
      if (cgpa >= 1.00) return 'Pass';
      return 'Fail';
    } else if (scale == GradingScale.nbte4_0) {
      if (cgpa >= 3.50) return 'Distinction';
      if (cgpa >= 3.00) return 'Upper Credit';
      if (cgpa >= 2.50) return 'Lower Credit';
      if (cgpa >= 2.00) return 'Pass';
      return 'Fail';
    }
    return 'N/A';
  }
}
```

### 7. `lib/services/ad_manager.dart`

This service handles the loading and displaying of Google Mobile Ads, specifically rewarded video ads for premium features and banner ads for general monetization.

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

class AdManager {
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;
  bool _isRewardedAdReady = false;

  // TODO: Replace with your actual AdMob ad unit IDs
  String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Test Ad Unit ID for Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test Ad Unit ID for iOS
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test Ad Unit ID for Android
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test Ad Unit ID for iOS
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('Rewarded ad loaded.');
        },
        onAdFailedToLoad: (err) {
          _rewardedAd = null;
          _isRewardedAdReady = false;
          print('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }

  void showRewardedAd(Function onUserEarnedReward) {
    if (_rewardedAd == null) {
      print('Warning: Attempt to show rewarded ad before it was ready.');
      loadRewardedAd(); // Try to load again if not ready
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => print('$ad onAdShowedFullScreenContent'),
      onAdDismissedFullScreenContent: (ad) {
        print('$ad onAdDismissedFullScreenContent');
        ad.dispose();
        _isRewardedAdReady = false;
        loadRewardedAd(); // Preload the next ad
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        print('$ad onAdFailedToShowFullScreenContent: $err');
        ad.dispose();
        _isRewardedAdReady = false;
        loadRewardedAd(); // Preload the next ad
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      print('${reward.amount} ${reward.type}');
      onUserEarnedReward();
    });
  }

  bool get isRewardedAdReady => _isRewardedAdReady;

  BannerAd getBannerAd() {
    _bannerAd ??= BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => print('Banner ad loaded.'),
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    )..load();
    return _bannerAd!;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
  }
}
```

### 8. `lib/services/feature_access_manager.dart`

This service manages access to premium features using `SharedPreferences` for time-limited unlocks after a rewarded ad is watched.

```dart
import 'package:shared_preferences/shared_preferences.dart';

class FeatureAccessManager {
  static const String _gradeTrackingKey = 'grade_tracking_unlocked_until';
  static const String _pdfExportKey = 'pdf_export_unlocked_until';

  Future<bool> isFeatureUnlocked(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockTimestamp = prefs.getInt(featureKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now < unlockTimestamp;
  }

  Future<void> unlockFeature(String featureKey, {Duration duration = const Duration(hours: 24)}) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockUntil = DateTime.now().add(duration).millisecondsSinceEpoch;
    await prefs.setInt(featureKey, unlockUntil);
  }

  // Feature keys
  static String get gradeTrackingFeatureKey => _gradeTrackingKey;
  static String get pdfExportFeatureKey => _pdfExportKey;
}
```

### 9. `lib/services/storage_service.dart`

This service provides CRUD operations for all Hive models: `AcademicRecord`, `Semester`, and `Course`.

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cgpa_calculator/models/academic_record.dart';
import 'package:cgpa_calculator/models/semester.dart';
import 'package:cgpa_calculator/models/course.dart';
import 'package:cgpa_calculator/models/enums.dart';

class StorageService {
  static const String _academicRecordBox = 'academicRecords';
  static const String _semesterBox = 'semesters';
  static const String _courseBox = 'courses';

  Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(GradingScaleAdapter());
    Hive.registerAdapter(AcademicRecordAdapter());
    Hive.registerAdapter(SemesterAdapter());
    Hive.registerAdapter(CourseAdapter());

    await Hive.openBox<AcademicRecord>(_academicRecordBox);
    await Hive.openBox<Semester>(_semesterBox);
    await Hive.openBox<Course>(_courseBox);
  }

  // AcademicRecord operations
  Box<AcademicRecord> get _academicRecordsBox => Hive.box<AcademicRecord>(_academicRecordBox);

  List<AcademicRecord> getAcademicRecords() {
    return _academicRecordsBox.values.toList();
  }

  Future<void> addAcademicRecord(AcademicRecord record) async {
    await _academicRecordsBox.put(record.id, record);
  }

  Future<void> updateAcademicRecord(AcademicRecord record) async {
    await record.save();
  }

  Future<void> deleteAcademicRecord(String recordId) async {
    await _academicRecordsBox.delete(recordId);
    // Also delete associated semesters and courses
    final semestersToDelete = getSemestersForRecord(recordId);
    for (var semester in semestersToDelete) {
      await deleteSemester(semester.id);
    }
  }

  // Semester operations
  Box<Semester> get _semestersBox => Hive.box<Semester>(_semesterBox);

  List<Semester> getSemestersForRecord(String academicRecordId) {
    return _semestersBox.values
        .where((semester) => semester.academicRecordId == academicRecordId)
        .toList();
  }

  Future<void> addSemester(Semester semester) async {
    await _semestersBox.put(semester.id, semester);
  }

  Future<void> updateSemester(Semester semester) async {
    await semester.save();
  }

  Future<void> deleteSemester(String semesterId) async {
    await _semestersBox.delete(semesterId);
    // Also delete associated courses
    final coursesToDelete = getCoursesForSemester(semesterId);
    for (var course in coursesToDelete) {
      await deleteCourse(course.id);
    }
  }

  // Course operations
  Box<Course> get _coursesBox => Hive.box<Course>(_courseBox);

  List<Course> getCoursesForSemester(String semesterId) {
    return _coursesBox.values
        .where((course) => course.semesterId == semesterId)
        .toList();
  }

  Future<void> addCourse(Course course) async {
    await _coursesBox.put(course.id, course);
  }

  Future<void> updateCourse(Course course) async {
    await course.save();
  }

  Future<void> deleteCourse(String courseId) async {
    await _coursesBox.delete(courseId);
  }

  List<Course> getAllCourses() {
    return _coursesBox.values.toList();
  }
}
```

### 10. `lib/services/pdf_generator.dart`

This service is responsible for generating professional-looking PDF reports for semesters and full academic transcripts, including student information, course details, and GPA/CGPA summaries.

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'package:cgpa_calculator/models/academic_record.dart';
import 'package:cgpa_calculator/models/course.dart';
import 'package:cgpa_calculator/models/semester.dart';
import 'package:cgpa_calculator/services/calculation_engine.dart';

class PdfGenerator {
  static Future<void> generateSemesterReport(
    AcademicRecord academicRecord,
    Semester semester,
    List<Course> courses,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    final gpa = CalculationEngine.calculateGPA(courses, academicRecord.gradingScale);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Academic Report - ${academicRecord.recordName}',
                style: pw.TextStyle(font: boldFont, fontSize: 24),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Semester: ${semester.name} ${semester.year}',
                style: pw.TextStyle(font: font, fontSize: 18),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: <String>[
                  'Course Code',
                  'Course Title',
                  'Credit Units',
                  'Score',
                  'Grade',
                  'Quality Point'
                ],
                data: courses.map((course) {
                  final letterGrade = CalculationEngine.getLetterGrade(
                      course.score, academicRecord.gradingScale);
                  final qualityPoint = CalculationEngine.getQualityPoint(
                      course.score, academicRecord.gradingScale);
                  return [
                    course.courseCode,
                    course.courseTitle,
                    course.creditUnits.toStringAsFixed(1),
                    course.score.toStringAsFixed(0),
                    letterGrade,
                    qualityPoint.toStringAsFixed(1),
                  ];
                }).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(font: boldFont),
                cellStyle: pw.TextStyle(font: font),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                  5: const pw.FlexColumnWidth(1.5),
                },
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Semester GPA: ${gpa.toStringAsFixed(2)}',
                style: pw.TextStyle(font: boldFont, fontSize: 16),
              ),
            ],
          );
        },
      ),
    );

    await _saveAndSharePdf(pdf, '${academicRecord.recordName}_${semester.name}_${semester.year}_Report.pdf');
  }

  static Future<void> generateFullAcademicTranscript(
    AcademicRecord academicRecord,
    List<Semester> semesters,
    List<Course> allCourses,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.openSansRegular();
    final boldFont = await PdfGoogleFonts.openSansBold();

    double cumulativeQualityPoints = 0.0;
    double cumulativeCreditUnits = 0.0;

    for (var semester in semesters) {
      final coursesInSemester = allCourses
          .where((course) => course.semesterId == semester.id)
          .toList();

      final effectiveCourses = CalculationEngine._applyGradeReplacement(
        coursesInSemester,
        academicRecord.gradeReplacementEnabled,
      );

      double semesterQualityPoints = 0.0;
      double semesterCreditUnits = 0.0;

      for (var course in effectiveCourses) {
        semesterQualityPoints += CalculationEngine.getQualityPoint(
                course.score, academicRecord.gradingScale) *
            course.creditUnits;
        semesterCreditUnits += course.creditUnits;
      }

      cumulativeQualityPoints += semesterQualityPoints;
      cumulativeCreditUnits += semesterCreditUnits;

      final gpa = semesterCreditUnits == 0
          ? 0.0
          : semesterQualityPoints / semesterCreditUnits;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Text(
              'Academic Transcript - ${academicRecord.recordName}',
              style: pw.TextStyle(font: boldFont, fontSize: 24),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Semester: ${semester.name} ${semester.year}',
              style: pw.TextStyle(font: font, fontSize: 18),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: <String>[
                'Course Code',
                'Course Title',
                'Credit Units',
                'Score',
                'Grade',
                'Quality Point'
              ],
              data: effectiveCourses.map((course) {
                final letterGrade = CalculationEngine.getLetterGrade(
                    course.score, academicRecord.gradingScale);
                final qualityPoint = CalculationEngine.getQualityPoint(
                    course.score, academicRecord.gradingScale);
                return [
                  course.courseCode,
                  course.courseTitle,
                  course.creditUnits.toStringAsFixed(1),
                  course.score.toStringAsFixed(0),
                  letterGrade,
                  qualityPoint.toStringAsFixed(1),
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(font: boldFont),
              cellStyle: pw.TextStyle(font: font),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1.5),
              },
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Semester GPA: ${gpa.toStringAsFixed(2)}',
              style: pw.TextStyle(font: boldFont, fontSize: 14),
            ),
            pw.Divider(),
          ],
        ),
      );
    }

    final cgpa = cumulativeCreditUnits == 0
        ? 0.0
        : cumulativeQualityPoints / cumulativeCreditUnits;
    final classification = CalculationEngine.getDegreeClassification(
        cgpa, academicRecord.gradingScale);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Cumulative Grade Point Average (CGPA)',
                  style: pw.TextStyle(font: boldFont, fontSize: 20),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  cgpa.toStringAsFixed(2),
                  style: pw.TextStyle(font: boldFont, fontSize: 48),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Degree Classification: $classification',
                  style: pw.TextStyle(font: boldFont, fontSize: 20),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Report Generated: ${DateFormat.yMMMd().add_jm().format(DateTime.now())}',
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    await _saveAndSharePdf(pdf, '${academicRecord.recordName}_Full_Transcript.pdf');
  }

  static Future<void> _saveAndSharePdf(pw.Document pdf, String filename) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$filename');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([XFile(file.path)], text: 'Here is your CGPA report!');
    } catch (e) {
      print('Error saving or sharing PDF: $e');
      // Handle error, e.g., show a toast message to the user
    }
  }
}
```

### 11. `lib/main.dart`

This is the entry point of the Flutter application. It initializes Hive, sets up the app's theme, and defines the routing for different screens.

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:cgpa_calculator/models/academic_record.dart';
import 'package:cgpa_calculator/models/course.dart';
import 'package:cgpa_calculator/models/enums.dart';
import 'package:cgpa_calculator/models/semester.dart';
import 'package:cgpa_calculator/services/storage_service.dart';
import 'package:cgpa_calculator/services/ad_manager.dart';
import 'package:cgpa_calculator/services/feature_access_manager.dart';

import 'package:cgpa_calculator/screens/home_screen.dart';
import 'package:cgpa_calculator/screens/add_course_screen.dart';
import 'package:cgpa_calculator/screens/semester_detail_screen.dart';
import 'package:cgpa_calculator/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();

  final storageService = StorageService();
  await storageService.initHive();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>(create: (_) => storageService),
        Provider<AdManager>(create: (_) => AdManager()..loadRewardedAd()),
        Provider<FeatureAccessManager>(create: (_) => FeatureAccessManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CGPA Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/add_course': (context) => AddCourseScreen(),
        '/semester_detail': (context) => SemesterDetailScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
```

### 12. `lib/screens/home_screen.dart`

This screen serves as the main dashboard, displaying the overall CGPA, a list of academic records, and quick actions for managing records and accessing features.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:cgpa_calculator/models/academic_record.dart';
import 'package:cgpa_calculator/models/enums.dart';
import 'package:cgpa_calculator/services/storage_service.dart';
import 'package:cgpa_calculator/services/calculation_engine.dart';
import 'package:cgpa_calculator/services/ad_manager.dart';
import 'package:cgpa_calculator/services/feature_access_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AcademicRecord? _selectedRecord;
  List<AcademicRecord> _academicRecords = [];

  @override
  void initState() {
    super.initState();
    _loadAcademicRecords();
  }

  Future<void> _loadAcademicRecords() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    _academicRecords = storageService.getAcademicRecords();
    if (_academicRecords.isNotEmpty && _selectedRecord == null) {
      _selectedRecord = _academicRecords.first;
    }
    setState(() {});
  }

  Future<void> _addAcademicRecord() async {
    String? recordName = await _showTextInputDialog(context, 'New Academic Record', 'Enter record name');
    if (recordName != null && recordName.isNotEmpty) {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final newRecord = AcademicRecord(
        id: const Uuid().v4(),
        recordName: recordName,
      );
      await storageService.addAcademicRecord(newRecord);
      _loadAcademicRecords();
    }
  }

  Future<void> _deleteAcademicRecord(AcademicRecord record) async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    await storageService.deleteAcademicRecord(record.id);
    _selectedRecord = null;
    _loadAcademicRecords();
  }

  Future<String?> _showTextInputDialog(BuildContext context, String title, String label) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final adManager = Provider.of<AdManager>(context);
    final featureAccessManager = Provider.of<FeatureAccessManager>(context);

    double currentCgpa = 0.0;
    String classification = 'N/A';

    if (_selectedRecord != null) {
      final allSemesters = storageService.getSemestersForRecord(_selectedRecord!.id);
      final allCourses = storageService.getAllCourses(); // This should ideally be filtered by academic record

      currentCgpa = CalculationEngine.calculateCGPA(
        _academicRecords,
        _selectedRecord!.id,
        allSemesters,
        allCourses,
      );
      classification = CalculationEngine.getDegreeClassification(
        currentCgpa,
        _selectedRecord!.gradingScale,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
        actions: [
          if (_selectedRecord != null)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/settings', arguments: _selectedRecord!.id)
                    .then((_) => _loadAcademicRecords());
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blueGrey,
              ),
              child: Text(
                'Academic Records',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ..._academicRecords.map((record) => ListTile(
              title: Text(record.recordName),
              selected: _selectedRecord?.id == record.id,
              onTap: () {
                setState(() {
                  _selectedRecord = record;
                });
                Navigator.pop(context);
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteAcademicRecord(record),
              ),
            )).toList(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add New Record'),
              onTap: () {
                Navigator.pop(context);
                _addAcademicRecord();
              },
            ),
          ],
        ),
      ),
      body: _selectedRecord == null
          ? const Center(
              child: Text(
                'Please add an academic record to get started.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '${_selectedRecord!.recordName} CGPA',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currentCgpa.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Classification: $classification',
                            style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Semester>>(
                    future: Future.value(storageService.getSemestersForRecord(_selectedRecord!.id)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No semesters added yet. Tap + to add one.'),
                        );
                      }
                      final semesters = snapshot.data!;
                      return ListView.builder(
                        itemCount: semesters.length,
                        itemBuilder: (context, index) {
                          final semester = semesters[index];
                          final coursesInSemester = storageService.getCoursesForSemester(semester.id);
                          final gpa = CalculationEngine.calculateGPA(coursesInSemester, _selectedRecord!.gradingScale);
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text('${semester.name} ${semester.year}'),
                              subtitle: Text('GPA: ${gpa.toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context, 
                                    '/semester_detail', 
                                    arguments: {'semesterId': semester.id, 'academicRecordId': _selectedRecord!.id}
                                  ).then((_) => _loadAcademicRecords());
                                },
                              ),
                              onLongPress: () async {
                                // Option to delete semester
                                final confirmDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Semester'),
                                    content: Text('Are you sure you want to delete ${semester.name} ${semester.year}? This will also delete all courses in it.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirmDelete == true) {
                                  await storageService.deleteSemester(semester.id);
                                  _loadAcademicRecords();
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (adManager.getBannerAd() != null)
                  SizedBox(
                    width: adManager.getBannerAd().size.width.toDouble(),
                    height: adManager.getBannerAd().size.height.toDouble(),
                    child: AdWidget(ad: adManager.getBannerAd()),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_selectedRecord == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please add an academic record first.')),
            );
            return;
          }
          String? semesterName = await _showTextInputDialog(context, 'New Semester', 'Enter semester name (e.g., Rain Semester)');
          if (semesterName != null && semesterName.isNotEmpty) {
            String? yearText = await _showTextInputDialog(context, 'Semester Year', 'Enter year (e.g., 2023)');
            if (yearText != null && yearText.isNotEmpty) {
              try {
                int year = int.parse(yearText);
                final newSemester = Semester(
                  id: const Uuid().v4(),
                  name: semesterName,
                  year: year,
                  academicRecordId: _selectedRecord!.id,
                );
                await storageService.addSemester(newSemester);
                _loadAcademicRecords();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid year entered.')),
                );
              }
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 13. `lib/screens/add_course_screen.dart`

This screen provides a form for users to add new courses or edit existing ones within a specific semester. It includes input fields for course code, title, credit units, and score.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:cgpa_calculator/models/course.dart';
import 'package:cgpa_calculator/services/storage_service.dart';

class AddCourseScreen extends StatefulWidget {
  final Course? course;
  final String semesterId;

  const AddCourseScreen({super.key, this.course, required this.semesterId});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _courseCodeController;
  late TextEditingController _courseTitleController;
  late TextEditingController _creditUnitsController;
  late TextEditingController _scoreController;

  @override
  void initState() {
    super.initState();
    _courseCodeController = TextEditingController(text: widget.course?.courseCode ?? '');
    _courseTitleController = TextEditingController(text: widget.course?.courseTitle ?? '');
    _creditUnitsController = TextEditingController(text: widget.course?.creditUnits.toString() ?? '');
    _scoreController = TextEditingController(text: widget.course?.score.toString() ?? '');
  }

  @override
  void dispose() {
    _courseCodeController.dispose();
    _courseTitleController.dispose();
    _creditUnitsController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (_formKey.currentState!.validate()) {
      final storageService = Provider.of<StorageService>(context, listen: false);

      final courseCode = _courseCodeController.text;
      final courseTitle = _courseTitleController.text;
      final creditUnits = double.parse(_creditUnitsController.text);
      final score = double.parse(_scoreController.text);

      if (widget.course == null) {
        // Add new course
        final newCourse = Course(
          id: const Uuid().v4(),
          courseCode: courseCode,
          courseTitle: courseTitle,
          creditUnits: creditUnits,
          score: score,
          semesterId: widget.semesterId,
        );
        await storageService.addCourse(newCourse);
      } else {
        // Update existing course
        widget.course!.courseCode = courseCode;
        widget.course!.courseTitle = courseTitle;
        widget.course!.creditUnits = creditUnits;
        widget.course!.score = score;
        await storageService.updateCourse(widget.course!);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? 'Add New Course' : 'Edit Course'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _courseCodeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseTitleController,
                decoration: const InputDecoration(
                  labelText: 'Course Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter course title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditUnitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Credit Units',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter credit units';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Score (0-100)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter score';
                  }
                  final score = double.tryParse(value);
                  if (score == null || score < 0 || score > 100) {
                    return 'Score must be between 0 and 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveCourse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(widget.course == null ? 'Add Course' : 'Update Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 14. `lib/screens/semester_detail_screen.dart`

This screen displays a list of courses within a selected semester, calculates and shows the semester GPA, and provides options to add new courses or generate a PDF report for the semester.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cgpa_calculator/models/academic_record.dart';
import 'package:cgpa_calculator/models/course.dart';
import 'package:cgpa_calculator/models/semester.dart';
import 'package:cgpa_calculator/services/storage_service.dart';
import 'package:cgpa_calculator/services/calculation_engine.dart';
import 'package:cgpa_calculator/services/pdf_generator.dart';
import 'package:cgpa_calculator/services/ad_manager.dart';
import 'package:cgpa_calculator/services/feature_access_manager.dart';

import 'package:cgpa_calculator/screens/add_course_screen.dart';

class SemesterDetailScreen extends StatefulWidget {
  const SemesterDetailScreen({super.key});

  @override
  State<SemesterDetailScreen> createState() => _SemesterDetailScreenState();
}

class _SemesterDetailScreenState extends State<SemesterDetailScreen> {
  late String _semesterId;
  late String _academicRecordId;
  Semester? _semester;
  AcademicRecord? _academicRecord;
  List<Course> _courses = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    _semesterId = args['semesterId']!;
    _academicRecordId = args['academicRecordId']!;
    _loadSemesterDetails();
  }

  Future<void> _loadSemesterDetails() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    _semester = storageService._semestersBox.get(_semesterId);
    _academicRecord = storageService._academicRecordsBox.get(_academicRecordId);
    _courses = storageService.getCoursesForSemester(_semesterId);
    setState(() {});
  }

  Future<void> _deleteCourse(Course course) async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    await storageService.deleteCourse(course.id);
    _loadSemesterDetails();
  }

  Future<void> _generatePdfReport() async {
    final featureAccessManager = Provider.of<FeatureAccessManager>(context, listen: false);
    final adManager = Provider.of<AdManager>(context, listen: false);

    bool unlocked = await featureAccessManager.isFeatureUnlocked(FeatureAccessManager.pdfExportFeatureKey);

    if (!unlocked) {
      if (adManager.isRewardedAdReady) {
        // Show ad to unlock feature
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unlock PDF Export'),
            content: const Text('Watch a short ad to unlock PDF export for 24 hours.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  adManager.showRewardedAd(() async {
                    await featureAccessManager.unlockFeature(FeatureAccessManager.pdfExportFeatureKey);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF Export unlocked for 24 hours!')), 
                    );
                    _generatePdfReport(); // Try again after unlocking
                  });
                },
                child: const Text('Watch Ad'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not ready yet. Please try again in a moment.')),
        );
        adManager.loadRewardedAd(); // Try loading ad again
      }
      return;
    }

    if (_semester != null && _academicRecord != null) {
      await PdfGenerator.generateSemesterReport(
        _academicRecord!,
        _semester!,
        _courses,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report generated and ready to share!')), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_semester == null || _academicRecord == null) {
      return const Scaffold(
        appBar: AppBar(title: Text('Loading...')), 
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final gpa = CalculationEngine.calculateGPA(_courses, _academicRecord!.gradingScale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_semester!.name} ${_semester!.year}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Semester GPA',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      gpa.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _courses.isEmpty
                ? const Center(
                    child: Text(
                      'No courses added yet. Tap + to add one.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      final letterGrade = CalculationEngine.getLetterGrade(
                          course.score, _academicRecord!.gradingScale);
                      final qualityPoint = CalculationEngine.getQualityPoint(
                          course.score, _academicRecord!.gradingScale);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text('${course.courseCode}: ${course.courseTitle}'),
                          subtitle: Text(
                              'Units: ${course.creditUnits.toStringAsFixed(1)} | Score: ${course.score.toStringAsFixed(0)} | Grade: $letterGrade ($qualityPoint)')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddCourseScreen(
                                        course: course,
                                        semesterId: _semesterId,
                                      ),
                                    ),
                                  ).then((_) => _loadSemesterDetails());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _deleteCourse(course),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCourseScreen(semesterId: _semesterId),
            ),
          ).then((_) => _loadSemesterDetails());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### 15. `lib/screens/settings_screen.dart`

This screen allows users to configure academic record settings, such as selecting the grading scale (NUC 5.0 or NBTE 4.0) and enabling/disabling grade replacement logic.

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cgpa_calculator/models/academic_record.dart';
import 'package:cgpa_calculator/models/enums.dart';
import 'package:cgpa_calculator/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _academicRecordId;
  AcademicRecord? _academicRecord;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _academicRecordId = ModalRoute.of(context)!.settings.arguments as String;
    _loadAcademicRecordSettings();
  }

  Future<void> _loadAcademicRecordSettings() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    _academicRecord = storageService._academicRecordsBox.get(_academicRecordId);
    setState(() {});
  }

  Future<void> _updateGradingScale(GradingScale? newScale) async {
    if (newScale != null && _academicRecord != null) {
      _academicRecord!.gradingScale = newScale;
      await Provider.of<StorageService>(context, listen: false).updateAcademicRecord(_academicRecord!);
      setState(() {});
    }
  }

  Future<void> _toggleGradeReplacement(bool value) async {
    if (_academicRecord != null) {
      _academicRecord!.gradeReplacementEnabled = value;
      await Provider.of<StorageService>(context, listen: false).updateAcademicRecord(_academicRecord!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_academicRecord == null) {
      return const Scaffold(
        appBar: AppBar(title: Text('Loading Settings...')), 
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grading Scale',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<GradingScale>(
                    title: const Text('NUC 5.0 Scale'),
                    value: GradingScale.nuc5_0,
                    groupValue: _academicRecord!.gradingScale,
                    onChanged: _updateGradingScale,
                  ),
                  RadioListTile<GradingScale>(
                    title: const Text('NBTE 4.0 Scale'),
                    value: GradingScale.nbte4_0,
                    groupValue: _academicRecord!.gradingScale,
                    onChanged: _updateGradingScale,
                  ),
                ],
              ),
            ),
          ),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grade Replacement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Grade Replacement'),
                    subtitle: const Text('Use only the best attempt for repeated courses in CGPA calculation.'),
                    value: _academicRecord!.gradeReplacementEnabled,
                    onChanged: _toggleGradeReplacement,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```
## Setup Instructions

Follow these steps to set up and run the Flutter CGPA Calculator project.

### 1. Create the Flutter Project

First, ensure you have Flutter installed. If not, follow the official Flutter installation guide. Then, create a new Flutter project:

```bash
flutter create cgpa_calculator
cd cgpa_calculator
```

### 2. Add Dependencies

Open the `pubspec.yaml` file and add the dependencies as specified in the `pubspec.yaml` section above. After modifying `pubspec.yaml`, run:

```bash
flutter pub get
```

### 3. Generate Hive Adapters

Hive uses code generation for its adapters. You need to run `build_runner` to generate the necessary `.g.dart` files for your Hive models. This command should be run whenever you make changes to your Hive models (e.g., adding new fields or models).

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 4. AdMob Setup

#### Android Setup

1.  **Update `android/app/src/main/AndroidManifest.xml`**:

    Add your AdMob App ID and update permissions. Replace `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` with your actual AdMob App ID.

    ```xml
    <manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="com.example.cgpa_calculator">

        <uses-permission android:name="android.permission.INTERNET"/>

        <application
            android:label="cgpa_calculator"
            android:name="${applicationName}"
            android:icon="@mipmap/ic_launcher">
            <meta-data
                android:name="com.google.android.gms.ads.APPLICATION_ID"
                android:value="ca-app-pub-3940256099942544~3347511713"/> <!-- Use your actual AdMob App ID here -->
            <activity
                android:name=".MainActivity"
                android:exported="true"
                android:launchMode="singleTop"
                android:theme="@style/LaunchTheme"
                android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
                android:hardwareAccelerated="true"
                android:windowSoftInputMode="adjustResize">
                <!-- Specifies an Android theme to apply to this Activity as soon as
                     the Android process has started. This theme is visible to the user
                     while the Flutter UI initializes. An Android BuildTarget will restore
                     the original Activity theme after the Flutter UI has rendered. -->
                <meta-data
                  android:name="io.flutter.embedding.android.NormalTheme"
                  android:resource="@style/NormalTheme"
                  />
                <intent-filter>
                    <action android:name="android.intent.action.MAIN"/>
                    <category android:name="android.intent.category.LAUNCHER"/>
                </intent-filter>
            </activity>
            <!-- Don't delete the meta-data below. -->
            <meta-data
                android:name="flutterEmbedding"
                android:value="2" />
        </application>
    </manifest>
    ```

2.  **Update `android/app/build.gradle`**:

    Ensure `minSdkVersion` is at least 19. The Google Mobile Ads SDK requires API level 19 or higher.

    ```gradle
    android {
        defaultConfig {
            // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
            applicationId "com.example.cgpa_calculator"
            minSdkVersion 19 // Ensure this is at least 19
            targetSdkVersion flutter.targetSdkVersion
            versionCode flutterVersionCode.toInteger()
            versionName flutterVersionName
        }
    }
    ```

#### iOS Setup

1.  **Update `ios/Runner/Info.plist`**:

    Add your AdMob App ID. Replace `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` with your actual AdMob App ID.

    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>CADisableMinimumFrameDurationOnPhone</key>
    	<true/>
    	<key>CFBundleDevelopmentRegion</key>
    	<string>$(DEVELOPMENT_LANGUAGE)</string>
    	<key>CFBundleExecutable</key>
    	<string>$(EXECUTABLE_NAME)</string>
    	<key>CFBundleIdentifier</key>
    	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    	<key>CFBundleInfoDictionaryVersion</key>
    	<string>6.0</string>
    	<key>CFBundleName</key>
    	<string>cgpa_calculator</string>
    	<key>CFBundlePackageType</key>
    	<string>APPL</string>
    	<key>CFBundleShortVersionString</key>
    	<string>$(FLUTTER_BUILD_NAME)</string>
    	<key>CFBundleSignature</key>
    	<string>????</string>
    	<key>CFBundleVersion</key>
    	<string>$(FLUTTER_BUILD_NUMBER)</string>
    	<key>LSRequiresIPhoneOS</key>
    	<true/>
    	<key>GADApplicationIdentifier</key>
    	<string>ca-app-pub-3940256099942544~1458002511</string> <!-- Use your actual AdMob App ID here -->
    	<key>UILaunchStoryboardName</key>
    	<string>LaunchScreen</string>
    	<key>UIMainStoryboardFile</key>
    	<string>Main</string>
    	<key>UISupportedInterfaceOrientations</key>
    	<array>
    		<string>UIInterfaceOrientationPortrait</string>
    		<string>UIInterfaceOrientationLandscapeLeft</string>
    		<string>UIInterfaceOrientationLandscapeRight</string>
    	</array>
    	<key>UISupportedInterfaceOrientations~ipad</key>
    	<array>
    		<string>UIInterfaceOrientationPortrait</string>
    		<string>UIInterfaceOrientationPortraitUpsideDown</string>
    		<string>UIInterfaceOrientationLandscapeLeft</string>
    		<string>UIInterfaceOrientationLandscapeRight</string>
    	</array>
    	<key>UIViewControllerBasedStatusBarAppearance</key>
    	<false/>
    </dict>
    </plist>
    ```

### 5. Configure Ad Unit IDs

In `lib/services/ad_manager.dart`, replace the test ad unit IDs with your actual AdMob ad unit IDs for rewarded video and banner ads. The provided code uses test IDs for development.

## Security Considerations

### Preventing Ad Bypass

Since premium features are gated by rewarded video ads, it's crucial to implement server-side verification for rewarded ads in a production environment. While this project uses client-side verification for simplicity (as there's no backend), for a real-world application, you would:

1.  **Implement a secure backend endpoint**: When a rewarded ad is completed, the client-side `onUserEarnedReward` callback should send a request to your backend.
2.  **Verify the reward**: Your backend should then verify the reward with the AdMob servers using the Google Mobile Ads SDK's server-side verification feature. This ensures the reward is legitimate and prevents users from bypassing ads.
3.  **Grant feature access**: Only after successful server-side verification should your backend signal the client to unlock the premium feature.

### Local Data Integrity

All data is stored locally using Hive. While Hive provides a robust and fast local database, it's important to note that local storage is not inherently secure against determined users with root access to their devices. For highly sensitive data, additional encryption layers or secure storage solutions would be necessary. However, for a CGPA calculator, Hive's default encryption (if enabled) and local storage are generally sufficient.

### Code Obfuscation

For production builds, consider enabling code obfuscation to make reverse engineering more difficult. This can be configured in your `android/app/build.gradle` and `ios/Podfile` files. For Flutter, ProGuard rules can be added for Android, and for iOS, bitcode can be enabled.

```gradle
// android/app/build.gradle
android {
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig signingConfigs.debug
            minifyEnabled true // Enables code shrinking, obfuscation, and optimization for the app's release build.
            useProguard true // Enables ProGuard for code shrinking and obfuscation.
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

Create a `proguard-rules.pro` file in `android/app` if you enable ProGuard.

## References

[1] NUC Grading System: 5-Point - OpenEducat.org: [https://openeducat.org/articles/nigeria-university-grading-system-cgpa-explained/](https://openeducat.org/articles/nigeria-university-grading-system-cgpa-explained/)
[2] Nigeria Polytechnic Grading: ND & HND CGPA Scale - OpenEducat.org: [https://openeducat.org/gradebook/nigeria/polytechnic/](https://openeducat.org/gradebook/nigeria/polytechnic/)
[3] Google Mobile Ads SDK for Flutter: [https://pub.dev/packages/google_mobile_ads](https://pub.dev/packages/google_mobile_ads)
[4] Hive - A fast, lightweight, and powerful database for Flutter and Dart: [https://pub.dev/packages/hive](https://pub.dev/packages/hive)
[5] PDF - A powerful PDF generation library for Dart and Flutter: [https://pub.dev/packages/pdf](https://pub.dev/packages/pdf)
[6] share_plus - A Flutter plugin for sharing content via the platform share UI: [https://pub.dev/packages/share_plus](https://pub.dev/packages/share_plus)
[7] path_provider - A Flutter plugin for finding commonly used locations on the filesystem: [https://pub.dev/packages/path_provider](https://pub.dev/packages/path_provider)
[8] provider - A wrapper around InheritedWidget to make them easier to use and more reusable: [https://pub.dev/packages/provider](https://pub.dev/packages/provider)
[9] shared_preferences - Persistent platform-specific key-value storage: [https://pub.dev/packages/shared_preferences](https://pub.dev/packages/shared_preferences)
[10] uuid - A Dart package for generating UUIDs: [https://pub.dev/packages/uuid](https://pub.dev/packages/uuid)
[11] intl - Internationalization and localization for Dart: [https://pub.dev/packages/intl](https://pub.dev/packages/intl)
[12] build_runner - A build system for Dart code generation: [https://pub.dev/packages/build_runner](https://pub.dev/packages/build_runner)
