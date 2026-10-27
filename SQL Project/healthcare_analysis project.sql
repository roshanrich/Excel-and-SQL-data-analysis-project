create database healthcare_analysis;
use healthcare_analysis;

create table patients (
PatientID INT PRIMARY KEY,
PatientName Varchar(100),
Gender varchar(100),
Age INT,
RegistrationDate Date );

create table Appointments (
AppointmentID INT PRIMARY KEY,
PatientID INT,
AppointmentDate Date,
Department Varchar(100),
DoctorID INT,
Status Varchar(20),
foreign key ( patientID )
References Patients (patientID));
use healthcare_analysis;
show tables;
select * from patients;
use healthcare_analysis;
select * from patients;

--- 1. Total Unique patients 
select count(distinct patientname) as Number_of_Patients from patients;
--- 1. Total unique Appointments
select count(distinct appointmentid) as Number_of_Appointments from appointments;


select * from patients;
select * from appointments;

------ celeaning -----

select patientid , count(*) from patients
group by patientid
having count(*) > 1;

--- null ----

---- check appointment status ----

select distinct status from appointments;

----- check invalid age -------
select age from patients
where age <= 0 or age >= 120 ;

select count(distinct patientname) as number_of_patients
from patients;
select count(distinct appointmentid) as number_of_appointments
from appointments;

select Gender, COUNT(*) as PatientCount
from Patients
group by Gender;

select Gender, round(avg(Age)) as AverageAge
from patients
group by gender;

select date_format(appointmentdate,'%M-%Y') as month_and_year, count(*)
 as count_of_appointments from appointments
 group by 1
 order by 1;
 
 select department,count(*)as no_of_missed__appointments from appointments
where status = 'missed'
 group by department
 order by no_of_appointments desc
 limit 3;
 
 select status,count(*) as distribution_of_status from appointments
 group by 1;
 
 with cte as(select patientid , count(*) as no_of_repeated_appointment
from appointments
group by 1 
having count(*) > 1),

cte1 as (select count(distinct patientid) as no_of_unique_patients 
from  appointments)

select count(*) * 100 /
 (select no_of_unique_patients from cte1 ) from cte;
 
--- Using Subquery
select count(*) / ( select count(distinct patientid) from appointments) *100 as Repeated_rate from (
select patientid , count(*) as No_of_Repeated_Appointments from appointments
group by 1
having No_of_Repeated_Appointments >1) as No_of_repeated_patients;

select * from appointments;


with cte as (select department , doctorid , count(*) as appointmentcount 
from appointments
group by 1 , 2)

select department, avg(appointmentcount) as avgappointmnetperdoc from cte
group by 1;

use healthcare_analysis;