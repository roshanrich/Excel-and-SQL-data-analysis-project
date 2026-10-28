
CREATE DATABASE healthcare_analysis;
USE healthcare_analysis;

CREATE TABLE patients (
    PatientID INT PRIMARY KEY,
    PatientName VARCHAR(100),
    Gender VARCHAR(100),
    Age INT,
    RegistrationDate DATE
);

CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY,
    PatientID INT,
    AppointmentDate DATE,
    Department VARCHAR(100),
    DoctorID INT,
    Status VARCHAR(20),
    FOREIGN KEY (patientID)
        REFERENCES Patients (patientID)
);

SELECT * FROM patients;
SELECT * FROM appointments;


-- =====================================================
-- DATA QUALITY AND VALIDATION
-- =====================================================

-- 1. Identify duplicate patient records

SELECT patientID, COUNT(*) AS Count_of_Duplicate_Records
FROM patients
GROUP BY patientID
HAVING COUNT(*) > 1;


-- 2. Identify records containing missing values

SELECT *
FROM patients
WHERE patientID IS NULL
   OR Patientname IS NULL
   OR Gender IS NULL
   OR Age IS NULL
   OR RegistrationDate IS NULL;


-- 3. Review the available appointment status categories

SELECT DISTINCT status
FROM appointments;

SELECT * FROM patients;


-- 4. Detect patients with invalid age values

SELECT *
FROM patients
WHERE age < 0 OR age > 120;


-- 5. Check whether appointment records have matching patient records

SELECT *
FROM patients p
LEFT JOIN appointments a
    ON a.patientID = p.patientID
WHERE p.patientID IS NULL;


-- Data validation completed; proceed with the analysis.

SELECT * FROM patients;
SELECT * FROM appointments;


-- =====================================================
-- PATIENT AND APPOINTMENT OVERVIEW
-- =====================================================

-- 1. Calculate the total number of unique patients

SELECT COUNT(DISTINCT patientname) AS Number_of_Patients
FROM patients;


-- 2. Calculate the total number of unique appointments

SELECT COUNT(DISTINCT appointmentid) AS Number_of_Appointments
FROM appointments;


-- =====================================================
-- PATIENT DEMOGRAPHIC ANALYSIS
-- =====================================================

-- 3. Examine the distribution of patients across genders

SELECT gender, COUNT(*) AS Count_of_Patients
FROM patients
GROUP BY gender;


-- 4. Calculate the average patient age for each gender

SELECT gender, ROUND(AVG(age)) AS Avg_Age_of_Patients
FROM patients
GROUP BY gender;


-- =====================================================
-- APPOINTMENT TREND ANALYSIS
-- =====================================================

-- 5. Analyze appointment volumes by month and year

SELECT * FROM appointments;

SELECT
    DATE_FORMAT(appointmentdate, '%M-%Y') AS Month_and_Year,
    COUNT(*) AS Count_of_Appointments
FROM appointments
GROUP BY 1
ORDER BY 1;


-- =====================================================
-- DEPARTMENT-WISE MISSED APPOINTMENT ANALYSIS
-- =====================================================

-- 6. Identify the top three departments with the highest
--    number of missed appointments and assign their ranks

WITH CTE AS (
    SELECT department, status
    FROM appointments
    WHERE status = 'missed'
),

CTE2 AS (
    SELECT
        department,
        COUNT(status) AS No_of_Missed_Appointments
    FROM CTE
    GROUP BY department
    ORDER BY COUNT(status) DESC
    LIMIT 3
)

SELECT
    department,
    No_of_missed_appointments,
    RANK() OVER (
        ORDER BY No_of_Missed_Appointments DESC
    ) AS Rank_of_Missed_Appointments
FROM CTE2;


-- Alternative approach: Retrieve the three departments
-- with the highest missed appointment counts

SELECT
    Department,
    COUNT(*) AS MissedAppointments
FROM appointments
WHERE Status = 'Missed'
GROUP BY Department
ORDER BY MissedAppointments DESC
LIMIT 3;


-- =====================================================
-- APPOINTMENT STATUS ANALYSIS
-- =====================================================

-- 7. Summarize appointments by their respective statuses

SELECT
    status,
    COUNT(*) AS Count_of_Statuses
FROM appointments
GROUP BY status;


-- =====================================================
-- REPEAT PATIENT ANALYSIS
-- =====================================================

-- 8. Calculate the repeat patient rate using CTEs

