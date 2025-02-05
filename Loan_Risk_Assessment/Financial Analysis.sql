--SQL Fake Lab Option 2: Financial Analysis

--1.
SELECT COUNT(loan_id), reason
FROM customerdata
JOIN loanreason on loanreason.reasoncode = customerdata.reason_code
GROUP BY reason 
ORDER BY COUNT(loan_id) DESC;

--2.
SELECT  reason, AVG(loan_amnt) as avg_loan_amnt
FROM customerdata
    JOIN loanreason on loanreason.reasoncode = customerdata.reason_code
       JOIN loandata on CAST(loandata.loan_id AS int)= customerdata.loan_id
GROUP BY reason
ORDER BY avg_loan_amnt DESC;

--3.
SELECT  grade, AVG(loan_amnt) as avg_loan_amnt, AVG(int_rate) as avg_int_rate
FROM customerdata
    JOIN loanreason on loanreason.reasoncode = customerdata.reason_code
       JOIN loandata on CAST(loandata.loan_id AS int)= customerdata.loan_id
GROUP BY grade
ORDER BY grade ASC;
--  a. A riskier loan should certainly mean a higher interest rate. This is a consistent trend
--     with the exceptioon of grade A, which is an outlier. The correlation
--     here makes sense, however, the amount of the loan is far from the only factor
--     in grading the loans. We need more data to know if this is reflective of responsible 
--     loan grading or of simply assigning high interest rates to higher amount without
--     looking at factors such as credit history and collateral. 

--4.
SELECT  addr_state, SUM(loan_amnt) as tot_loan_amnt, COUNT(DISTINCT customerdata.loan_id)as tot_num_loans
FROM customerdata
    JOIN loandata on CAST(loandata.loan_id AS int)= customerdata.loan_id
GROUP BY addr_state
ORDER BY tot_loan_amnt DESC;
--a. by number of loans: CA
--b. by amount: CA

--5.
SELECT  home_ownership, AVG(loan_amnt) as avg_loan_amnt
FROM customerdata
    JOIN loandata on CAST(loandata.loan_id AS int)= customerdata.loan_id
WHERE home_ownership='OWN' OR home_ownership='RENT'
GROUP BY home_ownership;
--RENT   12982.67
--OWN    13987.32

-- 6.
SELECT COUNT(loan_id), loan_status
FROM loandata
JOIN loanstatus ON loanstatus.loan_status_code = loandata.loan_status_code
WHERE loanstatus.loan_status_code = 'D' OR loanstatus.loan_status_code = 'L'
GROUP BY loan_status;
--"D"	"Late (31-120 days)". 103
--"L"	"Late (16-30 days)". 126

-- 7.
SELECT COUNT(loandata.loan_id), grade,
FROM customerdata
    JOIN loandata on CAST(loandata.loan_id AS int)= customerdata.loan_id
    JOIN loanstatus ON loanstatus.loan_status_code = loandata.loan_status_code
WHERE loanstatus.loan_status_code = 'D' OR loanstatus.loan_status_code = 'L'
GROUP BY grade
ORDER BY grade ASC;

-- a. The results do not match my expetations. I would expect that risker loans would lead to
-- more delinquencies, but the results tend more towards the opposite. It seems that
-- the most ddelinquencies are on less risky 'C' grade loans, while the most risky 'G' grade
-- loans are tied with the safest "A" loans for the least.

-- Based on your analysis, what patterns can you detect around loan amount, risk, and delinquency and the customers who
-- receive these loans?
--
-- It seems that much of the grading is primarily based on loan amount, which perhaps is
-- indeed the main indicator of risk. The fact that there are high numbers of middle grade loan
-- delinquencies does not neccesarilly mean anything, as those are also the most commonly
-- given loans. The customers are primarily from California, and most of their loans are taken 
-- out for home-buying and rentals.
-- 
