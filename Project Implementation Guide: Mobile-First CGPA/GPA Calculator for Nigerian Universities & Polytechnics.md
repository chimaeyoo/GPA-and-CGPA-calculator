# Project Implementation Guide: Mobile-First CGPA/GPA Calculator for Nigerian Universities & Polytechnics

**Author:** Manus AI

This comprehensive guide outlines the technical architecture, implementation roadmap, monetization strategy, and key features for a mobile-first CGPA and GPA calculator application tailored for the Nigerian university and polytechnic market. The application will leverage Flutter for cross-platform development and Supabase as its backend, adopting a 100% ad-supported, no-subscription business model.

# 1. Monetization & Access Logic

This section outlines the strategy for monetizing the CGPA/GPA calculator application through an ad-supported model, specifically focusing on an 'Ad-as-Currency' approach. It details the logic for gating premium features behind rewarded video ads, verifying ad completion, and managing feature access without a traditional subscription backend.

## Ad-as-Currency Model

The application will adopt an 'Ad-as-Currency' model, where certain premium features, namely **'Grade Tracking'** and **'PDF Export'**, are unlocked by watching rewarded video advertisements. This approach provides users with full access to advanced functionalities without direct monetary cost, while simultaneously generating revenue through ad impressions. The core principle is to exchange user attention for feature access, creating a value exchange that benefits both the user and the application.

## Verification: Rewarded Video Ad Completion

To ensure that users have genuinely engaged with the advertisement, the application will leverage the AdMob SDK's `onUserEarnedReward` callback. This callback is triggered only upon successful completion of a rewarded video ad, providing a reliable mechanism for verification. The following Flutter/Dart code snippet illustrates how to integrate and verify rewarded ad completion using the `google_mobile_ads` package.

```dart
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';

class AdManager {
  RewardedAd? _rewardedAd;
  final String _adUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Test Ad Unit ID

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _setFullScreenContentCallback();
          debugPrint('RewardedAd loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void _setFullScreenContentCallback() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('$ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Load a new ad for future use
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Load a new ad for future use
      },
    );
  }

  void showRewardedAd(Function onRewardEarned) {
    if (_rewardedAd == null) {
      debugPrint('Warning: Attempt to show rewarded ad before it was loaded.');
      // Optionally, show a message to the user or try to load an ad immediately.
      loadRewardedAd();
      return;
    }

    _rewardedAd?.show(onUserEarnedReward: (ad, reward) {
      debugPrint('User earned reward: ${reward.amount} ${reward.type}');
      onRewardEarned(); // Execute the feature unlock logic
    });
  }
}

// Example usage in a Flutter Widget:
/*
class MyFeatureScreen extends StatefulWidget {
  const MyFeatureScreen({super.key});

  @override
  State<MyFeatureScreen> createState() => _MyFeatureScreenState();
}

class _MyFeatureScreenState extends State<MyFeatureScreen> {
  final AdManager _adManager = AdManager();
  bool _isFeatureUnlocked = false;

  @override
  void initState() {
    super.initState();
    _adManager.loadRewardedAd();
    _checkFeatureUnlockStatus();
  }

  void _checkFeatureUnlockStatus() async {
    // Logic to check if feature is already unlocked (e.g., from SharedPreferences)
    // For now, assume it's locked.
    setState(() {
      _isFeatureUnlocked = false; // This will be managed by session logic
    });
  }

  void _unlockFeature() {
    setState(() {
      _isFeatureUnlocked = true;
    });
    // Persist the unlocked state using SharedPreferences or similar
    debugPrint('Feature unlocked!');
    // Navigate to feature or enable UI elements
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Feature')),
      body: Center(
        child: _isFeatureUnlocked
            ? const Text('Welcome to the unlocked feature!')
            : ElevatedButton(
                onPressed: () {
                  _adManager.showRewardedAd(_unlockFeature);
                },
                child: const Text('Watch Ad to Unlock Feature'),
              ),
      ),
    );
  }
}
*/
```

## Session Management: Tracking Unlocked States

Given the no-subscription model, feature access will be managed locally using `SharedPreferences` to store time-limited unlock states. This approach avoids the complexity of a backend payment system while still providing a mechanism to gate features. When a user successfully watches a rewarded ad, a timestamp is recorded, granting access to the feature for a predefined duration (e.g., 24 hours). After this period, the feature will be re-locked, requiring the user to watch another ad.

