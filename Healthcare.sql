--create warehouse
create warehouse Hospital_ops
 WAREHOUSE_SIZE = 'XSMALL'          
  AUTO_SUSPEND = 60                  
  AUTO_RESUME = TRUE

USE WAREHOUSE Hospital_ops;
--Create Database
CREATE DATABASE Hospital_ops_db;
use Hospital_ops_db;

-- CREATE SCHEMA
CREATE SCHEMA Hospital_ops_schema;

USE SCHEMA Hospital_ops_schema;
-- data exploration
-- sample of data
select * from patient limit 10;

-- count of rows
select count(*) from patient;

-- check null values

SELECT
    COUNT(*) AS Total_rows,
    COUNT_IF(patient_admission_date IS NULL) AS date_nulls,
    COUNT_IF(patient_admission_time IS NULL) AS time_nulls,
    COUNT_IF(patient_age IS NULL) AS age_nulls,
    COUNT_IF(patient_gender IS NULL) AS gender_nulls,
    COUNT_IF(patient_race IS NULL) AS race_nulls,
    COUNT_IF(department_referral IS NULL) AS department_nulls,
    COUNT_IF(patient_admission_flag IS NULL) AS admission_flag_nulls,
    COUNT_IF(patient_waittime IS NULL) AS waittime_nulls,
    COUNT_IF(patient_satisfaction_score IS NULL) AS satisfaction_nulls,
    COUNT_IF(visit_type IS NULL) AS visit_nulls,
    COUNT_IF(doctor_id IS NULL) AS doctor_nulls
FROM patient;

-- Date Range
select min(patient_admission_date) as start_date,
    max(patient_admission_date) as end_date
from patient ;

-- checking patients per department
select department_referral, count(*) as total_patients
from patient
group by department_referral
order by total_patients desc;


-- patient distribution by gender
select patient_gender, count(*) as total_patients
from patient
group by patient_gender
order by total_patients desc;

-- doctors data exploration

select * from doctor limit 10;

-- doctors per department
select department, count(doctor_id) as "Number of doctors"
from doctor
group by department
order by "Number of doctors" desc;

-- Data Cleaning
-- 1. Convert admission date into DATE format
-- 2. Change null values in Dept to "Unknown"
-- 3. Change ambiguous values in gender to "Unknown"

CREATE OR REPLACE TABLE patient_cleaned AS
SELECT * REPLACE(

-- Fix date
TO_DATE(patient_admission_date, 'DD-MM-YYYY') AS patient_admission_date,

-- Fix nulls in department
COALESCE(department_referral, 'Unknown') AS department_referral,

-- Fix gender
IFF(LOWER(patient_gender) = 'femaleemale', 'Unknown', patient_gender) AS patient_gender
)

from patient;

data analysis 

--Q1 How has patient volume changed over time? Calculate  monthly patient encounter counts to identify trends and growth patterns.
select
extract(month from patient_admission_date) as month,
extract(year from patient_admission_date) as year,
count(*) as patient_volume
from patient_cleaned
group by year,month
order by year, month;

select
extract(year from patient_admission_date) as year,
count(*) as patient_volume
from patient_cleaned
group by year
order by year;

--Q2 How does patient volume vary by visit type (Emergency vs Walk-in vs Scheduled)?
select visit_type, count(*) as total_patients
from patient_cleaned
group by visit_type
order by total_patients desc;

--Q3. What is the average wait time across the hospital, and how does it vary by department?
select ROUND(AVG(patient_waittime),2) 
from patient_cleaned;

select department_referral,
ROUND(AVG(patient_waittime),2) as avg_wait_time
from patient_cleaned
group by department_referral
order by avg_wait_time desc;

-- Q4. What % of patients wait more than 30 mins?

select 100 * count_if(patient_waittime > 30) / count(*)
from patient_cleaned;

--Q5. What are the peak hours for patient arrivals?
select extract(hour from patient_admission_time) as hour, count(*) as patient_volume
from patient_cleaned
group by hour
order by hour;

--Q6. Which department & hour of the day combinations experience the highest wait times?
select department_referral, 
extract(hour from patient_admission_time) as hour,
ROUND(AVG(patient_waittime),2) as avg_wait_time
from patient_cleaned
group by department_referral, hour
order by avg_wait_time desc;


--Q7. How does patient satisfaction vary by department?
select department_referral,
ROUND(AVG(patient_satisfaction_score),2) as avg_satisfaction_score
from patient_cleaned
where patient_satisfaction_score is not null
group by department_referral
order by avg_satisfaction_score desc;

--Q8. How do admission rates differ across departments?
select department_referral,
ROUND(100 * (COUNT_IF(patient_admission_flag = 'Admission')/COUNT(*)),2) as rate_of_patients_admission
from patient_cleaned
group by department_referral
order by rate_of_patients_admission desc ;

--Q9. Is there a relationship between wait time duration and likelihood of patient admission?

SELECT
    CASE 
        WHEN patient_waittime >= 30 THEN 'Long Wait'
        WHEN patient_waittime >= 15 THEN 'Medium Wait'
        ELSE 'Short Wait'
    END AS wait_bucket,
    COUNT(*) AS total_patients,
    COUNT_IF(patient_admission_flag = 'Admission') AS admissions,
    ROUND(100 * COUNT_IF(patient_admission_flag = 'Admission') / COUNT(*), 2) AS admission_rate_pct
FROM patient_cleaned
GROUP BY wait_bucket
ORDER BY admission_rate_pct DESC;

--Q10. How do different shifts compare in terms of patient load and wait time?
select
d.shift_type,
COUNT(p.patient_id) as patient_volume,
ROUND(AVG(p.patient_waittime),2) as avg_wait_time
from patient_cleaned p
JOIN doctor d 
    ON p.doctor_id = d.doctor_id
group by d.shift_type
order by avg_wait_time desc;

--Q11. What shift types exist among doctors, and how many doctors work each shift, per department?
SELECT department, shift_type, COUNT(doctor_id) AS doctor_count
FROM doctor
GROUP BY department, shift_type
ORDER BY department, shift_type;

--Q12. Which department + shift combinations have the highest patient-per-doctor load?

WITH patient_shift AS (
    SELECT
        patient_id,
        department_referral,
        doctor_id,
        CASE
            WHEN EXTRACT(HOUR FROM patient_admission_time) BETWEEN 6 AND 13 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM patient_admission_time) BETWEEN 14 AND 21 THEN 'Evening'
            ELSE 'Night'
        END AS shift_type
    FROM patient_cleaned
),
demand AS (
    SELECT department_referral, shift_type, COUNT(*) AS patient_count
    FROM patient_shift
    GROUP BY department_referral, shift_type
),
capacity AS (
    SELECT department, shift_type, COUNT(doctor_id) AS doctor_count
    FROM doctor
    GROUP BY department, shift_type
)
SELECT
    d.department_referral,
    d.shift_type,
    d.patient_count,
    c.doctor_count,
    ROUND(d.patient_count / NULLIF(c.doctor_count, 0), 2) AS patients_per_doctor
FROM demand d
JOIN capacity c
    ON d.department_referral = c.department
    AND d.shift_type = c.shift_type
ORDER BY patients_per_doctor DESC;
  
