-- SQLite
-- UK Gender Pay Gap
-- Data from 2024-25

-- Exploratory Data Analysis of UK Government collected data on gender pay gap (reported annually)
-- First, I queried the database to extract some essential insights about the dataset.

SELECT COUNT(DISTINCT EmployerName) FROM PayGap_24;

-- We have 11,076 companies.

SELECT COUNT(DISTINCT EmployerName) FROM PayGap_24
WHERE SubmittedAfterTheDeadline = 'True';

-- 714 of which submitted their data after the required deadline.

SELECT COUNT(DISTINCT EmployerName) FROM PayGap_24
WHERE CompanyLinkToGPGInfo IS NULL;

-- 4,945 companies have not provided a corresponding website link.

-- The 'SIC codes' represent the industries of each job. They can be found here: https://resources.companieshouse.gov.uk/sic/

SELECT DISTINCT SicCodes FROM PayGap_24 GROUP BY SicCodes;

-- I will use the mean hourly percent to calculate the pay gap because it yields a result that is more reflective of the trends in the group overall.

SELECT ROUND(AVG(DiffMeanHourlyPercent), 4) as avg_across_companies FROM PayGap_24;

-- The average gender pay gap across all companies in the data set is 12.45%.

-- Some caveats to be aware of:
-- This figure represents the hourly wage difference as a mean across companies of different valuations and industries. 
-- It is not proportional to anything other than the corresponding mean hourly percent, so it can be misleading in this way.
-- It is dependent on self-reported data that is subject to human error, bias, and fudging numbers.

SELECT EmployerName, DiffMeanHourlyPercent, EmployerSize 
FROM PayGap_24 
ORDER BY DiffMeanHourlyPercent DESC 
LIMIT 10;

-- These ten companies have the pay gaps that are most skewed towards men. Over half are Football Clubs in the English Premier League 
-- that are among the most well-known brands in the world.

SELECT EmployerName, DiffMeanHourlyPercent, EmployerSize  
FROM PayGap_24 
WHERE EmployerSize = '5000 to 19,999' OR EmployerSize = '20,000 or more' 
ORDER BY DiffMeanHourlyPercent DESC  
LIMIT 10;

-- These are the most significant companies with large pay gaps.
-- These companies are engaging in unlawful pay discrimination.
-- According to the 2010 law on equal pay in the UK, men and women are to be paid equally for the same work. 
-- These numbers clearly demonstrate a reality to the contrary.

SELECT (SELECT AVG(DiffMeanHourlyPercent) 
FROM PayGap_24
    WHERE Address LIKE '%London%') as avg_London, 
    (SELECT AVG(DiffMeanHourlyPercent) FROM PayGap_24 WHERE Address NOT LIKE '%London%') as avg_outside 
FROM PayGap_24 
LIMIT 1;

-- The average pay gap - In London: 14.25%, Outside London: 11.93%

SELECT (SELECT AVG(DiffMeanHourlyPercent) FROM PayGap_24 WHERE Address LIKE '%London%') as avg_London, 
    (SELECT AVG(DiffMeanHourlyPercent) FROM PayGap_24 WHERE Address LIKE '%Birmingham%') as avg_outside 
FROM PayGap_24 
LIMIT 1;

-- Avg pay gap in London: 14.25%, In Birmingham: 10.17%

SELECT AVG(DiffMeanHourlyPercent)as avg_Schools FROM PayGap_24 WHERE EmployerName LIKE '%School%';

-- Avg pay gap within schools is 14.71%

SELECT AVG(DiffMeanHourlyPercent)as avg_banks FROM PayGap_24 WHERE EmployerName LIKE '%Bank%';

-- In banks it is 24.08%

-- There is a relationship between the number of employees at a company and the average pay gap, evidenced by a 
-- lower rate in companies with less than 250 employees.

SELECT EmployerSize, ROUND(AVG(DiffMeanHourlyPercent),2) as avg FROM PayGap_24 GROUP BY EmployerSize;

-- Here I perform a join between the SIC code table data from online and the existing dataset, then query a list of the top
-- 10 industries by discrimination rate.

SELECT Description, ROUND(AVG(DiffMeanHourlyPercent),2) as avg 
FROM PayGap_24 
    JOIN Sic_Codes on Sic_Codes.Code = PayGap_24.SicCodes
GROUP BY SicCodes
ORDER BY avg DESC
LIMIT 10;

SELECT EmployerName, SicCodes, DiffMeanHourlyPercent,
       RANK() OVER (PARTITION BY SicCodes ORDER BY DiffMeanHourlyPercent DESC) AS rank_in_industry
FROM PayGap_24;

--This ranks companies within their respective industries based on the gender pay gap.

WITH IndustryAvg AS (
    SELECT SicCodes, AVG(DiffMeanHourlyPercent) AS industry_avg
    FROM PayGap_24
    GROUP BY SicCodes
)
SELECT u.EmployerName, u.SicCodes, u.DiffMeanHourlyPercent, ia.industry_avg
FROM PayGap_24 u
JOIN IndustryAvg ia ON u.SicCodes = ia.SicCodes
WHERE u.DiffMeanHourlyPercent > ia.industry_avg;

--This identifies companies with a higher-than-average pay gap within their industry.

SELECT EmployerName, DiffMeanHourlyPercent,
       CASE 
           WHEN DiffMeanHourlyPercent >= 30 THEN 'Extreme Gap'
           WHEN DiffMeanHourlyPercent >= 15 THEN 'High Gap'
           WHEN DiffMeanHourlyPercent >= 5 THEN 'Moderate Gap'
           ELSE 'Low or No Gap'
       END AS PayGapCategory
FROM PayGap_24;

--This helps in grouping companies into pay gap risk categories.

SELECT p24.EmployerName, 
       p24.DiffMeanHourlyPercent AS PayGap_2024,
       p25.DiffMeanHourlyPercent AS PayGap_2025,
       (p25.DiffMeanHourlyPercent - p24.DiffMeanHourlyPercent) AS ChangeInPayGap
FROM PayGap_24 p24
JOIN PayGap_25 p25 ON p24.EmployerName = p25.EmployerName;

--This shows how the gender pay gap changed year over year for each company.

SELECT EmployerName, DiffMeanHourlyPercent, SubmittedAfterTheDeadline
FROM PayGap_24
WHERE DiffMeanHourlyPercent > 25 AND SubmittedAfterTheDeadline = 'True';

--This could help flag companies that might be under legal scrutiny.