Here's a simple logic for managing feature access using `SharedPreferences`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class FeatureAccessManager {
  static const String _gradeTrackingKey = 'grade_tracking_unlocked_until';
  static const String _pdfExportKey = 'pdf_export_unlocked_until';
  static const Duration _unlockDuration = Duration(hours: 24);

  Future<bool> isFeatureUnlocked(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockTimestamp = prefs.getInt(featureKey);

    if (unlockTimestamp == null) {
      return false; // Never unlocked or expired
    }

    final unlockTime = DateTime.fromMillisecondsSinceEpoch(unlockTimestamp);
    return DateTime.now().isBefore(unlockTime); // Check if current time is before unlock expiry
  }

  Future<void> unlockFeature(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(_unlockDuration);
    await prefs.setInt(featureKey, expiryTime.millisecondsSinceEpoch);
  }

  // Example usage:
  // In your ad reward callback:
  // Future<void> onAdRewardEarnedForGradeTracking() async {
  //   await FeatureAccessManager().unlockFeature(_gradeTrackingKey);
  //   // Update UI or navigate to feature
  // }

  // When checking feature access:
  // bool canAccessGradeTracking = await FeatureAccessManager().isFeatureUnlocked(_gradeTrackingKey);
}
```

This logic ensures that feature access is temporary and tied to ad engagement, promoting recurring ad views while maintaining a free-to-use model. The `featureKey` parameter allows for managing multiple gated features independently.

# 2. Technical Architecture & Schema

This section details the technical foundation of the CGPA/GPA calculator application, confirming the chosen tech stack and outlining the database schema for Supabase. It also addresses the critical aspect of offline-first persistence, ensuring the application remains functional and data is synchronized seamlessly.

## Tech Stack

The application will be developed using **Flutter** for the mobile front-end, providing a single codebase for both Android and iOS platforms. **Supabase** will serve as the backend-as-a-service (BaaS), offering a PostgreSQL database, authentication, and real-time capabilities. This combination provides a robust, scalable, and developer-friendly environment for building the application.

## Database Schema (Supabase)

The Supabase backend will utilize a PostgreSQL database. The schema is designed to store user information, academic records, semesters, and courses, without any tables related to payments or subscriptions, aligning with the ad-supported business model. The following SQL schema defines the necessary tables and their relationships.

```sql
-- Enable Row Level Security (RLS) for all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE semesters ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Create the 'users' table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  university_scale_id INT NOT NULL DEFAULT 1, -- 1 for 5.0 scale (University), 2 for 4.0 scale (Polytechnic)
  grade_replacement_enabled BOOLEAN NOT NULL DEFAULT FALSE -- User preference for grade replacement
);

-- Policies for 'users' table
CREATE POLICY "Users can view their own profile." ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile." ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile." ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- Create the 'academic_records' table
CREATE TABLE academic_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  record_name TEXT NOT NULL -- e.g., 'First Degree', 'HND', 'ND'
);

-- Policies for 'academic_records' table
CREATE POLICY "Users can view their own academic records." ON academic_records FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage their own academic records." ON academic_records FOR ALL USING (auth.uid() = user_id);

-- Create the 'semesters' table
CREATE TABLE semesters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_record_id UUID REFERENCES academic_records(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  semester_name TEXT NOT NULL, -- e.g., 'First Semester', 'Second Semester'
  year INT NOT NULL,
  UNIQUE (academic_record_id, semester_name, year) -- Ensure unique semester per academic record per year
);

-- Policies for 'semesters' table
CREATE POLICY "Users can view their own semesters." ON semesters FOR SELECT USING (auth.uid() = (SELECT user_id FROM academic_records WHERE id = academic_record_id));
CREATE POLICY "Users can manage their own semesters." ON semesters FOR ALL USING (auth.uid() = (SELECT user_id FROM academic_records WHERE id = academic_record_id));

-- Create the 'courses' table
CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  semester_id UUID REFERENCES semesters(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  course_code TEXT NOT NULL, -- e.g., 'CSC101'
  course_title TEXT NOT NULL,
  credit_units INT NOT NULL,
  grade_score INT NOT NULL, -- Raw score (e.g., 75)
  grade_point DECIMAL(3, 2) NOT NULL, -- Calculated grade point (e.g., 5.00)
  UNIQUE (semester_id, course_code) -- Ensure unique course per semester
);

-- Policies for 'courses' table
CREATE POLICY "Users can view their own courses." ON courses FOR SELECT USING (auth.uid() = (SELECT user_id FROM academic_records WHERE id = (SELECT academic_record_id FROM semesters WHERE id = semester_id)));
CREATE POLICY "Users can manage their own courses." ON courses FOR ALL USING (auth.uid() = (SELECT user_id FROM academic_records WHERE id = (SELECT academic_record_id FROM semesters WHERE id = semester_id)));

