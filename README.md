# loan-portfolio-risk-analysis
End-to-end loan portfolio analysis of 2,500 loans (2013-2018) using Excel, MySQL, Python and Power BI: default risk, approval trends and a 3-page interactive dashboard.

---

## Table of Contents
1. [Problem Statement](#problem-statement)
2. [Project Workflow](#project-workflow)
4. [Tools & Skills](#tools--skills)
6. [Data Cleaning & Feature Engineering (Excel)](#data-cleaning--feature-engineering-excel)
7. [SQL Analysis](#sql-analysis)
8. [Python Analysis](#python-analysis)
9. [Power BI Dashboard](#power-bi-dashboard)
10. [Key Insights](#key-insights)
11. [Recommendations](#recommendations)
12. [Limitations](#limitations)
13. [How to Reproduce](#how-to-reproduce)
14. [Author](#author)

---

## Problem Statement

A lending company has issued personal loans and also holds yearly application data (accepted and rejected). Management needs to understand **how the loan portfolio is performing, who gets approved, and which loans are risky**, so that future lending decisions are safer.

**Business questions answered**
1. What does the portfolio look like by amount, purpose, term, state and status?
2. How much of the funded money has been repaid, and how much is still outstanding?
3. Which borrower and loan characteristics (grade, credit score, term, home ownership, income, DTI) are linked to default?
4. How have loan approval rates changed over the years, and which applicants are approved most and least?
5. Which loans need urgent attention (late or in grace period with a large balance)?

---

## Project Workflow

```
Excel (raw data + cleaning)  ->  MySQL (SQL analysis)  ->  Python (EDA + features)  ->  Power BI (dashboard)
```

| Stage | Purpose |
|---|---|
| Excel | Clean the raw data, create analysis columns, build lookup tables and quick pivot checks |
| SQL (MySQL) | Answer business questions with queries |
| Python | Data quality checks, charts, ratios, loan classification, vintage analysis, export of summary tables |
| Power BI | Data model, DAX measures and a 3-page interactive dashboard |

---

## Tools & Skills

| Area | Tools / Techniques |
|---|---|
| Excel | `IF`, nested `IF`, `IFERROR`, `VLOOKUP`, `SUMIFS`, `LEFT`, `VALUE`, pivot tables, lookup tables |
| SQL (MySQL) | `GROUP BY`, `HAVING`, `JOIN`, `CASE WHEN`, subqueries, aggregates, `ORDER BY`, `LIMIT`, `IN` |
| Python | pandas, NumPy, Matplotlib, Seaborn, SQLAlchemy, PyMySQL |
| Power BI | Power Query, data modelling, DAX, slicers, bookmarks, conditional formatting |

---

## Data Cleaning & Feature Engineering (Excel)

Columns added to build `loans_fact`:

| New column | Logic |
|---|---|
| `employment_years` | Extracts the leading number from the employment text: `<1 yr` becomes 0.5, `Unknown` is left blank, and `10+ yrs` is capped at 10 |
| `loan_status_group` | Nested `IF` mapping: Charged Off -> Defaulted, Fully Paid -> Successfully Repaid, Current -> Active, In Grace Period -> Grace Period, Late (16-30 days) -> Overdue 16-30 Days, Late (31-120 days) -> Overdue 31-120 Days, anything else -> Other |
| `loan_type_group` | `VLOOKUP` against `lk_loan_type`, with `IFERROR` fallback to "All other purposes". Groups: Debt consolidation, Credit card, Home improvement, All other purposes |
| `default_flag` | 1 for Charged Off, otherwise 0 |
| `is_closed_status` | 1 for Fully Paid and Charged Off (final outcome known) |
| Band columns | Credit score, DTI, income and loan size bands for easier reporting |
| `lk_year_approval` | Yearly `accepted_count` and `total_applications` using `SUMIFS` on `approval_by_emp_dti`, and `approval_rate_pct = accepted / total * 100` |

**Business definitions used**
- **Default** = loan status *Charged Off*.
- **Closed loans** = Fully Paid + Charged Off. Active and overdue loans are excluded from default rates in Power BI because their outcome is not final.
- **Outstanding principal** = principal still to be repaid.
- **DTI (debt-to-income)** = monthly debt payments divided by monthly income.
- **Approval rate** = accepted applications / total applications.

---

## SQL Analysis

| # | Business question | Techniques |
|---|---|---|
| 1 | Loan status distribution and % of portfolio | `GROUP BY`, subquery |
| 2 | Relationship between `default_flag` and `loan_status` (validation) | `GROUP BY` on two columns |
| 3 | Join loans to yearly approval rate | `INNER JOIN` |
| 4 | States with the highest outstanding principal (with total funded and default rate) | `GROUP BY`, `SUM`, `AVG` |
| 5 | Top 5 loan categories by default rate (minimum 20 loans) | `HAVING`, `ORDER BY`, `LIMIT` |
| 6 | Default rate by credit tier (Excellent 750+, Good 700+, Fair 625+, Poor below 625) | `CASE WHEN` |
| 7 | Interest rate, default rate and outstanding principal by grade | Multiple aggregates |
| 8 | High-balance loans (over 10,000) that are in grace period, late or charged off, for investigation | `WHERE`, `IN`, `LIMIT` |

Default rate in SQL is calculated as `ROUND(AVG(default_flag) * 100, 2)`, because the flag is 1 for default and 0 otherwise.

---

## Python Analysis

1. **Connect** to MySQL with SQLAlchemy (`mysql+pymysql`) and load `loans_fact` and `lk_year_approval` into pandas.
2. **Data quality checks:** shape, data types, duplicate loan IDs (assertion), `describe()`.
3. **Visualisation:** loan amount distribution, loans by status, default rate by grade, default rate by year.
4. **Feature engineering:**
   - `loan_to_income` = loan amount / annual income
   - `payment_burden` = monthly installment x 12 / annual income
5. **Loan classification** into Good, Active, Default and Watchlist, with a `watchlist_flag` for loans in grace period or overdue.
6. **Vintage analysis:** default rate by issue year using resolved loans only (Fully Paid and Charged Off).
7. **Export** of results back to MySQL (`loan_python_features`, `grade_summary`, `vintage_summary`) and to CSV files.

> Before running, replace the database credentials in the connection cell with your own (use environment variables, never commit real passwords).

---

## Power BI Dashboard

**Page 1: Portfolio** – *What do we lend and how is it repaid?*
- KPI cards: Loans Funded, Funded Amount, Avg Loan Amount, Outstanding Principal, Repayment %, Weighted Avg Interest Rate %
- Charts: funded amount and average loan by year, loan purpose, state, term, loan size band, loan status group, repaid vs outstanding vs loss by year

**Page 2: Approval** – *How hard is it to get a loan?*
- KPI cards: Total, Accepted and Rejected Applications, Approval Rate %, Applications per Approval, Approval Rate YoY (pp)
- Charts: state map and bar, applications vs approval rate by year, employment length x DTI matrix, approval by DTI band over time

**Page 3: Risk** – *Who defaults and why?*
- KPI cards: Defaulted Loans, Default Rate % (closed loans), Loss on Defaults, Loss Severity %, Delinquency Rate %, Avg Credit Score
- Charts: grade (interest rate vs default rate), credit score band, term, home ownership, income verification, income band, DTI band, loan purpose, closed share and default rate by year

Every page has Year and State slicers, a reset button, and a dynamic insight card that updates with the filters.

**Main DAX measures**

| Measure | Logic |
|---|---|
| Loans Funded | `DISTINCTCOUNT(loan_id)` |
| Funded Amount | `SUM(loan_amount)` |
| Outstanding Principal / Principal Repaid | `SUM` of the respective columns |
| Repayment % | Principal Repaid / Funded Amount |
| Weighted Avg Interest Rate % | `SUMX(rate x amount)` / Funded Amount |
| Default Rate % (Closed Loans) | Defaulted closed loans / closed loans |
| Loss on Defaults | Funded amount minus principal repaid, for defaulted loans |
| Loss Severity % | Loss on defaults / funded amount of defaulted loans |
| Delinquency Rate % | Outstanding balance of grace-period and overdue loans / total outstanding balance |
| Approval Rate % | Accepted / Total applications |
| Applications per Approval | Total / Accepted |
| Approval Rate YoY (pp) | Current year rate minus previous year rate (uses `VAR` and `ALL`) |
| Insight measures | `TOPN`, `FORMAT` and string concatenation for dynamic text |
| Default Rate Color | `SWITCH(TRUE())` for conditional formatting |

### Screenshots
| Portfolio | Approval | Risk |
-- <img width="719" height="407" alt="image" src="https://github.com/user-attachments/assets/765fc29d-689a-41a7-996c-4c17b366131c" />
-- <img width="715" height="401" alt="image" src="https://github.com/user-attachments/assets/4584e1c2-07a1-499b-acba-356a5e8fa727" />
-- <img width="719" height="401" alt="image" src="https://github.com/user-attachments/assets/4e3fe1d8-1c86-4fda-a26a-4973158e925d" />

---

## Key Insights

**Portfolio**
- Debt consolidation (60.24%) and credit card (24.90%) loans make up **85.14%** of funded amount.
- The top 5 states hold **42.17%** of funded amount; California alone has **13.63%**.
- 36-month loans are **60.26%** of funded amount and 60-month loans are **39.74%**.
- Defaulted loans repaid only **27.74%** of their principal ($1,244,610 of $4,486,250), a loss of **$3,241,640**.
- Defaulted loans carried a higher average rate (15.97%) than fully paid loans (12.40%).
- 73.51% of 2018 principal is still outstanding, so low repayment in recent years is expected.

**Approval**
- Applications grew **11.2x** (895,756 to 9,990,909), while accepted loans grew only **3.7x**.
- The rejected share rose from **84.95% to 95.05%**; the approval rate fell from 15.05% (2013) to 4.95% (2018).
- Applicants with a DTI of 30+ have the lowest approval rate (**2.86%**).

**Risk**
- Default rate on closed loans climbs from **6.67% (Grade A) to 81.82% (Grade G)**.
- From A to G the weighted interest rate rises about **4.0x** (7.06% to 28.31%), while the default rate rises about **12.3x**.
- Grades D to G are **22.44%** of loans but default at **37.71%** on closed loans.
- 60-month loans default at **29.94%** vs **17.21%** for 36-month loans.
- Credit scores of 625–699 default at **24.77%**, versus 5.88% (750–799) and 5.00% (800+).
- Renters default at **25.13%** vs **15.99%** for mortgage holders.
- Defaulted loans lose **72.26%** of their principal.
- Applicants with income *not verified* show the lowest default rate (14.49%), which is counter-intuitive. A likely explanation is that lenders verified the riskier applicants.

---

## Recommendations

1. Tighten lending or reprice risk on **Grades D to G** and **60-month loans**, where defaults are highest and interest rates do not rise in line with risk.
2. Favour applicants with **credit scores of 700+**, who default far less.
3. Monitor **watchlist loans** (grace period and overdue) and prioritise those with large outstanding balances, using the SQL investigation query.
4. Review concentration in a few states and in two loan purposes.
5. Review income-verification rules, given the counter-intuitive default pattern.

---

## Limitations

- **Default rate definition:** Power BI uses closed loans only (Fully Paid and Charged Off). A plain average of `default_flag` across all loans includes active loans as non-defaults and gives a lower figure, so SQL and Power BI default rates are not directly comparable.
- **Recent loans are not fully matured**, so recent issue years can look better or worse than they will eventually be.
- **Approval data is aggregated** (counts by year, state, employment length and DTI band) and is not linked at borrower level to the loan records.
- **Correlation is not causation:** patterns such as the income-verification result need further investigation.
- Day-count rules for grace period and charge-off depend on the lender's policy.

---

## How to Reproduce

1. Open `data/loan_project.xlsx` to review the cleaned `loans_fact` table and lookup sheets.
2. Load the tables into MySQL (database `loan_db`) and run `sql/Loan_project_sql_file.sql`.
3. Install the Python libraries: `pip install pandas numpy matplotlib seaborn sqlalchemy pymysql`
4. Open `notebooks/loan_project.ipynb`, set your own database connection details and run all cells.
5. Open `powerbi/loan_portfolio_dashboard.pbix` in Power BI Desktop and refresh the data sources if prompted.

---

## Author

**Nehasri M**
Data Analyst | SQL · Python · Power BI · Excel
