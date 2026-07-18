# Technical Guide: CGPA and GPA Calculation for Nigerian Universities

This document provides a comprehensive technical guide for calculating Grade Point Average (GPA) and Cumulative Grade Point Average (CGPA) in Nigerian universities, based on the National Universities Commission (NUC) standards. This guide is intended to serve as a logic reference for developing an application to calculate academic performance in this context.

## 1. Standard 5.0 Grading Scale

Nigerian universities primarily operate under a 5.0 grading scale mandated by the National Universities Commission (NUC). This system maps percentage scores to letter grades and corresponding Grade Points (GP) [1]. While minor variations in percentage thresholds for 'D' and 'E' grades may exist across institutions, the core A=5, B=4, C=3 structure remains consistent [1].

### NUC 5.0 Grading Table

| Score Range (%) | Letter Grade | Grade Point (GP) |
| :-------------- | :----------- | :--------------- |
| 70 - 100        | A            | 5                |
| 60 - 69         | B            | 4                |
| 50 - 59         | C            | 3                |
| 45 - 49         | D            | 2                |
| 40 - 44         | E            | 1                |
| 0 - 39          | F            | 0                |

## 2. Calculation Formulas

The calculation of GPA and CGPA relies on two fundamental concepts: **Credit Units** and **Quality Points**.

*   **Credit Unit (CU):** Represents the academic weight of a course, typically ranging from 2 to 4 units, depending on the workload [1].
*   **Quality Point (QP):** Derived for each course by multiplying the Grade Point (GP) earned in that course by its Credit Unit (CU). 
    `QP = GP × CU`

### 2.1. Grade Point Average (GPA)

GPA is calculated per semester and reflects a student's academic performance within that specific period. It is the ratio of the total Quality Points earned in a semester to the total Credit Units registered for that semester [1].

`GPA = (Sum of Quality Points for all courses in a semester) / (Sum of Credit Units for all courses in a semester)`

### 2.2. Cumulative Grade Point Average (CGPA)

CGPA represents a student's overall academic performance across all semesters completed to date. It is a cumulative measure, calculated by dividing the sum of all Quality Points earned from the very first semester by the sum of all Credit Units registered from the very first semester [1].

`CGPA = (Sum of Total Quality Points from all semesters) / (Sum of Total Credit Units from all semesters)`

**Important Development Tip:** When implementing a 
grade training" feature, ensure logic accounts for the fact that CGPA is cumulative. This means that if a user adds a new semester, the calculator must not simply average the previous semesters' GPAs; it must re-sum all Quality Points and Credit Units from the very first semester to maintain mathematical accuracy.

## 3. Handling Carryovers/Repeats

In Nigerian universities, the handling of failed courses (carryovers) or repeated courses significantly impacts the CGPA calculation. When a student fails a course (earns an 'F' grade), they are typically required to retake it. The NUC guidelines generally allow for the failed course to be re-registered and the new grade obtained will be used in the CGPA calculation [2].

*   **Failed Courses (Carryovers):** If a student fails a course, the 'F' grade (0 Grade Point) is initially recorded and contributes to the GPA and CGPA. When the course is retaken and passed, the new grade and its corresponding Quality Points replace the previous 'F' grade's contribution to the cumulative totals. However, the 'F' grade typically remains on the academic transcript, but its impact on the CGPA is nullified by the successful retake [2].
*   **Repeating Courses for Grade Improvement:** Some universities may allow students to repeat courses they have passed (e.g., with a 'D' or 'E' grade) to improve their grade and, consequently, their CGPA. In such cases, the higher grade obtained from the repeat attempt is usually considered for CGPA calculation, while both grades may appear on the transcript [2]. It is crucial for the calculator to use the most recent or highest grade for the same course when calculating the cumulative totals.

## 4. Degree Classification

Upon graduation, a student's final CGPA determines their class of degree. The NUC has established standard ranges for degree classifications under the 5.0 grading system [1] [3].

### NUC Degree Classification (5.0 Scale)

| CGPA Range | Class of Degree        |
| :--------- | :--------------------- |
| 4.50 - 5.00  | First Class Honours    |
| 3.50 - 4.49  | Second Class Honours (Upper Division) |
| 2.40 - 3.49  | Second Class Honours (Lower Division) |
| 1.50 - 2.39  | Third Class Honours    |
| 1.00 - 1.49  | Pass Degree            |
| Below 1.00 | No Degree (Withdrawal) |

## 5. Technical Nuances

While the NUC provides a standardized framework, some technical nuances and variations can exist across different Nigerian institutions:

*   **Polytechnic Grading:** It is important to note that polytechnics in Nigeria, regulated by the National Board for Technical Education (NBTE), often use a 4.0 grading scale, which differs from the NUC's 5.0 scale for universities [4]. This guide focuses on the university system. If polytechnic calculations are needed, a separate grading table and degree classification would be required.
*   **Elective vs. Compulsory Courses:** Generally, both elective and compulsory courses contribute equally to the GPA and CGPA based on their credit units. There are typically no special rules that differentiate their impact on the overall calculation, beyond their assigned credit units [5]. However, students are usually required to pass all compulsory courses.
*   **Minimum CGPA for Graduation:** The NUC mandates a minimum CGPA of 1.50 for graduation. Students falling below this threshold after all academic requirements are met may not be awarded a degree [3].
*   **Academic Probation and Withdrawal:** Universities often have policies for academic probation when a student's CGPA falls below a certain threshold (e.g., 1.50 at the end of an academic year). Continued poor performance can lead to withdrawal from the program [1].

## References

[1] OpenEduCat. (2026, March 15). *Nigeria University Grading System: 5-Point CGPA and Degree Classes Explained*. Retrieved from https://openeducat.org/articles/nigeria-university-grading-system-cgpa-explained/
[2] SabiHow. (2026, January 28). *Does Carryover Affect Your CGPA? The Honest Truth Students*. Retrieved from https://sabihow.com.ng/does-carryover-affect-your-cgpa/
[3] Campus Reporter. (2018, October 21). *NUC wants universities to use five-point grading system*. Retrieved from https://campusreporter.africa/nuc-wants-universities-to-use-five-point-grading-system/
[4] OpenEduCat. *Nigeria Polytechnic Grading: ND & HND CGPA Scale*. Retrieved from https://openeducat.org/gradebook/nigeria/polytechnic/
[5] YouTube. (n.d.). *Meaning of Compulsory, Required and Elective Courses*. Retrieved from https://www.youtube.com/shorts/JUjU1cOUnac