```

## Offline-First Persistence

To ensure the application remains fully functional even without an active internet connection, an offline-first strategy will be implemented. This involves storing data locally using a lightweight database solution like SQLite (via `sqflite` package) or Hive, and then synchronizing this local data with Supabase when an internet connection becomes available. This approach provides a seamless user experience, allowing users to input grades, calculate CGPA/GPA, and access their academic records at all times.

### Local Data Storage (Hive Example)

Hive is chosen for its simplicity and performance as a local NoSQL database. It allows for easy storage of Dart objects.

First, add the necessary dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.0.11
  # For Supabase integration
  supabase_flutter: ^1.10.0
```

Initialize Hive in your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  // Register adapters for your data models (e.g., User, AcademicRecord, Semester, Course)
  // Hive.registerAdapter(UserAdapter());
  // Hive.registerAdapter(AcademicRecordAdapter());
  // Hive.registerAdapter(SemesterAdapter());
  // Hive.registerAdapter(CourseAdapter());
  runApp(const MyApp());
}
```

Define your data models as Hive objects. For example, a `Course` model:

```dart
import 'package:hive/hive.dart';

part 'course.g.dart'; // Generated by `flutter packages pub run build_runner build`

@HiveType(typeId: 0)
class Course extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String semesterId;

  @HiveField(2)
  String courseCode;

  @HiveField(3)
  String courseTitle;

  @HiveField(4)
  int creditUnits;

  @HiveField(5)
  int gradeScore;

  @HiveField(6)
  double gradePoint;

  @HiveField(7)
  bool isSynced; // Flag to track sync status

  Course({
    required this.id,
    required this.semesterId,
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnits,
    required this.gradeScore,
    required this.gradePoint,
    this.isSynced = false,
  });

  // Convert from Supabase JSON to local model
  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json["id"],
      semesterId: json["semester_id"],
      courseCode: json["course_code"],
      courseTitle: json["course_title"],
      creditUnits: json["credit_units"],
      gradeScore: json["grade_score"],
      gradePoint: (json["grade_point"] as num).toDouble(),
      isSynced: true, // Data from Supabase is already synced
    );
  }

  // Convert local model to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "semester_id": semesterId,
      "course_code": courseCode,
      "course_title": courseTitle,
      "credit_units": creditUnits,
      "grade_score": gradeScore,
      "grade_point": gradePoint,
    };
  }
}
```

### Synchronization Logic

The synchronization process will involve listening for network connectivity changes and, when online, pushing unsynced local data to Supabase and pulling down any new or updated data from Supabase to the local database.

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataSyncService {
  final SupabaseClient _supabaseClient;
  final Box<Course> _courseBox;

  DataSyncService(this._supabaseClient) : _courseBox = Hive.box<Course>('courses');

  void startSyncListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        debugPrint('Internet connection available. Starting sync...');
        _syncData();
      } else {
        debugPrint('No internet connection. Offline mode active.');
      }
    });
  }

  Future<void> _syncData() async {
    // 1. Upload unsynced local data to Supabase
    final unsyncedCourses = _courseBox.values.where((course) => !course.isSynced).toList();
    for (final course in unsyncedCourses) {
      try {
        await _supabaseClient.from('courses').upsert(course.toJson());
        course.isSynced = true;
        await course.save(); // Mark as synced in local Hive
        debugPrint('Uploaded course: ${course.courseCode}');
      } catch (error) {
        debugPrint('Error uploading course ${course.courseCode}: $error');
        // Handle errors, e.g., retry later or notify user
      }
    }

    // 2. Download and update local data from Supabase
    try {
      final response = await _supabaseClient.from('courses').select('*').order('created_at', ascending: true);
      final supabaseCourses = (response as List).map((json) => Course.fromJson(json)).toList();

      for (final supabaseCourse in supabaseCourses) {
        final localCourse = _courseBox.get(supabaseCourse.id);
        if (localCourse == null || !localCourse.isSynced) {
          // If course doesn't exist locally or is not synced, add/update it
          await _courseBox.put(supabaseCourse.id, supabaseCourse);
          debugPrint('Downloaded/Updated course: ${supabaseCourse.courseCode}');
        }
      }
    } catch (error) {
      debugPrint('Error downloading courses from Supabase: $error');
    }
  }

  // Example usage:
  // In your main application widget's initState:
  // final DataSyncService _dataSyncService = DataSyncService(Supabase.instance.client);
  // _dataSyncService.startSyncListener();
}
```

