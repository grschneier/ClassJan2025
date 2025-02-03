-- UK Gender Pay Gap
-- Data from 2024-25

-- Exploratory Data Analysis of UK Government collected. data on gender pay gap (reported annually)
-- First, I queried the database to extract some essential insights about the dataset.

SELECT COUNT(DISTINCT EmployerName) FROM UK_pay_gap;

-- We have 11,076 companies.

SELECT COUNT(DISTINCT EmployerName) FROM UK_pay_gap
WHERE SubmittedAfterTheDeadline = 'True';

-- 714 of which submitted their data after the required deadline.

SELECT COUNT(DISTINCT EmployerName) FROM UK_pay_gap
WHERE CompanyLinkToGPGInfo IS NULL;

-- 4,945 companies have not provided a corresponding website link.

-- The 'SIC codes' represent the industries of each job. They can be found here: https://resources.companieshouse.gov.uk/sic/

SELECT DISTINCT SicCodes FROM UK_pay_gap GROUP BY SicCodes;

-- I will use the mean hourly percent to calculate the pay gap because it yields a result that is more reflective of the trends in the group overall.

SELECT ROUND(AVG(DiffMeanHourlyPercent), 4) as avg_across_companies FROM UK_pay_gap;

-- The average gender pay gap across all companies in the data set is 12.45%. 

-- Some caveats to be aware of:
-- This figure represent the hourly wage difference as a mean across companies of different valuations and industries. 
-- It is not proportional to anything other than the corresponding mean hourly percent, so it acn be misleading in this way.
-- It is dependent on self-reported data that is subject to human error, bias and fudging numbers.


SELECT EmployerName, DiffMeanHourlyPercent, EmployerSize 
FROM UK_pay_gap 
ORDER BY DiffMeanHourlyPercent DESC 
LIMIT 10;

/*
FOX RECRUITMENT LINCS LTD
AIR PRODUCTS PUBLIC LIMITED COMPANY
AFC BOURNEMOUTH LIMITED
JOINERY AND TIMBER CREATIONS (65) LIMITED
CHELSEA FOOTBALL CLUB LIMITED
WEST HAM UNITED FOOTBALL CLUB LIMITED
STOCKS HALL CARE HOMES LIMITED
BRENTFORD FC LIMITED
LEEDS UNITED FOOTBALL CLUB LIMITED
NOTTINGHAM FOREST FOOTBALL CLUB LIMITED
*/

-- These ten companies have the pay gaps that are most skewed towards mean. Over half are Football Clubs in the English Premier League 
-- that are some of the among the most well-known brands in the world.

SELECT EmployerName, DiffMeanHourlyPercent, EmployerSize  
FROM UK_pay_gap 
WHERE EmployerSize = '5000 to 19,999' OR EmployerSize = '20,000 or more' 
ORDER BY DiffMeanHourlyPercent DESC  
LIMIT 10;
/*
BRITISH AIRWAYS PLC,     			         57,    "20,000 or more"
VIRGIN ATLANTIC LIMITED,    			     56.1,  "5000 to 19,999"
EASYJET AIRLINE COMPANY LIMITED,			 53.9,  "5000 to 19,999"
ARTHUR J. GALLAGHER SERVICES (UK) LIMITED,   52.7,  "5000 to 19,999"
JET2.COM LIMITED,						     47.16, "5000 to 19,999"
PETRIE TUCKER AND PARTNERS LIMITED,	         46.51, "5000 to 19,999"
LINNAEUS GROUP LIMITED,					     45.4,  "5000 to 19,999"
HOWDEN GROUP HOLDINGS LIMITED,				 45.1,  "5000 to 19,999"
JSA SERVICES LIMITED,					     44,    "5000 to 19,999"
BARCLAYS BANK PLC,							 42.2,  "5000 to 19,999"
*/

-- These are the most significant companies with large pay gaps.
-- These companies are engaging in unlawful pay discrimination.
-- According to the 2010 law on equal pay in the UK, men and women are to be paid equally for the same work. 
-- These numbers clearly demonstrate a reality to the contrary.


SELECT (SELECT AVG(DiffMeanHourlyPercent) 
FROM UK_pay_gap
    WHERE Address LIKE '%London%') as avg_London, 
    (SELECT AVG(DiffMeanHourlyPercent) FROM UK_pay_gap WHERE Address NOT LIKE '%London%') as avg_outside 
FROM UK_pay_gap 
LIMIT 1;

-- The average pay gap - In London: 14.25%, Outside London: 11.93%

SELECT (SELECT AVG(DiffMeanHourlyPercent) FROM UK_pay_gap WHERE Address LIKE '%London%') as avg_London, 
    (SELECT AVG(DiffMeanHourlyPercent) FROM UK_pay_gap WHERE Address LIKE '%Birmingham%') as avg_outside 
FROM UK_pay_gap 
LIMIT 1;

-- Avg pay gap in London: 14.25%, In Birmingham: 10.17%

SELECT AVG(DiffMeanHourlyPercent)as avg_Schools FROM UK_pay_gap WHERE EmployerName LIKE '%School%';

-- Avg pay gap within schools is 14.71%

SELECT AVG(DiffMeanHourlyPercent)as avg_banks FROM UK_pay_gap WHERE EmployerName LIKE '%Bank%';

-- In banks it is 24.08%


-- There is a relationship between the number of employees at a company and the average pay gap, evinced by a 
-- lower rate in companies with less than 250 employees.

SELECT EmployerSize, ROUND(AVG(DiffMeanHourlyPercent),2) as avg FROM UK_pay_gap GROUP BY EmployerSize;
/*
20,000 or more, 11.54%
5000 to 19,999, 13.06%
1000 to 4999,   11.69%
250 to 499,     12.48%
500 to 999,     13.24%
Less than 250,  10.66%
Not Provided,    2.35%
*/

-- Here I perform a join between the SIC code table data from online and the existing dataset, then query a list of the top
-- 10 industries by discriminatin rate.

SELECT Description, ROUND(AVG(DiffMeanHourlyPercent),2) as avg 
FROM UK_pay_gap 
	JOIN Sic_Codes on Sic_Codes.Code = UK_pay_gap.SicCodes
GROUP BY SicCodes
ORDER BY avg DESC
LIMIT 10;

/*
Activities of sport clubs,					61.64%
Manufacture of industrial gases,			50.15%
Scaffold erection,							50.11%
Retail sale of hearing aids,				44.0%
Non-scheduled passenger air transport,		42.05%
Mining of chemical and fertilizer minerals,	40.95%
Risk and damage evaluation,					37.08%
Manufacture of women's underwear,			36.1%
Manufacture of sports goods,				34.0%
Non-life reinsurance,						33.9%
*/