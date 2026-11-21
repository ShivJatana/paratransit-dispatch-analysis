# Findings & recommendations

*Synthetic data, 4 weeks, 152 drivers, 60 vehicles, 16,228 booked trips. Queries: [`sql/01_analysis.sql`](sql/01_analysis.sql).*

## Summary
Pickups were on time 83.5% of the time. Most lateness comes from three things dispatch can plan for: **peak periods**, **Monday sick calls** and **older vans breaking down**. Rural North Durham trips need their own scheduling approach.

## 1. Peaks cause most lateness
**Evidence:** On-time is 76–78% from 06:30 to 09:00 and from 14:00 to 16:30, versus 90–93% the rest of the day. (Queries 1.2, 1.3)
**Recommendation:** Pad peak trip times by 5–10 minutes in scheduling, and stagger driver start times so more vehicles are on the road at 06:30 and 14:00.

## 2. Monday sick calls are the biggest single risk
**Evidence:** 10.7% of Monday shifts end in a sick call, more than double the 4–5% on other weekdays. Monday on-time is 64.3%, versus 87.0% Tuesday to Friday. Days with 10+ sick calls average 66.4% on time. (Queries 2.1, 2.2)
**Recommendation:** Roster 4–6 standby drivers on Mondays, track attendance patterns by driver, and confirm Monday shifts on Sunday evening.

## 3. Older vans break down 3 times as often
**Evidence:** 2016–2018 vehicles averaged 1.14 breakdowns each over 4 weeks, versus 0.38 for 2022–2024. Breakdowns averaged about 4 hours out of service each, 158 hours in total, and weekdays with 2+ breakdowns averaged 79.6% on time, versus 85.8%. (Queries 3.1–3.4)
**Recommendation:** Move the oldest accessible vans (for example V34, V02, V28) to a shorter preventive-maintenance interval, prioritize them for replacement, and keep one spare accessible van staged during peaks.

## 4. Rural trips need different scheduling
**Evidence:** North Durham trips are on time 65.7% of the time, with an average delay of 14.3 minutes, versus 8.6–8.8 minutes in Ajax, Pickering, Whitby and Oshawa. (Query 1.4)
**Recommendation:** Use wider pickup windows for rural bookings and group North Durham trips onto dedicated runs instead of mixing them into urban runs.

## 5. Wheelchair trips run slightly later
**Evidence:** 81.3% on time for wheelchair trips versus 84.8% for ambulatory ones. Wheelchair trips also depend on the accessible vans, which are the oldest part of the fleet. (Query 3.5)
**Recommendation:** Add a few minutes of boarding time to wheelchair bookings in scheduling.