This synchronization logic provides a robust offline experience, ensuring data consistency across local and remote storage. It prioritizes local data for immediate access and updates the remote server when connectivity is restored, handling potential conflicts by upserting based on `id`.

# 3. Calculation Engine (Nigerian Context)

This section details the core logic of the CGPA/GPA calculator, designed to accommodate the specific academic grading systems prevalent in Nigerian universities (NUC 5.0 scale) and polytechnics (NBTE 4.0 scale). It outlines the Dart class structure for the calculation engine, including support for grade replacement and credit load validation.

## Grading Scales

The application will support two primary grading scales, configurable by the user:

### NUC (University) 5.0 Scale

| Score Range | Letter Grade | Grade Point (GP) |
| :---------- | :----------- | :--------------- |
| 70-100      | A            | 5.0              |
| 60-69       | B            | 4.0              |
| 50-59       | C            | 3.0              |
| 45-49       | D            | 2.0              |
| 40-44       | E            | 1.0              |
| 0-39        | F            | 0.0              |

### NBTE (Polytechnic) 4.0 Scale

| Score Range | Letter Grade | Grade Point (GP) |
| :---------- | :----------- | :--------------- |
| 70-100      | A            | 4.0              |
| 65-69       | AB           | 3.5              |
| 60-64       | B            | 3.0              |
| 55-59       | BC           | 2.5              |
| 50-54       | C            | 2.0              |
| 45-49       | CD           | 1.5              |
| 40-44       | D            | 1.0              |
| 0-39        | F            | 0.0              |

## Dart Class Structure for Calculation Engine

The `GpaCalculator` class will encapsulate the logic for calculating GPA and CGPA, handling different grading scales, and applying grade replacement rules. It will also include methods for validating credit load limits.

