-- -- DIMENSION TABLES

-- CREATE TABLE dim_date (
--     date_id SERIAL PRIMARY KEY,
--     day INT,
--     month INT,
--     year INT
-- );


-- CREATE TABLE dim_location (
--     location_id SERIAL PRIMARY KEY,
--     lga_name VARCHAR(100),
--     sa4_name VARCHAR(100),
--     state VARCHAR(10),
--     remoteness_area VARCHAR(50)
-- );

-- CREATE TABLE dim_vehicle (
--     vehicle_id SERIAL PRIMARY KEY,
--     crash_type VARCHAR(50),
--     bus_involved BOOLEAN,
--     rigid_truck_involved BOOLEAN,
--     articulated_truck_involved BOOLEAN
-- );


-- DROP TABLE dim_road CASCADE
-- CREATE TABLE dim_road (
--     road_id SERIAL PRIMARY KEY,
--     road_type VARCHAR(50),
--     speed_limit VARCHAR(50),
--     christmas_period BOOLEAN,
--     easter_period BOOLEAN
-- );

-- CREATE TABLE dim_time (
--     time_id SERIAL PRIMARY KEY,
--     time TIME,
--     day_of_week VARCHAR(20),
--     time_of_day VARCHAR(20)
-- );

-- CREATE TABLE dim_person (
--     person_id SERIAL PRIMARY KEY,
--     gender VARCHAR(10),
--     age INT,
--     age_group VARCHAR(20),
--     road_user VARCHAR(50)
-- );

-- CREATE TABLE dim_dwelling (
--     dwelling_id SERIAL PRIMARY KEY,
--     lga_name VARCHAR(100),
--     dwelling_count INT
-- );


-- CREATE TABLE dim_event_flags (
--     event_id SERIAL PRIMARY KEY,
--     christmas_period BOOLEAN,
--     easter_period BOOLEAN
-- );

-- -- FACT TABLES

DROP TABLE fact_crashes CASCADE
CREATE TABLE fact_crashes (
    crash_id BIGINT PRIMARY KEY,
    date_id INT REFERENCES dim_date(date_id),
    location_id INT REFERENCES dim_location(location_id),
    vehicle_id INT REFERENCES dim_vehicle(vehicle_id),
    road_id INT REFERENCES dim_road(road_id),
    time_id INT REFERENCES dim_time(time_id),
    dwelling_id INT REFERENCES dim_dwelling(dwelling_id),
    event_id INT REFERENCES dim_event_flags(event_id),
    num_fatalities INT
);
ALTER TABLE fact_crashes ADD COLUMN event_id INT REFERENCES dim_event_flags(event_id);

-- CREATE TABLE fact_fatalities (
--     fatality_id SERIAL PRIMARY KEY,
--     crash_id BIGINT REFERENCES fact_crashes(crash_id),
--     person_id INT REFERENCES dim_person(person_id),
--     date_id INT REFERENCES dim_date(date_id),
--     location_id INT REFERENCES dim_location(location_id),
--     time_id INT REFERENCES dim_time(time_id),
--     person_count INT DEFAULT 1
-- );


-- select * from stg_crashes
-- select * from dim_date

-- INSERT script DML------

-- 1. Load dim_date
-- INSERT INTO dim_date (day, month, year)
-- SELECT DISTINCT 1 AS day, CAST("Month" AS INTEGER), CAST("Year" AS INTEGER)
-- FROM stg_crashes
-- WHERE "Month" IS NOT NULL AND "Year" IS NOT NULL
-- ON CONFLICT DO NOTHING;
-- -- select * from dim_date

-- -- 2. Load dim_time
-- INSERT INTO dim_time (time, day_of_week, time_of_day)
-- SELECT DISTINCT "Time", "Day of week", "Time of Day"
-- FROM stg_crashes
-- WHERE "Time" IS NOT NULL
-- ON CONFLICT DO NOTHING;
-- -- select * from dim_time

-- -- 3. Load dim_location
-- -- TRUNCATE table dim_location CASCADE
-- INSERT INTO dim_location (lga_name, sa4_name, state, remoteness_area)
-- SELECT DISTINCT 
--   "National LGA Name 2021", 
--   "SA4 Name 2021", 
--   "State", 
--   "National Remoteness Areas"
-- FROM stg_crashes
-- ON CONFLICT DO NOTHING;
-- -- select * from dim_location order by lga_name where location_id in (1601, 1353)

-- -- 4. Load dim_vehicle
-- INSERT INTO dim_vehicle (crash_type, bus_involved, rigid_truck_involved, articulated_truck_involved)
-- SELECT DISTINCT 
--   "Crash Type", 
--   CASE WHEN "Bus Involvement" = 'Yes' THEN TRUE ELSE FALSE END,
--   CASE WHEN "Heavy Rigid Truck Involvement" = 'Yes' THEN TRUE ELSE FALSE END,
--   CASE WHEN "Articulated Truck Involvement" = 'Yes' THEN TRUE ELSE FALSE END
-- FROM stg_crashes
-- ON CONFLICT DO NOTHING;
-- -- select * from dim_vehicle

