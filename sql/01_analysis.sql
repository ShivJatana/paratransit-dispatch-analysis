-- =====================================================================
-- PARATRANSIT DISPATCH ANALYSIS
-- On-time = picked up no more than 15 minutes after the scheduled time.
-- Only completed trips have a pickup time, so on-time % uses completed trips.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1.1  Overall volume and on-time performance
-- ---------------------------------------------------------------------
SELECT COUNT(*)                                            AS trips_booked,
       SUM(trip_status = 'Completed')                      AS completed,
       ROUND(100.0 * SUM(trip_status = 'No-show') / COUNT(*), 1)     AS no_show_pct,
       ROUND(100.0 * SUM(trip_status = 'Late cancel') / COUNT(*), 1) AS late_cancel_pct,
       ROUND(100.0 * SUM(pickup_delay_min <= 15) / SUM(trip_status = 'Completed'), 1) AS on_time_pct,
       ROUND(AVG(pickup_delay_min), 1)                     AS avg_delay_min
FROM trips;


-- ---------------------------------------------------------------------
-- 1.2  On-time % by hour of the day
-- ---------------------------------------------------------------------
SELECT substr(scheduled_pickup, 1, 2) AS hour,
       COUNT(*)                       AS completed_trips,
       ROUND(100.0 * SUM(pickup_delay_min <= 15) / COUNT(*), 1) AS on_time_pct
FROM trips
WHERE trip_status = 'Completed'
GROUP BY hour
ORDER BY hour;


-- ---------------------------------------------------------------------
-- 1.3  Peak vs off-peak (peaks: 06:30-08:59 and 14:00-16:29)
-- ---------------------------------------------------------------------
SELECT CASE WHEN scheduled_pickup BETWEEN '06:30' AND '08:59'
              OR scheduled_pickup BETWEEN '14:00' AND '16:29'
            THEN 'Peak' ELSE 'Off-peak' END AS period,
       COUNT(*) AS completed_trips,
       ROUND(100.0 * SUM(pickup_delay_min <= 15) / COUNT(*), 1) AS on_time_pct,
       ROUND(AVG(pickup_delay_min), 1) AS avg_delay_min
FROM trips
WHERE trip_status = 'Completed'
GROUP BY period;


-- ---------------------------------------------------------------------
-- 1.4  On-time % by zone
-- ---------------------------------------------------------------------
SELECT zone,
       COUNT(*) AS completed_trips,
       ROUND(100.0 * SUM(pickup_delay_min <= 15) / COUNT(*), 1) AS on_time_pct,
       ROUND(AVG(pickup_delay_min), 1) AS avg_delay_min
FROM trips
WHERE trip_status = 'Completed'
GROUP BY zone
ORDER BY on_time_pct;


-- ---------------------------------------------------------------------
-- 2.1  Sick calls by day of week
-- ---------------------------------------------------------------------
SELECT CASE strftime('%w', shift_date) WHEN '0' THEN '0 Sun' WHEN '1' THEN '1 Mon' WHEN '2' THEN '2 Tue'
       WHEN '3' THEN '3 Wed' WHEN '4' THEN '4 Thu' WHEN '5' THEN '5 Fri' ELSE '6 Sat' END AS day,
       COUNT(*) AS shifts_scheduled,
       SUM(attendance = 'Called in sick') AS sick_calls,
       ROUND(100.0 * SUM(attendance = 'Called in sick') / COUNT(*), 1) AS sick_call_pct
FROM driver_shifts
GROUP BY day
ORDER BY day;


