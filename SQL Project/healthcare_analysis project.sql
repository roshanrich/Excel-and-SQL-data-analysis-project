
-- =====================================================
-- PROJECT: HEALTHCARE APPOINTMENT ANALYSIS
-- DATABASE: MySQL
-- =====================================================


-- 1. DATABASE CREATION
CREATE DATABASE IF NOT EXISTS healthcare_analysis;

USE healthcare_analysis;


-- 2. CREATE PATIENTS TABLE
CREATE TABLE IF NOT EXISTS Patients (
    PatientID INT PRIMARY KEY,
    PatientName VARCHAR(100),
    Gender VARCHAR(100),
    Age INT,
    RegistrationDate DATE
);


-- 3. CREATE APPOINTMENTS TABLE
CREATE TABLE IF NOT EXISTS Appointments (
    AppointmentID INT PRIMARY KEY,
    PatientID INT,
    AppointmentDate DATE,
    Department VARCHAR(100),
    DoctorID INT,
    Status VARCHAR(20),
    FOREIGN KEY (PatientID)
        REFERENCES Patients(PatientID)
);


-- 4. VIEW TABLES AND DATA
SHOW TABLES;

SELECT * FROM Patients;

SELECT * FROM Appointments;


-- =====================================================
-- DATA QUALITY CHECKS
-- =====================================================


-- 5. CHECK DUPLICATE PATIENT IDs
-- PatientID is a primary key, so duplicates are prevented.

SELECT PatientID, COUNT(*) AS RecordCount
FROM Patients
GROUP BY PatientID
HAVING COUNT(*) > 1;


-- 6. CHECK NULL VALUES IN PATIENTS

SELECT *
FROM Patients
WHERE PatientName IS NULL
   OR Gender IS NULL
   OR Age IS NULL
   OR RegistrationDate IS NULL;


-- 7. CHECK NULL VALUES IN APPOINTMENTS

SELECT *
FROM Appointments
WHERE PatientID IS NULL
   OR AppointmentDate IS NULL
   OR Department IS NULL
   OR DoctorID IS NULL
   OR Status IS NULL;


-- 8. CHECK INVALID PATIENT AGES

SELECT *
FROM Patients
WHERE Age <= 0 OR Age >= 120;


-- 9. CHECK DISTINCT GENDER VALUES

SELECT DISTINCT Gender
FROM Patients;


-- 10. CHECK DISTINCT APPOINTMENT STATUSES

SELECT DISTINCT Status
FROM Appointments;


-- =====================================================
-- KEY PERFORMANCE INDICATORS (KPIs)
-- =====================================================


-- 11. TOTAL UNIQUE PATIENTS

SELECT COUNT(DISTINCT PatientID) AS Number_of_Patients
FROM Patients;


-- 12. TOTAL UNIQUE APPOINTMENTS

SELECT COUNT(DISTINCT AppointmentID) AS Number_of_Appointments
FROM Appointments;


-- =====================================================
-- PATIENT DEMOGRAPHIC ANALYSIS
-- =====================================================


-- 13. PATIENT COUNT BY GENDER

SELECT
    Gender,
    COUNT(*) AS PatientCount
FROM Patients
GROUP BY Gender
ORDER BY PatientCount DESC;


-- 14. AVERAGE AGE BY GENDER

SELECT
    Gender,
    ROUND(AVG(Age), 2) AS AverageAge
FROM Patients
GROUP BY Gender
ORDER BY Gender;


-- 15. PATIENT AGE DISTRIBUTION

SELECT
    CASE
        WHEN Age < 18 THEN 'Under 18'
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 45 THEN '31-45'
        WHEN Age BETWEEN 46 AND 60 THEN '46-60'
        WHEN Age > 60 THEN 'Above 60'
        ELSE 'Unknown'
    END AS AgeGroup,
    COUNT(*) AS PatientCount
FROM Patients
GROUP BY AgeGroup
ORDER BY MIN(Age);


-- =====================================================
-- APPOINTMENT TREND ANALYSIS
-- =====================================================


-- 16. MONTHLY APPOINTMENT TREND
-- Chronological sorting by year and month

