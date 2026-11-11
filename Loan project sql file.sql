create database loan_db;
use loan_db;

-- To analyze the distribution of loan statuses and calculate the percentage of loans in each status.
select loan_status,count(*) as loan_count,round(count(*) * 100.0 /(select count(*) from loans_fact),2) as percentage_of_portfolio
from loans_fact
group by loan_status
order by loan_count desc;


-- To determine how the existing default_flag relates to the loan status.
select loan_status,default_flag,count(*) as loan_count from loans_fact
group by loan_status, default_flag
order by loan_status,default_flag;


-- To connect loan records with historical approval rates.
select l.loan_id,l.issue_year,l.loan_type_group,l.loan_amount, y.approval_rate_pct from loans_fact as l
inner join lk_year_approval as y
on l.issue_year = y.year;


-- To identify states with the highest outstanding principal
select state,count(*) as total_loans,sum(loan_amount) as total_funded,sum(outstanding_principal) as outstanding_principal,
round(avg(default_flag) * 100, 2) as default_rate_pct from loans_fact
group by state
order by outstanding_principal desc;


-- To identify loan categories with higher observed default rates.
select loan_type_group,count(loan_id) as total_loans,sum(default_flag) as defaulted_loans,round(avg(default_flag) * 100, 2) as default_rate_pct
from loans_fact
group by loan_type_group
having count(loan_id) >= 20
order by default_rate_pct desc
limit 5;


-- To compare default rates across credit score categories
select
case
        when credit_score >= 750 then 'Excellent'
        when credit_score >= 700 then 'Good'
        when credit_score >= 625  then 'Fair'
        else 'Poor'
end as credit_tier,count(*) as total_loans,round(avg (default_flag) * 100, 2) as default_rate_pct
from loans_fact
group by credit_tier
order by default_rate_pct desc;


-- To compare interest rates, defaults, and outstanding principal across grades.
select grade,count(*) as total_loans,round(avg(interest_rate_pct), 2) as avg_interest_rate,
round(avg(default_flag) * 100, 2) as default_rate_pct,sum(outstanding_principal) as outstanding_principal
from loans_fact
group by grade
order by grade;


--  To identify high-outstanding-balance loans requiring further investigation
select loan_id,state,loan_type_group,loan_status,outstanding_principal,default_flag
from loans_fact
where outstanding_principal > 10000 and loan_status in ('Late (16-30 days)','Late (31-120 days)','In Grace Period','Charged Off')
order by outstanding_principal desc
limit 100;