```dart
import 'dart:math';

enum GradingScale {
  nuc5_0,
  nbte4_0,
}

enum GradeReplacementOption {
  allAttempts,
  bestAttempt,
}

class Course {
  final String courseCode;
  final String courseTitle;
  final int creditUnits;
  final int score; // Raw score (e.g., 75)
  final int attemptNumber; // For grade replacement logic

  Course({
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnits,
    required this.score,
    this.attemptNumber = 1,
  });
}

class Semester {
  final String name;
  final int year;
  final List<Course> courses;

  Semester({
    required this.name,
    required this.year,
    required this.courses,
  });

  // Get total credit units for the semester
  int get totalCreditUnits => courses.fold(0, (sum, course) => sum + course.creditUnits);
}

class AcademicRecord {
  final String recordName;
  final List<Semester> semesters;
  final GradingScale gradingScale;
  final GradeReplacementOption gradeReplacementOption;

  AcademicRecord({
    required this.recordName,
    required this.semesters,
    this.gradingScale = GradingScale.nuc5_0,
    this.gradeReplacementOption = GradeReplacementOption.allAttempts,
  });
}

class GpaCalculator {
  final AcademicRecord academicRecord;

  GpaCalculator(this.academicRecord);

  // Converts a raw score to a grade point based on the selected grading scale
  double _getGradePoint(int score) {
    switch (academicRecord.gradingScale) {
      case GradingScale.nuc5_0:
        if (score >= 70) return 5.0;
        if (score >= 60) return 4.0;
        if (score >= 50) return 3.0;
        if (score >= 45) return 2.0;
        if (score >= 40) return 1.0;
        return 0.0;
      case GradingScale.nbte4_0:
        if (score >= 70) return 4.0;
        if (score >= 65) return 3.5;
        if (score >= 60) return 3.0;
        if (score >= 55) return 2.5;
        if (score >= 50) return 2.0;
        if (score >= 45) return 1.5;
        if (score >= 40) return 1.0;
        return 0.0;
    }
  }

  // Applies grade replacement logic if enabled
  List<Course> _applyGradeReplacement(List<Course> courses) {
    if (academicRecord.gradeReplacementOption == GradeReplacementOption.allAttempts) {
      return courses; // No replacement, consider all attempts
    }

    // GradeReplacementOption.bestAttempt
    final Map<String, Course> bestAttempts = {};
    for (final course in courses) {
      final existing = bestAttempts[course.courseCode];
      if (existing == null || _getGradePoint(course.score) > _getGradePoint(existing.score)) {
        bestAttempts[course.courseCode] = course;
      }
    }
    return bestAttempts.values.toList();
  }

  // Calculates GPA for a single semester
  double calculateSemesterGPA(Semester semester) {
    final effectiveCourses = _applyGradeReplacement(semester.courses);
    if (effectiveCourses.isEmpty) return 0.0;

    double totalGradePoints = 0.0;
    int totalCreditUnits = 0;

    for (final course in effectiveCourses) {
      final gradePoint = _getGradePoint(course.score);
      totalGradePoints += (gradePoint * course.creditUnits);
      totalCreditUnits += course.creditUnits;
    }

    return totalCreditUnits > 0 ? totalGradePoints / totalCreditUnits : 0.0;
  }

  // Calculates CGPA for all academic records
  double calculateCGPA() {
    double totalCumulativeGradePoints = 0.0;
    int totalCumulativeCreditUnits = 0;

    for (final semester in academicRecord.semesters) {
      final effectiveCourses = _applyGradeReplacement(semester.courses);
      for (final course in effectiveCourses) {
        final gradePoint = _getGradePoint(course.score);
        totalCumulativeGradePoints += (gradePoint * course.creditUnits);
        totalCumulativeCreditUnits += course.creditUnits;
      }
    }

    return totalCumulativeCreditUnits > 0 ? totalCumulativeGradePoints / totalCumulativeCreditUnits : 0.0;
  }

  // Validates credit load limits for a semester
  // NUC: min 15, max 24 per semester (30-48 per session)
  // NBTE: typically 1-4 credit units per course, no explicit semester limit provided in prompt, 
  // but general academic practice suggests similar ranges.
  // For this implementation, we'll use a general guideline for NBTE if not specified.
  bool validateCreditLoad(Semester semester) {
    final int semesterCreditUnits = semester.totalCreditUnits;
    switch (academicRecord.gradingScale) {
      case GradingScale.nuc5_0:
        return semesterCreditUnits >= 15 && semesterCreditUnits <= 24; // NUC guideline
      case GradingScale.nbte4_0:
        // Assuming a similar range for NBTE for validation purposes if not explicitly defined
        return semesterCreditUnits >= 12 && semesterCreditUnits <= 24; // General polytechnic guideline
    }
  }
}

// Example Usage:
/*
void main() {
  // Define courses for a semester
  final course1 = Course(courseCode: 'CSC101', courseTitle: 'Intro to Comp Sci', creditUnits: 3, score: 75);
  final course2 = Course(courseCode: 'MTH101', courseTitle: 'Algebra', creditUnits: 2, score: 62);
  final course3 = Course(courseCode: 'PHY101', courseTitle: 'Physics I', creditUnits: 3, score: 55);
  final course4 = Course(courseCode: 'GNS101', courseTitle: 'Use of English', creditUnits: 1, score: 80);

  // Define a semester
  final firstSemester = Semester(
    name: 'First Semester',
    year: 2023,
    courses: [course1, course2, course3, course4],
  );

  // Define an academic record (e.g., University student)
  final universityRecord = AcademicRecord(
    recordName: 'B.Sc. Computer Science',
    semesters: [firstSemester],
    gradingScale: GradingScale.nuc5_0,
    gradeReplacementOption: GradeReplacementOption.allAttempts,
  );

  // Create a calculator instance
  final uniCalculator = GpaCalculator(universityRecord);

  // Calculate GPA for the semester
  final semesterGPA = uniCalculator.calculateSemesterGPA(firstSemester);
  print('University First Semester GPA: ${semesterGPA.toStringAsFixed(2)}');

  // Calculate CGPA
  final universityCGPA = uniCalculator.calculateCGPA();
  print('University CGPA: ${universityCGPA.toStringAsFixed(2)}');

  // Validate credit load
  final isValidCreditLoad = uniCalculator.validateCreditLoad(firstSemester);
  print('Is First Semester credit load valid? $isValidCreditLoad');

  // Example for Polytechnic with grade replacement
  final polyCourse1 = Course(courseCode: 'COM111', courseTitle: 'Intro to Computing', creditUnits: 4, score: 68);
  final polyCourse2 = Course(courseCode: 'MTH112', courseTitle: 'Calculus', creditUnits: 3, score: 58);
  final polyCourse3 = Course(courseCode: 'COM111', courseTitle: 'Intro to Computing', creditUnits: 4, score: 72, attemptNumber: 2); // Retake

  final polySemester = Semester(
    name: 'First Semester',
    year: 2023,
    courses: [polyCourse1, polyCourse2, polyCourse3],
  );

  final polyRecord = AcademicRecord(
    recordName: 'ND Computer Science',
    semesters: [polySemester],
    gradingScale: GradingScale.nbte4_0,
    gradeReplacementOption: GradeReplacementOption.bestAttempt,
  );

  final polyCalculator = GpaCalculator(polyRecord);
  final polySemesterGPA = polyCalculator.calculateSemesterGPA(polySemester);
  print('Polytechnic First Semester GPA (Best Attempt): ${polySemesterGPA.toStringAsFixed(2)}');
}
*/
```

