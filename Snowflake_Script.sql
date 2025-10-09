--Peek at the first 10 rows in the user profile table--
SELECT* FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE
LIMIT 10;

-------EDA-------
-- List all distinct raw gender values (to see data quality issues)--
SELECT DISTINCT GENDER
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE;

-- Normalizing gender by replacing null/None with 'Unknown'--
SELECT DISTINCT
CASE
    WHEN GENDER IS Null THEN 'Unknown'
    WHEN GENDER = 'None' THEN 'Unknown'
    ELSE GENDER
END AS GENDER
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE;

-- List all distinct raw province values--
SELECT DISTINCT PROVINCE
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE;

-- Normalize province by replacing null/None with 'Unknown'--
SELECT DISTINCT
CASE
    WHEN PROVINCE IS Null THEN 'Unknown'
    WHEN PROVINCE = 'None' THEN 'Unknown'
    ELSE PROVINCE
END AS PROVINCE
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE;

-- List all distinct raw race values--
SELECT DISTINCT RACE
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE;

-- Normalizing race by replacing null/other/None to 'Unknown'--
SELECT DISTINCT
CASE
    WHEN RACE IS Null THEN 'Unknown'
    WHEN RACE = 'other' THEN 'Unknown'
    WHEN RACE = 'None' THEN 'Unknown'
    ELSE RACE
END AS RACE
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE;

-- Checking Null USERID--
SELECT*
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE
WHERE USERID IS NULL;

-- Checking Null Values in AGE Column--
SELECT*
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE
WHERE AGE IS NULL;

----Checking dupliicates---
--Counting duplicate USERID rows-- 
SELECT USERID,
COUNT(*) AS Row_cnt
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE
GROUP BY USERID
HAVING Row_cnt>1;

------CREATING TEMP TABLES-----
CREATE OR REPLACE TEMP TABLE BRIGHTTV.BRIGHTTV_DATASET.USER_DETAILS AS (
SELECT
USERID,
AGE,

    -- Creating Age Bucket--
CASE 
             WHEN AGE BETWEEN '0' AND '14' THEN 'Kids: 0 to 14'
             WHEN AGE BETWEEN '15' AND '19' THEN 'Teenagers: 15 t0 19'
             WHEN AGE BETWEEN '20' AND '30' THEN 'Young Adults: 20 to 30'
             WHEN AGE BETWEEN '31' AND '49' THEN 'Adults: 31 to 49'
             ELSE 'Elder: 50 to 114'
         END AS AGE_bucket,

-- Clean gender column replace Null values by 'Unknown'--
CASE
    WHEN GENDER IS Null THEN 'Unknown'
    WHEN GENDER = 'None' THEN 'Unknown'
    ELSE GENDER
END AS GENDER,

-- Clean province column replace Null values by 'Unknown'--
CASE
    WHEN PROVINCE IS Null THEN 'Unknown'
    WHEN PROVINCE = 'None' THEN 'Unknown'
    ELSE PROVINCE
END AS PROVINCE,

-- Clean race column replace Null values by 'Unknown'--
CASE
    WHEN RACE IS Null THEN 'Unknown'
    WHEN RACE = 'other' THEN 'Unknown'
    WHEN RACE = 'None' THEN 'Unknown'
    ELSE RACE
END AS RACE
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_USERPROFILE
);
--Checking the user profile temp table--
SELECT* FROM BRIGHTTV.BRIGHTTV_DATASET.USER_DETAILS;

-- Inspect the raw viewership table--
SELECT* FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_VIEWERSHIP;

-- Create a temp table with parsed timestamp--
CREATE OR REPLACE TEMP TABLE BRIGHTTV.BRIGHTTV_DATASET.VIEWS AS (
SELECT COALESCE(USERID, USERID) AS USERID,
CHANNEL2 AS TV_CHANNEL,
TRY_TO_TIMESTAMP_NTZ(RECORDDATE2, 'YYYY/MM/DD HH24:MI')AS RECORD_TS ,
TO_TIME(RECORD_TS) AS WATCH_TIME,

--Create Time Bucket--    
 CASE 
             WHEN WATCH_TIME BETWEEN '00:00:00' AND '05:59:59' THEN 'Early Morning: 12am to 6am'
             WHEN WATCH_TIME BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning: 6am to 12pm'
             WHEN WATCH_TIME BETWEEN '12:00:00' AND '13:59:59' THEN 'During The Day: 12pm to 2pm'
             WHEN WATCH_TIME BETWEEN '14:00:00' AND '16:59:59' THEN 'Afternoon: 2pm to 5pm'
             WHEN WATCH_TIME BETWEEN '17:00:00' AND '20:59:59' THEN 'Early Evening: 5pm to 9pm'
             ELSE 'Late Evening: 10pm to 12pm'
         END AS TIME_BUCKET,

--Extracting Day of Month, Month Name, , Year, Day Name from the Watch Date--
TO_DATE(RECORD_TS) AS WATCH_DATE,
DAYOFMONTH(WATCH_DATE) AS DAY_OF_THE_MONTH,
MONTHNAME(WATCH_DATE) AS MONTH_NAME,
YEAR(TO_DATE(WATCH_DATE)) AS YEAR, 
DAYNAME(WATCH_DATE) AS DAY_OF_THE_WEEK,

-- Classifying days as weekend/weekday--
CASE
            WHEN DAY_OF_THE_WEEK IN('Sat', 'Sun') THEN 'Weekend'
            ELSE 'Weekday'
         END AS DAY_CATEGORY,

-- Returning Duration column as it is--
DURATION2 AS DURATION
FROM BRIGHTTV.BRIGHTTV_DATASET.BRIGHTTV_VIEWERSHIP
);

--checking of the temp view table
    SELECT* FROM BRIGHTTV.BRIGHTTV_DATASET.VIEWS;

------Now Joining the Temp Tables-----

-- Create a new combined temp table
CREATE OR REPLACE TEMP TABLE BRIGHTTV.BRIGHTTV_DATASET.COMBINED_DATASET AS
(SELECT 
    U.USERID,
    U.AGE,
    u.AGE_bucket,
    U.GENDER,
    U.RACE,
    U.PROVINCE,
    V.TV_CHANNEL,
    V.WATCH_TIME,
    V.TIME_BUCKET,
    V.WATCH_DATE,
    V.DAY_OF_THE_MONTH,
    V.MONTH_NAME,
    V.YEAR,
    V.DAY_OF_THE_WEEK,
    V. DAY_CATEGORY,
    V.DURATION,
  
FROM  BRIGHTTV.BRIGHTTV_DATASET.USER_DETAILS AS U
LEFT JOIN BRIGHTTV.BRIGHTTV_DATASET.VIEWS AS V
    ON U.USERID = V.USERID);

-- Final check of the joined dataset--
SELECT* FROM  BRIGHTTV.BRIGHTTV_DATASET.COMBINED_DATASET;