-- --select *  from information_schema.columns where table_name = 'stg_crashes'

-- -- 5. Load dim_road
-- INSERT INTO dim_road (speed_limit, road_type, christmas_period, easter_period)
-- SELECT DISTINCT 
--   "Speed Limit" ,
--   "National Road Type",
--   CASE WHEN "Christmas Period" = 'Yes' THEN TRUE ELSE FALSE END,
--   CASE WHEN "Easter Period" = 'Yes' THEN TRUE ELSE FALSE END
-- FROM stg_crashes
-- ON CONFLICT DO NOTHING;

-- -- 6. Load dim_person
-- INSERT INTO dim_person (gender, age, age_group, road_user)
-- SELECT DISTINCT 
--   "Gender", 
--   CAST("Age" AS INTEGER), 
--   "Age Group", 
--   "Road User"
-- FROM stg_fatalities
-- ON CONFLICT DO NOTHING;
--select * from dim_person

-- -- 7. Load dim_dwelling
-- INSERT INTO dim_dwelling (lga_name, dwelling_count)
-- SELECT DISTINCT lga_name, dwelling_count
-- FROM stg_dwelling_count
-- ON CONFLICT DO NOTHING;

-- -- 8. Load dim_event_flags
-- INSERT INTO dim_event_flags (christmas_period, easter_period)
-- SELECT DISTINCT
--     CASE WHEN "Christmas Period" = 'Yes' THEN TRUE ELSE FALSE END,
--     CASE WHEN "Easter Period" = 'Yes' THEN TRUE ELSE FALSE END
-- FROM stg_crashes
-- ON CONFLICT DO NOTHING;
-- -- select * from dim_event_flags

-- select * from dim_road
-- select * from fact_crashes

-- -- 9. Load fact_crashes
-- -- Truncate table fact_crashes CASCADE
-- INSERT INTO fact_crashes (
--     crash_id,
--     date_id,
--     location_id,
--     vehicle_id,
--     road_id,
--     time_id,
--     dwelling_id,
--     event_id,
--     num_fatalities
-- )
-- SELECT
--     s."Crash ID"::BIGINT,
--     d.date_id,
--     l.location_id,
--     v.vehicle_id,
--     r.road_id,
--     t.time_id,
--     dw.dwelling_id,
--     ef.event_id,
--     s."Number Fatalities"::INT
-- FROM stg_crashes s

-- -- Joins remain unchanged...
-- LEFT JOIN dim_date d
--   ON d.month = s."Month"::INT AND d.year = s."Year"::INT
-- LEFT JOIN dim_location l
--   ON l.lga_name = s."National LGA Name 2021"
--   AND l.remoteness_area   = s."National Remoteness Areas"
--   AND l.sa4_name  = s."SA4 Name 2021"
--   AND l.state = s."State"
-- LEFT JOIN dim_vehicle v
--   ON v.crash_type = s."Crash Type"
--  AND v.bus_involved = (s."Bus Involvement" = 'Yes')
--  AND v.rigid_truck_involved = (s."Heavy Rigid Truck Involvement" = 'Yes')
--  AND v.articulated_truck_involved = (s."Articulated Truck Involvement" = 'Yes')
-- LEFT JOIN dim_road r
--   ON r.road_type = s."National Road Type"
--  AND r.christmas_period = (s."Christmas Period" = 'Yes')
--  AND r.easter_period = (s."Easter Period" = 'Yes')
--  AND r.speed_limit = s."Speed Limit"
-- LEFT JOIN dim_time t
--   ON t.time = s."Time"::TIME
--  AND t.day_of_week = s."Day of week"
--  AND t.time_of_day = s."Time of Day"
-- LEFT JOIN dim_dwelling dw
--   ON dw.lga_name = s."National LGA Name 2021"
-- LEFT JOIN dim_event_flags ef
--   ON ef.christmas_period = (s."Christmas Period" = 'Yes')
--  AND ef.easter_period = (s."Easter Period" = 'Yes')

--  -- select * from fact_crashes


-- -- 10. Load fact_fatalities
-- INSERT INTO fact_fatalities (
--     crash_id,
--     person_id,
--     date_id,
--     location_id,
--     time_id,
--     person_count
-- )
-- SELECT
--     f."Crash ID"::BIGINT,
--     p.person_id,
--     d.date_id,
--     l.location_id,
--     t.time_id,
--     1 AS person_count
-- FROM stg_fatalities f
-- LEFT JOIN dim_person p
--   ON p.gender = f."Gender"
--  AND p.age = f."Age"::INT
--  AND p.age_group = f."Age Group"
--  AND p.road_user = f."Road User"
-- LEFT JOIN dim_date d
--   ON d.month = f."Month"::INT AND d.year = f."Year"::INT
-- LEFT JOIN dim_location l
--   ON l.lga_name = f."National LGA Name 2021"
--  AND l.remoteness_area = f."National Remoteness Areas"
--  AND l.sa4_name = f."SA4 Name 2021"
--  AND l.state = f."State"
-- LEFT JOIN dim_time t
--   ON t.time = f."Time"::TIME
--  AND t.day_of_week = f."Day of week"
--  AND t.time_of_day = f."Time of day"
-- -- Ensure crash exists in fact_crashes
-- JOIN fact_crashes fc
--   ON fc.crash_id = f."Crash ID"::BIGINT;