SELECT
    YEAR(AppointmentDate) AS AppointmentYear,
    MONTH(AppointmentDate) AS AppointmentMonth,
    DATE_FORMAT(AppointmentDate, '%M-%Y') AS Month_And_Year,
    COUNT(*) AS AppointmentCount
FROM Appointments
WHERE AppointmentDate IS NOT NULL
GROUP BY
    YEAR(AppointmentDate),
    MONTH(AppointmentDate),
    DATE_FORMAT(AppointmentDate, '%M-%Y')
ORDER BY
    AppointmentYear,
    AppointmentMonth;


-- 17. APPOINTMENT STATUS DISTRIBUTION

SELECT
    Status,
    COUNT(*) AS AppointmentCount
FROM Appointments
GROUP BY Status
ORDER BY AppointmentCount DESC;


-- 18. DEPARTMENT-WISE APPOINTMENT COUNT

SELECT
    Department,
    COUNT(*) AS TotalAppointments
FROM Appointments
GROUP BY Department
ORDER BY TotalAppointments DESC;


-- 19. TOP 3 DEPARTMENTS WITH THE MOST MISSED APPOINTMENTS

SELECT
    Department,
    COUNT(*) AS MissedAppointmentCount
FROM Appointments
WHERE LOWER(TRIM(Status)) = 'missed'
GROUP BY Department
ORDER BY MissedAppointmentCount DESC
LIMIT 3;


-- =====================================================
-- REPEATED PATIENT ANALYSIS
-- =====================================================


-- 20. PATIENTS WITH MORE THAN ONE APPOINTMENT

SELECT
    PatientID,
    COUNT(*) AS AppointmentCount
FROM Appointments
GROUP BY PatientID
HAVING COUNT(*) > 1
ORDER BY AppointmentCount DESC;


-- 21. REPEATED PATIENT RATE
-- Percentage of patients with more than one appointment
-- among patients who have at least one appointment.

WITH PatientAppointmentCounts AS (
    SELECT
        PatientID,
        COUNT(*) AS AppointmentCount
    FROM Appointments
    WHERE PatientID IS NOT NULL
    GROUP BY PatientID
)
SELECT
    ROUND(
        100.0 * SUM(
            CASE
                WHEN AppointmentCount > 1 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS RepeatedPatientRate_Percent
FROM PatientAppointmentCounts;


-- 22. ALTERNATIVE: REPEATED PATIENT RATE USING A SUBQUERY

SELECT
    ROUND(
        100.0 * COUNT(*) /
        NULLIF(
            (SELECT COUNT(DISTINCT PatientID)
             FROM Appointments
             WHERE PatientID IS NOT NULL),
            0
        ),
        2
    ) AS RepeatedPatientRate_Percent
FROM (
    SELECT PatientID
    FROM Appointments
    WHERE PatientID IS NOT NULL
    GROUP BY PatientID
    HAVING COUNT(*) > 1
) AS RepeatedPatients;


-- =====================================================
-- DOCTOR PERFORMANCE ANALYSIS
-- =====================================================


-- 23. TOTAL APPOINTMENTS BY DOCTOR AND DEPARTMENT

SELECT
    Department,
    DoctorID,
    COUNT(*) AS AppointmentCount
FROM Appointments
WHERE DoctorID IS NOT NULL
GROUP BY Department, DoctorID
ORDER BY Department, AppointmentCount DESC;


-- 24. AVERAGE APPOINTMENTS PER DOCTOR BY DEPARTMENT
-- Includes doctors who have at least one appointment
-- in the relevant department.

WITH DoctorAppointmentCounts AS (
    SELECT
        Department,
        DoctorID,
        COUNT(*) AS AppointmentCount
    FROM Appointments
    WHERE DoctorID IS NOT NULL
    GROUP BY Department, DoctorID
)
SELECT
    Department,
    ROUND(AVG(AppointmentCount), 2)
        AS AverageAppointmentsPerDoctor
FROM DoctorAppointmentCounts
GROUP BY Department
ORDER BY AverageAppointmentsPerDoctor DESC;


-- =====================================================
-- END OF HEALTHCARE APPOINTMENT ANALYSIS
-- =====================================================