### Logic for 'Grade Replacement' vs. 'All Attempts'

The `GradeReplacementOption` enum and the `_applyGradeReplacement` method within the `GpaCalculator` class handle this logic. If `GradeReplacementOption.bestAttempt` is selected, the system identifies courses with the same `courseCode` and retains only the attempt with the highest grade point. If `GradeReplacementOption.allAttempts` is selected, all course attempts are included in the GPA/CGPA calculation, reflecting a cumulative average across all registered courses.

### Validation for NUC/NBTE Credit Load Limits

The `validateCreditLoad` method in the `GpaCalculator` class enforces the credit unit limits. For NUC, the guideline is a minimum of 15 and a maximum of 24 credit units per semester. For NBTE, while specific semester limits were not explicitly provided in the research, a general polytechnic guideline of 12-24 credit units per semester is applied for validation purposes to ensure reasonable academic loads. These values can be adjusted based on more precise NBTE guidelines if available.

# 4. Implementation Roadmap

This section outlines a phased development approach for the CGPA/GPA calculator application, breaking down the project into manageable stages with clear deliverables and estimated timelines. This roadmap ensures a structured development process, allowing for focused effort and iterative improvements.

## Phase 1: Core UI/UX and Calculation Logic (Offline)

**Timeline:** 3-4 Weeks

**Deliverables:**
-   **User Interface (UI) Mockups & Wireframes:** Complete designs for key screens (e.g., Course Entry, Semester View, GPA/CGPA Display, Settings).
-   **Basic Navigation:** Functional navigation between core screens.
-   **Local Data Input:** Ability to add, edit, and delete courses and semesters locally.
-   **Core Calculation Engine:** Fully functional GPA and CGPA calculation based on NUC 5.0 and NBTE 4.0 scales, including grade point conversion and initial credit load validation.
-   **User Settings:** Implementation of grading scale selection (5.0/4.0) and grade replacement option (All Attempts/Best Attempt).
-   **Unit Tests:** Comprehensive unit tests for the calculation engine.

**Description:** This phase focuses on building the foundational elements of the application, ensuring a smooth user experience for data entry and accurate calculation of academic metrics. The application will be fully functional in an offline capacity during this phase.

## Phase 2: Local Storage and Supabase Sync

**Timeline:** 3-4 Weeks

**Deliverables:**
-   **Offline Persistence:** Integration of Hive (or SQLite) for robust local data storage.
-   **Supabase Integration:** Setup of Supabase project, including database schema deployment and Flutter client configuration.
-   **User Authentication:** Basic user registration and login using Supabase Auth.
-   **Data Synchronization Service:** Implementation of the offline-first synchronization logic, pushing local changes to Supabase and pulling remote updates when online.
-   **Conflict Resolution Strategy:** Basic strategy for handling data conflicts during synchronization (e.g., last-write-wins).
-   **Integration Tests:** Tests for data persistence and synchronization flows.

**Description:** This phase extends the core functionality by introducing persistent data storage, both locally and remotely. It establishes the Supabase backend and implements the critical synchronization mechanism to support offline usage and user data portability.

## Phase 3: AdMob Banner and Rewarded Video Integration

**Timeline:** 2-3 Weeks

**Deliverables:**
-   **AdMob SDK Integration:** Setup and configuration of the Google Mobile Ads SDK in Flutter.
-   **Banner Ads:** Implementation of banner ads on non-intrusive screens (e.g., bottom of semester list).
-   **Rewarded Video Ads:** Integration of rewarded video ads for gating premium features (Grade Tracking, PDF Export).
-   **Ad-as-Currency Logic:** Implementation of the `onUserEarnedReward` callback and `SharedPreferences` based session management for feature unlocks.
-   **Ad Placement Optimization:** Initial placement and frequency tuning for ads to balance monetization and user experience.

**Description:** This phase focuses on integrating the monetization strategy. It involves setting up AdMob, displaying banner ads, and crucially, implementing the rewarded video ad mechanism to unlock premium features, adhering to the ad-as-currency model.

## Phase 4: PDF Generation and Report Styling

