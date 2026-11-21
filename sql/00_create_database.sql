-- =====================================================================
-- STEP 0: CREATE THE DATABASE (run once)
-- 1. DB Browser for SQLite -> New Database -> save as paratransit.db
-- 2. Execute SQL tab -> paste this file -> Run -> Write Changes
-- 3. File -> Import -> Table from CSV file -> select all 5 files in data/
--    (tick "Column names in first line"; import into the existing tables)
-- 4. Write Changes (Ctrl+S)
-- =====================================================================

CREATE TABLE drivers (
    driver_id   TEXT PRIMARY KEY,
    shift_type  TEXT,      -- AM, PM or Split
    hire_date   TEXT
);

CREATE TABLE vehicles (
    vehicle_id    TEXT PRIMARY KEY,
    vehicle_type  TEXT,    -- Accessible minivan or Sedan
    model_year    INTEGER
);

CREATE TABLE driver_shifts (
    shift_date  TEXT,
    driver_id   TEXT REFERENCES drivers(driver_id),
    shift_type  TEXT,
    attendance  TEXT       -- Worked or Called in sick
);

CREATE TABLE vehicle_incidents (
    incident_id             TEXT PRIMARY KEY,
    incident_date           TEXT,
    vehicle_id              TEXT REFERENCES vehicles(vehicle_id),
    incident_type           TEXT,    -- Breakdown, Switch-out (defect/cleaning), Minor collision
    reported_time           TEXT,
    minutes_out_of_service  INTEGER
);

CREATE TABLE trips (
    trip_id           TEXT PRIMARY KEY,
    trip_date         TEXT,
    scheduled_pickup  TEXT,          -- HH:MM
    actual_pickup     TEXT,          -- blank if not completed
    zone              TEXT,
    trip_type         TEXT,          -- Ambulatory or Wheelchair
    trip_status       TEXT,          -- Completed, No-show, Late cancel
    driver_id         TEXT REFERENCES drivers(driver_id),
    vehicle_id        TEXT REFERENCES vehicles(vehicle_id),
    pickup_delay_min  INTEGER        -- actual minus scheduled; negative = early
);
