-- Create schema
USE pmg_assessment;

-- Preliminary Work
-- Check the data_type of the columns in `marketing_data`
-- SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
-- WHERE table_name = 'marketing_data';


 
 -- Alter the types of columns in the `marketing_data` table to the right ones
ALTER TABLE marketing_data
MODIFY `date` DATETIME;
  
ALTER TABLE marketing_data
MODIFY geo  VARCHAR(2);
  
ALTER TABLE marketing_data
MODIFY impressions  FLOAT;
  
ALTER TABLE marketing_data
MODIFY clicks  FLOAT;

-- Check the data_type of the columns in `store_revenue`
-- SELECT DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS 
-- WHERE table_name = 'store_revenue';
 
 -- Alter the types of columns in the `store_revenue` table to the right ones
ALTER TABLE store_revenue
MODIFY `date` DATETIME;
  
ALTER TABLE store_revenue
MODIFY brand_id  INT;
  
ALTER TABLE store_revenue
MODIFY store_location  VARCHAR(250);
  
ALTER TABLE store_revenue
MODIFY revenue  FLOAT;

-- Answers:

-- Question #1:  Generate a query to get the sum of the clicks of the marketing data​
SELECT SUM(clicks) AS sum_clicks
FROM marketing_data;

-- Question #2: Generate a query to gather the sum of revenue by store_location from the `store_revenue` table​
SELECT store_location, 
			   SUM(revenue) AS sum_revenue
FROM store_revenue
GROUP BY store_location;

-- Question #3: Merge these two datasets so we can see impressions, clicks, and revenue together by date and geo. Please ensure all records from each table are accounted for.​
-- Explanation: since there's no "full outer join" in mysql, I used union the results of left join and right join, which will automatically eliminate the duplicaets
SELECT market.`date`, 
			   market.geo, 
               market.impressions, 
               market.clicks, 
               SUM(store.revenue) AS total_store_revenue
FROM marketing_data market
LEFT JOIN store_revenue store 
ON market.date = store.date AND market.geo = RIGHT(store.store_location, 2)
GROUP BY market.`date`, market.geo, market.impressions, market.clicks

UNION

SELECT store.`date`, 
			   RIGHT(store.store_location, 2), 
               market.impressions, 
               market.clicks, 
               SUM(store.revenue) AS total_store_revenue
FROM marketing_data market
RIGHT JOIN store_revenue store 
ON market.date = store.date AND market.geo = RIGHT(store.store_location, 2)
GROUP BY store.`date`, RIGHT(store.store_location, 2), impressions, clicks;


-- Question #4: In your opinion, what is the most efficient store and why?​
-- Answer: the store in CA is the most efficient store.
-- Explanation: I use two metrics to measure the efficiency of the stores: average CTR (Click-through-rate) and average RPI (Revenue per impression).
-- Average CTR, which is calculated by dividing total clicks by total impressions, illustrates the efficiency of the campaign for each store during all time recorded.
-- Average RPI, which is calculated by dividing total revenue by total impressions actually shown, illustrate the store's efficiency in generating revenue given the scheduled impressions.
-- Since we cannot obtain the RPI of the store in MN, and there seemed to be an error in the marketing data for MN on 2016-01-01 where it had >50% CTR,
-- The store in CA has the relative best performance in both dimensions.

WITH performance AS
(
SELECT market.`date`, 
			   market.geo, 
               market.impressions, 
               market.clicks, 
               SUM(store.revenue) AS total_store_revenue
FROM marketing_data market
LEFT JOIN store_revenue store 
ON market.date = store.date AND market.geo = RIGHT(store.store_location, 2)
GROUP BY `date`, geo, impressions, clicks

UNION

SELECT store.`date`, 
			   RIGHT(store.store_location, 2), 
               market.impressions, 
               market.clicks, 
               SUM(store.revenue) AS total_store_revenue
FROM marketing_data market
RIGHT JOIN store_revenue store 
ON market.date = store.date AND market.geo = RIGHT(store.store_location, 2)
GROUP BY store.`date`, RIGHT(store.store_location, 2), impressions, clicks
)


SELECT geo,
			   SUM(clicks) / SUM(impressions) AS CTR,
               SUM(total_store_revenue) / SUM(impressions) AS RPI
FROM performance
GROUP BY geo
ORDER BY SUM(clicks) / SUM(impressions) DESC, 
					SUM(total_store_revenue) / SUM(impressions) DESC;

-- Question #5: (Challenge) Generate a query to rank in order the top 10 revenue producing states​
-- Explanation: I used the window function `DENSE_RANK() OVER()` to consider the case when there're ties in the top10 revenue states.
-- For example, state A and state B have exactly the same amount of revenue who all ranked 10th among all states.
WITH revenue_ranked AS(
SELECT state,
			   total_revenue,
			   DENSE_RANK() OVER(ORDER BY total_revenue DESC) AS ranking
FROM
(SELECT RIGHT(store_location, 2) AS state, 
			   SUM(revenue) AS total_revenue
FROM store_revenue
GROUP BY  RIGHT(store_location, 2)) temp)

SELECT state, total_revenue, ranking
FROM revenue_ranked
WHERE ranking <= 10;




