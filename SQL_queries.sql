USE analystdb;


describe analystdb;


DESCRIBE orders_data;

SELECT * FROM orders_data;



SELECT COUNT(DISTINCT city) FROM orders_data;


-- CAST(price AS DECIMAL(10,2));

-- To calculate the total selling price and profits for all orders
SELECT "Order Id", SUM(Quantity * Unit_Selling_Price) AS 'Total Selling Price',
CAST(SUM(Quantity * Unit_Profit) AS DECIMAL(10, 2)) AS 'Total Profit'
FROM orders_data
GROUP BY `Order Id`
ORDER BY `Total Profit` DESC;


-- Write a query to find all orders from the 'Technology' category that were shipped using 'Second Class' ship mode, ordered by order date.
SELECT `Order Id`, `Order Date` FROM orders_data
WHERE category = 'Technology' and `Ship Mode` = 'Second Class'
ORDER BY `order date`;


-- the average order value
SELECT CAST(AVG(Quantity * Unit_Selling_Price) AS DECIMAL(10, 2)) AS "Average-Order-Value"
FROM orders_data;



-- the city with the highest total quantity of products ordered.
SELECT city, SUM(Quantity) as 'Total Quantity'
FROM orders_data
GROUP BY city
ORDER BY `Total Quantity` DESC;


-- Use a window function to rank orders in each region by quantity in descending order.
SELECT `Order Id`, Region, Quantity AS 'Total_Quantity',
DENSE_RANK() OVER (Partition BY Region ORDER BY Quantity DESC) AS Ranking
FROM orders_data 
ORDER BY region, Ranking;


-- Write a SQL query to list all orders placed in the first quarter of any year (January to March), 
-- including the total cost for these orders.

SELECT `Order Id`, `Order Date`, MONTH(`Order Date`) AS month, 
SUM(Quantity * unit_selling_price) AS 'Total Value'
FROM orders_data
WHERE MONTH(`Order Date`) IN (1, 2, 3)
GROUP BY `Order Id`
ORDER BY `Total Value` DESC;

-- top 10 highest profit generating products
SELECT `Product Id`, SUM(`Total Profit`) AS Profit
FROM orders_data
GROUP BY `Product Id`
ORDER BY Profit DESC
LIMIT 10;

-- the window function approach
WITH cte AS (
    SELECT `Product Id`, SUM(`Total Profit`) AS profit, 
    DENSE_RANK() OVER (ORDER BY SUM(`Total Profit`) DESC) AS rn
    FROM orders_data
    GROUP BY `Product Id`
)
SELECT 
    `Product Id`, 
    profit
FROM cte 
WHERE rn <= 10;


-- Top 3 highest selling products in each region
-- Method 1 (using CTE with ROW_NUMBER)
WITH cte AS (
    SELECT 
        region, 
        `Product Id`, 
        SUM(quantity * Unit_selling_price) AS sales,
        ROW_NUMBER() OVER(PARTITION BY region ORDER BY SUM(quantity * Unit_selling_price) DESC) AS rn
    FROM orders_data
    GROUP BY region, `Product Id`
) 
SELECT * 
FROM cte
WHERE rn <= 3;

-- Method 2 (using subquery)
WITH cte AS (
    SELECT 
        region, 
        `Product Id`, 
        SUM(quantity * Unit_selling_price) AS sales
    FROM orders_data
    GROUP BY region, `Product Id`
) 
SELECT * FROM (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales DESC) AS rn
    FROM cte
) A
WHERE rn <= 3;


-- Month-over-month growth comparison (2022 vs 2023)
WITH cte AS (
    SELECT 
        YEAR(`Order Date`) AS order_year,
        MONTH(`Order Date`) AS order_month,
        SUM(quantity * Unit_selling_price) AS sales
    FROM orders_data
    GROUP BY YEAR(`Order Date`), MONTH(`Order Date`)
)
SELECT 
    order_month,
    ROUND(SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END), 2) AS sales_2022,
    ROUND(SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END), 2) AS sales_2023,
    ROUND((SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) - 
          SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END)) / 
          SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) * 100, 2) AS growth_percentage
FROM cte 
GROUP BY order_month
ORDER BY order_month;

-- For each category, which month had highest sales
WITH cte AS (
    SELECT 
        category, 
        DATE_FORMAT(`Order Date`, '%Y-%m') AS order_year_month,
        SUM(quantity * Unit_selling_price) AS sales,
        ROW_NUMBER() OVER(PARTITION BY category ORDER BY SUM(quantity * Unit_selling_price) DESC) AS rn
    FROM orders_data
    GROUP BY category, DATE_FORMAT(`Order Date`, '%Y-%m')
)
SELECT 
    category AS Category, 
    order_year_month AS 'Order Year-Month', 
    sales AS 'Total Sales'
FROM cte
WHERE rn = 1;

-- Sub-category with highest growth in 2023 vs 2022
WITH cte AS (
    SELECT 
        `Sub Category` AS sub_category, 
        YEAR(`Order Date`) AS order_year,
        SUM(quantity * Unit_selling_price) AS sales
    FROM orders_data
    GROUP BY `Sub Category`, YEAR(`Order Date`)
),
cte2 AS (
    SELECT 
        sub_category,
        ROUND(SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END), 2) AS sales_2022,
        ROUND(SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END), 2) AS sales_2023
    FROM cte 
    GROUP BY sub_category
)
SELECT 
    sub_category AS 'Sub Category', 
    sales_2022 AS 'Sales in 2022',
    sales_2023 AS 'Sales in 2023',
    (sales_2023 - sales_2022) AS 'Diff in Amount',
    ROUND((sales_2023 - sales_2022) / sales_2022 * 100, 2) AS 'Growth Percentage'
FROM cte2
ORDER BY (sales_2023 - sales_2022) DESC
LIMIT 1;