-- ALTER TABLE fact_crashes
-- DROP COLUMN population_id;

-- -- Data issue analysis
-- select * from dim_location where location_id in (1078, 1154, 1178, 1261, 1270)
-- select * from stg_crashes where "Crash ID" =  20126026
-- select * from stg_fatalities where "Crash ID" =  20126026

-- select * from stg_crashes -- total rows = 49883
-- select * from stg_fatalities -- total rows = 55233

-- we have 2 fact tables but for star schema, we nee one only hence we are going to merge fact fatalities in fact crashes and create a couple of dimension table as well

--select * from dim_person



-- ALTER TABLE fact_crashes
-- ADD COLUMN person_id INT REFERENCES dim_fatality(fatality_id),
-- ADD COLUMN fatal_person_count INT;


--select * from fact_crashes
--select * from fact_fatalities

UPDATE fact_crashes fc
SET person_id = sub.person_id 
-- fatality_person_count = sub.person_count
FROM (
    SELECT DISTINCT ON (ff.crash_id) ff.crash_id, ff.person_id, ff.person_count
    FROM fact_fatalities ff
    ORDER BY ff.crash_id, ff.person_id
) sub
WHERE fc.crash_id = sub.crash_id;

ALTER TABLE fact_fatalities DROP CONSTRAINT IF EXISTS fact_fatalities_crash_id_fkey;
ALTER TABLE fact_fatalities DROP CONSTRAINT IF EXISTS fact_fatalities_person_id_fkey;
ALTER TABLE fact_fatalities DROP CONSTRAINT IF EXISTS fact_fatalities_date_id_fkey;
ALTER TABLE fact_fatalities DROP CONSTRAINT IF EXISTS fact_fatalities_location_id_fkey;
ALTER TABLE fact_fatalities DROP CONSTRAINT IF EXISTS fact_fatalities_time_id_fkey;

ALTER TABLE fact_crashes
ADD CONSTRAINT fk_fact_crashes_person
FOREIGN KEY (person_id)
REFERENCES dim_person(person_id);

--Business Questions and SQL Query
--To address the business questions, the following PostgreSQL queries were used:
--Which LGAs have the highest number of fatal crashes?
SELECT dl.lga_name, COUNT(fc.crash_id) AS total_crashes, SUM(fc.num_fatalities) AS total_fatalities
FROM fact_crashes fc
JOIN dim_location dl ON fc.location_id = dl.location_id
WHERE lga_name != 'Unknown'
GROUP BY dl.lga_name
ORDER BY total_fatalities DESC;

--Top 10 LGAs by fatal crash count:
SELECT dl.lga_name, COUNT(fc.crash_id) AS crash_count
FROM fact_crashes fc
JOIN dim_location dl ON fc.location_id = dl.location_id
WHERE lga_name != 'Unknown'
GROUP BY dl.lga_name
ORDER BY crash_count DESC
LIMIT 10;

--Urban vs Rural Fatalities Comparison:
SELECT dl.remoteness_area, COUNT(fc.crash_id) AS crash_count, SUM(fc.num_fatalities) AS fatalities,
SUM(fc.num_fatalities)::FLOAT/COUNT(fc.crash_id)::FLOAT AS fatalities_per_crash
FROM fact_crashes fc
JOIN  dim_location dl ON fc.location_id = dl.location_id
GROUP BY dl.remoteness_area
HAVING remoteness_area !='Unknown'
ORDER BY crash_count;

--Fatal crashes by day of the week:
SELECT dd.month, COUNT(fc.crash_id) AS crash_count, SUM(fc.num_fatalities) AS fatalities
FROM fact_crashes fc
JOIN  dim_date dd ON fc.date_id = dd.date_id
GROUP BY dd.month
ORDER BY crash_count DESC;

--Crash count by speed limit:
SELECT dr.speed_limit, COUNT(fc.crash_id) AS crash_count, SUM(fc.num_fatalities) AS fatalities
FROM fact_crashes fc
JOIN dim_road dr ON fc.road_id = dr.road_id
GROUP BY dr.speed_limit
ORDER BY crash_count DESC;

--To assess whether public holidays contribute significantly to the number of fatal crashes, and to evaluate if road safety measures during these periods are effective.
SELECT 
  ef.christmas_period AS is_christmas,
  ef.easter_period AS is_easter,
  COUNT(fc.crash_id) AS crash_count,
  SUM(fc.num_fatalities) AS total_fatalities
FROM fact_crashes fc
JOIN dim_event_flags ef ON fc.event_id = ef.event_id
GROUP BY ef.christmas_period, ef.easter_period
ORDER BY total_fatalities DESC;

--To assess which age group/gender is more prone to accidents
SELECT 
    p.gender,
    p.age_group,
    COUNT(fc.crash_id) AS crash_count
FROM fact_crashes fc
JOIN dim_person p ON fc.person_id = p.person_id
GROUP BY p.gender, p.age_group
ORDER BY p.gender, p.age_group;
