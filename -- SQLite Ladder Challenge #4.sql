-- SQLite Ladder Challenge #4

--78) 
SELECT date, 
SUM(volume) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as tot_volume
FROM yum
ORDER BY date;

--79) 
SELECT   
    STRFTIME('%m', date) as month, 
    SUM(volume) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as tot_volume
FROM yum
GROUP BY month
ORDER BY month ASC;

--80) 
SELECT
STRFTIME('%d', date) as day,
    ROW_NUMBER() OVER (
        PARTITION BY STRFTIME('%Y-%m', date)
        ORDER BY date
    ) as row_num,
    MIN(low) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cumltv_low,
    MAX(high) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cumltv_high,
    SUM(volume) OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cumltv_vol
FROM yum
WHERE STRFTIME('%Y-%m', date) = '2017-03';

--81)
SELECT 
    AVG(close) OVER (
        ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING
    ) CloseMovingAvg
FROM yum;

--82)
SELECT
STRFTIME('%d', date) as day,
    ROW_NUMBER() OVER (
        PARTITION BY STRFTIME('%Y-%m', date)
        ORDER BY date) as row_num,
    MIN(low) OVER (ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) moving_low,
    MAX(high)  OVER ( ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) as moving_high,
    SUM(volume) OVER (ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) as moving_vol
FROM yum
WHERE STRFTIME('%Y-%m', date) = '2017-03';

--83)
WITH yum_WR_CTE(l7, h7, date, close)
AS
(SELECT
    MIN(low) OVER (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),
    MAX(high) OVER ( ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), date, close
    FROM yum
    )
SELECT date, (h7-close)/(h7-l7) as Williams_R
FROM yum_WR_CTE;

--84)
WITH yum_SO_CTE(l14, h14, date, close)
AS
(SELECT
    MIN(low) OVER (ROWS BETWEEN 13 PRECEDING AND CURRENT ROW),
    MAX(high) OVER (ROWS BETWEEN 13 PRECEDING AND CURRENT ROW), date, close
    FROM yum
    )
SELECT date,
    (close-l14)/(h14-l14)as pct_k,
    AVG((close-l14)/(h14-l14)) OVER (ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) as pct_d
FROM yum_SO_CTE;


/*
85) In my opinion, this is the hardest problem in the ladder challenge. For each month 
--between 2015 and 2019, as in the final problem from the `03` file, we'll attach Yum! 
--stock data to the `transactions` data. Let's condense our `yum` data to show relevant monthly 
--statistics. That is, for each month of each year, create a table with the following columns:
* Year
* Month
* The total revenue from our company in `transactions`
* The monthly low (ie, the lowest low that month)
* The monthly high (ie, the highest high that month)
* The monthly open (ie, the opening value in the first trading day that month)
* The monthly close (ie, the closing value of the last trading day that month)
* The total trade volume of Yum! that month

My solution to this problem is 38 lines long. For reference, here are the top 3 rows of the solution:
```
year        month       company_revenue  yum_low     yum_high    yum_open    yum_close   yum_volume
----------  ----------  ---------------  ----------  ----------  ----------  ----------  ----------
2015        01          $14,106          49.88       53.87       53.12       53.28       89,074,400
2015        02          $20,739          50.68       59.29       56.95       58.31       98,621,800
2015        03          $21,232          54.92       59.55       58.23       58.81       108,827,60
``
Some hints:
* I used two CTEs, but you may not need to. 
* You'll need the `FIRST_VALUE()` and `LAST_VALUE()` window functions.
* To find the first in each month, you'll need the `PARTITION BY` statement in those window functions. 
--`PARTITION BY` acts a lot like `GROUP BY`, but for window functions.
*/
WITH yum_monthly_CTE(year, month, month_low, month_high, month_open, month_close, tot_volume)
AS
(
SELECT
    STRFTIME('%Y', date),
    STRFTIME('%m', date),
    MIN(low) OVER (PARTITION BY STRFTIME('%m', date) ORDER BY date),
    MAX(high) OVER (PARTITION BY STRFTIME('%m', date)ORDER BY date),
    FIRST_VALUE(open) OVER (PARTITION BY STRFTIME('%m', date)ORDER BY date),
    LAST_VALUE(close) OVER (PARTITION BY STRFTIME('%m', date)ORDER BY date),
    SUM(volume)OVER (PARTITION BY STRFTIME('%m', date)ORDER BY date)
FROM yum
)
SELECT yum_monthly_CTE.year as year,
 yum_monthly_CTE.month as month, total_cost as company_revenue,
    --STRFTIME('%Y', date) as year,
  --  STRFTIME('%m', date) as month,
   -- (SELECT total_cost FROM trans_by_month ) as company_revenue,
    month_low, month_high, month_open, month_close, tot_volume
FROM yum_monthly_CTE
  --  JOIN trans_by_month on trans_by_month.year = yum_monthly_CTE.year
    JOIN trans_by_month on trans_by_month.year = yum_monthly_CTE.year
        AND trans_by_month.month = yum_monthly_CTE.month
GROUP by yum_monthly_CTE.year, yum_monthly_CTE.month
ORDER BY yum_monthly_CTE.year, yum_monthly_CTE.month;