**Timeline:** 2-3 Weeks

**Deliverables:**
-   **PDF Generation Library Integration:** Integration of a Flutter PDF generation library (e.g., `pdf` package).
-   **Grade Tracking Feature:** UI and backend logic for users to track their academic progress over time, potentially visualizing trends.
-   **PDF Export Functionality:** Ability to generate and export academic reports (e.g., semester results, full academic transcript summary) as PDF files.
-   **Report Styling:** Professional and clear styling for generated PDF reports, including branding elements.
-   **User Feedback Mechanism:** Implementation of a simple in-app feedback or rating system.

**Description:** The final phase enhances the application with advanced features, including the ability to generate professional PDF reports of academic performance and a dedicated grade tracking interface. This adds significant value to the user experience and completes the core feature set.

# 5. Deliverables & Documentation

This section outlines the key outputs of the project and essential documentation required for setup, deployment, and ongoing maintenance.

## Code: Ad-Reward Callback and Core GPA/CGPA Math Functions

Clean, well-commented code snippets for critical functionalities are provided throughout this document. Specifically, the Ad-Reward callback mechanism is detailed in Section 1.2, and the core GPA/CGPA math functions are presented in Section 3.2.

## Project README

A comprehensive `README.md` file will be provided at the root of the project repository, serving as the primary guide for developers and contributors. It will include:

```markdown
# CGPA/GPA Calculator (Nigerian Universities & Polytechnics)

A mobile-first CGPA and GPA calculator designed for students in Nigerian universities (NUC 5.0 scale) and polytechnics (NBTE 4.0 scale). This application supports offline functionality, data synchronization with Supabase, and an ad-as-currency monetization model where premium features are unlocked via rewarded video ads.

## Features

-   **Dual Grading Scales:** Supports NUC 5.0 and NBTE 4.0 grading systems.
-   **GPA/CGPA Calculation:** Accurate calculation of semester GPA and cumulative CGPA.
-   **Grade Replacement Logic:** User-configurable option for Grade Replacement vs. All Attempts.
-   **Credit Load Validation:** Checks against NUC/NBTE credit unit guidelines.
-   **Offline-First:** Full functionality without internet, with seamless data sync to Supabase.
-   **Ad-as-Currency:** Access to premium features (Grade Tracking, PDF Export) by watching rewarded video ads.
-   **User Authentication:** Secure user accounts powered by Supabase Auth.
-   **PDF Report Generation:** Export academic records as professional PDF documents.

## Tech Stack

-   **Frontend:** Flutter (Dart)
-   **Backend:** Supabase (PostgreSQL, Auth, Realtime)
-   **Local Persistence:** Hive (NoSQL local database)
-   **Ads:** Google Mobile Ads (AdMob)

## Setup Instructions

### 1. Environment Setup

Ensure you have Flutter installed and configured. Follow the official Flutter installation guide: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)

### 2. Supabase Backend Deployment

1.  **Create a Supabase Project:** Go to [https://app.supabase.com/](https://app.supabase.com/) and create a new project.
2.  **Deploy SQL Schema:** Navigate to the SQL Editor in your Supabase project and execute the SQL schema provided in `technical_architecture_schema.md` to set up your tables and Row Level Security (RLS) policies.
3.  **Retrieve API Keys:** From your Supabase project settings, note down your `Project URL` and `Anon Public Key`. These will be used in your Flutter application.

### 3. Firebase/AdMob Initialization

1.  **Create a Firebase Project:** Go to [https://console.firebase.google.com/](https://console.firebase.google.com/) and create a new project.
2.  **Add AdMob to your Firebase Project:** Follow the instructions to link your Firebase project to AdMob and create an AdMob app for Android and iOS.
3.  **Create Ad Units:** Create Rewarded Video Ad Units and Banner Ad Units. Note down their respective Ad Unit IDs.
4.  **Integrate `google_mobile_ads`:** Follow the official `google_mobile_ads` package instructions for platform-specific setup (e.g., `AndroidManifest.xml` for Android, `Info.plist` for iOS) and initialize the SDK in your Flutter app.

### 4. Flutter Project Configuration

1.  **Clone the Repository:**
    ```bash
    git clone <repository_url>
    cd cgpa_gpa_calculator
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure Supabase:** In your Flutter project, locate where Supabase is initialized (e.g., `main.dart`) and replace placeholder values with your `Project URL` and `Anon Public Key`:
    ```dart
    // main.dart
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
    ```