-- ---------------------------------------------------------------------
-- 2.2  Do short-staffed days run late? (weekdays only)
--      Days grouped by how many drivers called in sick.
-- ---------------------------------------------------------------------
WITH daily_staff AS (
    SELECT shift_date, SUM(attendance = 'Called in sick') AS sick_calls
    FROM driver_shifts
    WHERE strftime('%w', shift_date) BETWEEN '1' AND '5'
    GROUP BY shift_date
),
daily_trips AS (
    SELECT trip_date, 100.0 * SUM(pickup_delay_min <= 15) / COUNT(*) AS on_time_pct
    FROM trips WHERE trip_status = 'Completed' GROUP BY trip_date
)
SELECT CASE WHEN s.sick_calls >= 10 THEN '3: 10+ sick calls'
            WHEN s.sick_calls >= 7  THEN '2: 7-9 sick calls'
            ELSE '1: 0-6 sick calls' END AS staffing,
       COUNT(*)                     AS weekdays,
       ROUND(AVG(t.on_time_pct), 1) AS avg_on_time_pct
FROM daily_staff s
JOIN daily_trips t ON t.trip_date = s.shift_date
GROUP BY staffing
ORDER BY staffing;


-- ---------------------------------------------------------------------
-- 3.1  Vehicle incidents by type
-- ---------------------------------------------------------------------
SELECT incident_type,
       COUNT(*) AS incidents,
       ROUND(AVG(minutes_out_of_service)) AS avg_minutes_out,
       ROUND(SUM(minutes_out_of_service) / 60.0, 1) AS total_hours_out
FROM vehicle_incidents
GROUP BY incident_type
ORDER BY incidents DESC;


-- ---------------------------------------------------------------------
-- 3.2  Breakdowns by vehicle age
-- ---------------------------------------------------------------------
SELECT CASE WHEN v.model_year <= 2018 THEN '2016-2018'
            WHEN v.model_year <= 2021 THEN '2019-2021'
            ELSE '2022-2024' END AS model_years,
       COUNT(DISTINCT v.vehicle_id) AS vehicles,
       SUM(i.incident_type = 'Breakdown') AS breakdowns,
       ROUND(1.0 * SUM(i.incident_type = 'Breakdown') / COUNT(DISTINCT v.vehicle_id), 2) AS breakdowns_per_vehicle
FROM vehicles v
LEFT JOIN vehicle_incidents i ON i.vehicle_id = v.vehicle_id
GROUP BY model_years
ORDER BY model_years;


-- ---------------------------------------------------------------------
-- 3.3  Most breakdown-prone vehicles (replacement candidates)
-- ---------------------------------------------------------------------
SELECT v.vehicle_id, v.vehicle_type, v.model_year,
       COUNT(*) AS breakdowns,
       SUM(i.minutes_out_of_service) AS minutes_out
FROM vehicle_incidents i
JOIN vehicles v ON v.vehicle_id = i.vehicle_id
WHERE i.incident_type = 'Breakdown'
GROUP BY v.vehicle_id
ORDER BY breakdowns DESC, minutes_out DESC
LIMIT 5;


-- ---------------------------------------------------------------------
-- 3.4  Do breakdown days run late? (weekdays)
-- ---------------------------------------------------------------------
WITH daily_bd AS (
    SELECT t.trip_date,
           (SELECT COUNT(*) FROM vehicle_incidents i
             WHERE i.incident_date = t.trip_date AND i.incident_type = 'Breakdown') AS breakdowns,
           100.0 * SUM(t.pickup_delay_min <= 15) / COUNT(*) AS on_time_pct
    FROM trips t
    WHERE t.trip_status = 'Completed' AND strftime('%w', t.trip_date) BETWEEN '1' AND '5'
    GROUP BY t.trip_date
)
SELECT CASE WHEN breakdowns >= 2 THEN '2+ breakdowns' ELSE '0-1 breakdowns' END AS breakdown_level,
       COUNT(*) AS weekdays,
       ROUND(AVG(on_time_pct), 1) AS avg_on_time_pct
FROM daily_bd
GROUP BY breakdown_level;


-- ---------------------------------------------------------------------
-- 3.5  Wheelchair vs ambulatory trips
-- ---------------------------------------------------------------------
SELECT trip_type,
       COUNT(*) AS completed_trips,
       ROUND(100.0 * SUM(pickup_delay_min <= 15) / COUNT(*), 1) AS on_time_pct
FROM trips
WHERE trip_status = 'Completed'
GROUP BY trip_type;
