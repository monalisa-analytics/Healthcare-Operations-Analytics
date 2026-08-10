# 🏥 Healthcare Operations Analytics

SQL-based analysis of 15 months of hospital patient encounter data, uncovering operational inefficiencies in patient flow and translating them into data-backed staffing recommendations.

**Tools:** Snowflake · SQL (CTEs, window-style aggregates, multi-table joins)
**Dataset:** 9,216 patient encounters · April 2023 – October 2024

---

## Business Problem

A medium-sized hospital network was seeing rising patient volumes and inconsistent patient flow, but had no systematic analysis of *why*. This project analyzes patient encounter data to answer:

> **How can the hospital leverage patient flow data to identify operational inefficiencies, improve patient experience, and optimize resource allocation across departments?**

## Dataset

| Category | Fields |
|---|---|
| Patient demographics | Age, Gender, Race |
| Visit details | Admission Date & Time, Visit Type (Emergency / Walk-in / Scheduled) |
| Operational metrics | Department Referral, Wait Time |
| Outcome variable | Admission Flag |
| Experience metric | Patient Satisfaction Score |
| Relational data | Doctor ID → linked to Doctor table (department, shift) |

## Methodology

All analysis was written in SQL in Snowflake, structured around 12 business questions:

1. Data cleaning — date type conversion, null handling, gender field correction
2. Exploratory analysis — volume trends, visit type mix, wait times, peak hours, satisfaction, admission rates
3. A follow-up **department × shift capacity analysis**, joining doctor headcount against patient volume to compute a patients-per-doctor ratio — testing whether high patient load was actually driving worse patient outcomes

## Key Insights

- **59.3% of patients wait longer than 30 minutes** — a hospital-wide service efficiency issue, not isolated to one department.
- **Volume is up in raw terms but flat once normalized** — 4,338 encounters (Apr–Dec 2023) vs. 4,878 (Jan–Oct 2024) covers unequal period lengths; per-month rate is nearly identical (~482 vs ~488/month).
- **Neurology is the hospital's weak point on every patient-facing metric** — worst average wait time (36.8 min), lowest satisfaction score (3.54/5), and repeatedly appears among the worst department-hour bottlenecks (1am, 11pm, and midday).
- **General Practice carries the heaviest doctor workload in the hospital (400+ patients per doctor)** — roughly 8x the best-staffed department-shift combination — yet its wait times and satisfaction remain among the *best* in the hospital, suggesting GP visits are short enough that volume doesn't bottleneck care the way it does elsewhere.
- **Wait time does not predict admission likelihood** — admission rate is nearly flat across wait-time buckets (51.9% → 49.4%), a weak, practically negligible relationship.

## Business Recommendations

1. **Prioritize Neurology for additional physician coverage** — it's the only department combining a real staffing gap (a single doctor covering its Morning shift) with the worst outcomes on both wait time and satisfaction.
2. **Treat General Practice's staffing ratio as a resilience risk, not an urgent fix** — outcomes are currently strong, but there's no coverage redundancy if a doctor is out.
3. **Fix specific department-hour bottlenecks with targeted scheduling**, rather than a hospital-wide staffing increase.
4. **Investigate the Night shift as a workflow issue**, not a pure headcount shortage — it has the highest volume and wait time despite most departments being adequately staffed at night per doctor.
5. **Don't use wait time as a proxy for clinical urgency** in resourcing decisions, since it has no meaningful relationship with admission outcomes.

## Repository Contents

| File | Description |
|---|---|
| `Healthcare.sql` | Full SQL script — data cleaning + all 12 business questions |
| `Healthcare Project Report.pdf` | Full business report with findings, interpretations, and recommendations |

## Author

**Monalisa Mahanta**
Data Analyst · Power BI Developer · [PL-300 Certified]