4.  **Configure AdMob:** Update the Ad Unit IDs in your `AdManager` class (or wherever your ads are configured) with your actual AdMob Ad Unit IDs.

## Running the Application

```bash
flutter run
```

## Security/Risk Analysis

This section identifies potential security risks and outlines mitigation strategies to ensure the integrity and reliability of the application, particularly concerning the ad-as-currency model.

### 1. Bypassing Ad Calls

**Risk:** Users might attempt to bypass rewarded video ad calls to gain free access to premium features without watching ads. This could involve using ad blockers, modifying network requests, or tampering with the application code.

**Mitigation Strategies:**
-   **Client-Side Validation & Obfuscation:** While client-side checks are not foolproof, implementing robust checks for ad completion (`onUserEarnedReward` callback) and obfuscating the client-side code can deter casual attempts. Ensure that the feature unlock logic is tightly coupled with the successful execution of the reward callback.
-   **Server-Side Verification (Future Enhancement):** For higher security, especially if the app scales or if ad fraud becomes a significant issue, consider implementing server-side verification of rewarded ad completions. This involves sending a server-to-server (S2S) callback from AdMob to your Supabase Edge Function (or a custom backend) to verify the reward before unlocking the feature. This would require a more complex backend setup but offers stronger protection against ad bypasses.
-   **Integrity Checks:** Implement app integrity checks (e.g., using Firebase App Check or similar services) to detect if the app has been tampered with or is running on an unverified environment.

### 2. Data Tampering (Offline Mode)

**Risk:** In offline mode, users might attempt to modify local data (e.g., grades, credit units) stored in Hive to artificially inflate their GPA/CGPA.

**Mitigation Strategies:**
-   **Data Validation on Sync:** When local data is synchronized with Supabase, implement server-side validation rules (e.g., using PostgreSQL triggers or Supabase functions) to check for suspicious changes. For instance, ensure that grades are within a valid range (0-100) and credit units are positive.
-   **Checksums/Hashes (Advanced):** For critical data, consider storing a hash or checksum of the data locally and verifying it against a server-generated hash during synchronization. Any mismatch would indicate tampering.
-   **Row Level Security (RLS):** Supabase RLS is already implemented in the schema to ensure users can only access and modify their own data, preventing unauthorized access to other users' academic records.

### 3. API Key Exposure

**Risk:** Hardcoding Supabase API keys or AdMob Ad Unit IDs directly in the client-side code could expose them, potentially leading to misuse.

**Mitigation Strategies:**
-   **Environment Variables/Build Flavors:** Use Flutter build configurations or environment variables to manage API keys, ensuring they are not directly committed to version control. While client-side keys are inherently exposed in a compiled app, this practice prevents accidental exposure in source code.
-   **Supabase RLS:** Leverage Supabase's Row Level Security to restrict data access based on authenticated user roles, minimizing the impact of a compromised API key.

### 4. Data Loss/Corruption

**Risk:** Issues during synchronization or local storage corruption could lead to loss or corruption of user academic data.

**Mitigation Strategies:**
-   **Robust Sync Logic:** Implement comprehensive error handling and retry mechanisms in the data synchronization service. Ensure atomic operations where possible.
-   **Regular Backups (Supabase):** Supabase automatically handles database backups, providing a safety net for server-side data. Educate users on the importance of syncing their data to the cloud.
-   **Local Data Integrity Checks:** Periodically verify the integrity of local Hive boxes, and provide mechanisms for users to report data discrepancies.

By addressing these risks proactively, the application can maintain a high level of security and provide a trustworthy experience for its users.

# 6. Degree Classification Tables

This section provides the degree classification tables for both the NUC (University) 5.0 scale and the NBTE (Polytechnic) 4.0 scale, which are crucial for understanding the academic standing of students in Nigerian tertiary institutions.

## NUC (University) 5.0 Scale Degree Classification

| CGPA Range  | Class of Degree       |
| :---------- | :-------------------- |
| 4.50 - 5.00 | First Class Honours   |
| 3.50 - 4.49 | Second Class Honours (Upper Division) |
| 2.40 - 3.49 | Second Class Honours (Lower Division) |
| 1.50 - 2.39 | Third Class Honours   |
| 1.00 - 1.49 | Pass                  |

## NBTE (Polytechnic) 4.0 Scale Degree Classification

| CGPA Range  | Class of Award        |
| :---------- | :-------------------- |
| 3.50 - 4.00 | Distinction           |
| 3.00 - 3.49 | Upper Credit          |
| 2.50 - 2.99 | Lower Credit          |
| 2.00 - 2.49 | Pass                  |