WITH Repeating_patients_No AS (
    SELECT
        patientId,
        COUNT(patientID) AS Repeating_Numbers
    FROM appointments
    GROUP BY patientID
    HAVING Repeating_Numbers > 1
),

Unique_patient_No AS (
    SELECT COUNT(DISTINCT PatientID) AS No_of_Unique_Patients
    FROM appointments
)

SELECT
    COUNT(*) / (SELECT * FROM unique_patient_No) * 100
        AS Repeat_Patient_Rate
FROM Repeating_patients_No;


-- Alternative approach: Calculate the repeat patient rate
-- using a subquery

SELECT
    COUNT(*) * 100.0 / (
        SELECT COUNT(DISTINCT PatientID)
        FROM appointments
    ) AS Repeat_Patient_Rate
FROM (
    SELECT PatientID
    FROM appointments
    GROUP BY PatientID
    HAVING COUNT(*) > 1
) AS RepeatPatients;

SELECT * FROM appointments;


-- =====================================================
-- DOCTOR WORKLOAD ANALYSIS
-- =====================================================

-- 9. Calculate the average appointment volume per doctor
--    across each department

SELECT
    department,
    COUNT(*) AS No_of_Appointments,
    COUNT(DISTINCT doctorID) AS No_of_Doctors,
    COUNT(*) / COUNT(DISTINCT doctorID) AS Avg_Appointments
FROM appointments
GROUP BY department
ORDER BY avg_appointments DESC;


-- =====================================================
-- PATIENTS WITH REPEATED MISSED APPOINTMENTS
-- =====================================================

-- 10. Identify patients who have missed more than
--     two appointments

SELECT * FROM patients;
SELECT * FROM appointments;

SELECT
    p.patientid,
    p.patientName,
    COUNT(a.appointmentid) AS Count_of_Appointments
FROM patients p
INNER JOIN appointments a
    ON p.patientid = a.patientid
WHERE status = 'missed'
GROUP BY 1, 2
HAVING Count_of_Appointments > 2
ORDER BY 3 DESC;


-- =====================================================
-- APPOINTMENT INTERVAL ANALYSIS
-- =====================================================

-- 11. Calculate the average number of days between
--     appointments for patients registered in 2020

USE healthcare_analysis;

SELECT * FROM appointments;
SELECT * FROM patients;

WITH CTE AS (
    SELECT patientid, patientname
    FROM patients
    WHERE YEAR(Registrationdate) = '2020'
),

CTE2 AS (
    SELECT
        c.patientname,
        a.appointmentdate
    FROM CTE c
    INNER JOIN appointments a
        ON c.patientid = a.patientid
    ORDER BY c.patientname ASC
),

CTE3 AS (
    SELECT
        patientname,
        appointmentdate,
        LAG(appointmentdate) OVER (
            PARTITION BY patientname
            ORDER BY APPOINTMENTDATE
        ) AS Previous_App_date
    FROM CTE2
),

CTE4 AS (
    SELECT
        patientname,
        appointmentdate,
        PREVIOUS_APP_DATE,
        DATEDIFF(
            appointmentdate,
            previous_app_date
        ) AS Diff_of_App
    FROM CTE3
)

SELECT
    patientname,
    AVG(Diff_of_App) AS Avg_Appointment_Gap
FROM CTE4
GROUP BY 1;


-- =====================================================
-- APPOINTMENT SEQUENCING AND FIRST-VISIT IDENTIFICATION
-- =====================================================

-- 12. Rank each patient's appointments by date and
--     identify their first recorded visit

WITH Ranked_Visits AS (
    SELECT
        patientid,
        appointmentdate,
        RANK() OVER (
            PARTITION BY patientid
            ORDER BY appointmentdate
        ) AS Rank_of_Visits
    FROM appointments
)

SELECT
    patientid,
    appointmentdate,
    rank_of_visits,
    CASE
        WHEN Rank_of_Visits = 1 THEN 'First_Visit'
        ELSE NULL
    END AS Flag_Visits
FROM Ranked_visits;


-- =====================================================
-- DEPARTMENT-WISE MONTHLY NO-SHOW ANALYSIS
-- =====================================================

-- 13. Measure monthly no-show rates for each department

SELECT
    department,
    YEAR(appointmentdate),
    MONTH(appointmentdate),
    COUNT(
        CASE
            WHEN status = 'missed' THEN 1
        END
    ) * 100 / COUNT(*) AS No_Show_Rate
FROM appointments
GROUP BY 1, 2, 3
ORDER BY 1, 2 DESC;
