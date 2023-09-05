-- Having a glimpse of each table in the database
SELECT *
FROM swiggy..food;

SELECT *
FROM swiggy..menu;

SELECT *
FROM swiggy..order_details;

SELECT *
FROM swiggy..orders;

SELECT *
FROM swiggy..restaurants;

SELECT *
FROM swiggy..users;

--1. Customers who have never ordered
SELECT name
FROM swiggy..users
WHERE user_id not in (SELECT user_id FROM swiggy..orders);

--2. Average Price per dish
SELECT f.f_name, AVG(m.price) AS avg_price
FROM swiggy..food f
INNER JOIN swiggy..menu m
ON f.f_id = m.f_id
GROUP BY f.f_name;


-- Top restaurants in terms of number of order for a given month
WITH CTE AS (
SELECT MONTH(o.date) AS MONTH_, r_id,  COUNT(order_id) AS Orders
FROM swiggy..orders o
WHERE r_id is NOT NULL and MONTH(o.date) = 5 -- Write the respective month number here 
GROUP BY MONTH(o.date), r_id
--ORDER BY 1, 2
)
SELECT r_name
FROM swiggy..restaurants 
WHERE r_id = (
			SELECT r_id
			FROM CTE
			WHERE Orders = (SELECT MAX(Orders) FROM CTE));

-- restaurants with monthly sales greater than x for 
WITH CTE1 AS
(
SELECT MONTH(date) AS month_, r_id, SUM(amount) AS Monthly_sales
FROM swiggy..orders
WHERE r_id IS NOT NULL and MONTH(date) = 6  -- Enter the month here
GROUP BY MONTH(date), r_id
HAVING SUM(amount) > 700 -- Enter the given monthly sales here
)
SELECT r_name 
FROM swiggy..restaurants
WHERE r_id IN(SELECT r_id FROM CTE1);

-- Show all orders with order details for a particular customer in a particular date range
-- Basically suppose the customer is Ankit, so in a given date range find which restaurant he visited, what he ordered and type of food
WITH temp AS
(
SELECT * FROM swiggy..orders
WHERE user_id = 
(SELECT user_id
FROM swiggy..users
WHERE name = 'Ankit') AND
date BETWEEN '2022-05-15 00:00:00.000' AND '2022-06-30 00:00:00.000'
)
SELECT r.r_name,f.f_name, f.type
FROM swiggy..order_details od
INNER JOIN temp t
ON od.order_id = t.order_id
INNER JOIN swiggy..food f
ON f.f_id = od.f_id
INNER JOIN swiggy..restaurants r
ON r.r_id = t.r_id;

-- 6. Find restaurants with max repeated customers 
-- In which restaurants, users repeat..
SELECT r.r_name, COUNT(*) AS 'unique_customers'
FROM
(
SELECT r_id, user_id, COUNT(*) AS 'visits'
FROM swiggy..orders
WHERE r_id IS NOT NULL
GROUP BY r_id, user_id
HAVING COUNT(*) > 1) t
INNER JOIN swiggy..restaurants r
ON r.r_id = t.r_id
GROUP BY r.r_name
ORDER BY 2 DESC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY; -- KFC has most number of repeated customers i.e. 2


-- 7. Month Over Month revenue growth of Swiggy
SELECT Month_num, 
((Revenue - previous_month_revenue) / previous_month_revenue) * 100 AS monthly_revenue_grwoth
FROM
(
SELECT MONTH(date) Month_num,
SUM(amount) AS Revenue,
LAG(SUM(amount)) OVER(ORDER BY MONTH(date)) AS previous_month_revenue
FROM swiggy..orders
WHERE date IS NOT NULL
GROUP BY MONTH(date)) t;

-- 8. Customer -> favourite food
-- A food which will be ordered most number of times will be customer's favourite food
WITH food_ranking
AS (
SELECT u.name,
f.f_name,
COUNT(*) AS No_of_orders,
DENSE_RANK() OVER(PARTITION BY u.name ORDER BY COUNT(f.f_id) DESC) AS ranking
FROM swiggy..users u 
INNER JOIN swiggy..orders o
ON o.user_id = u.user_id
INNER JOIN swiggy..order_details od
ON o.order_id = od.order_id
INNER JOIN swiggy..food f
ON f.f_id = od.f_id
GROUP BY u.name, f.f_name
HAVING COUNT(f.f_id) > 1)
SELECT name, 
f_name
FROM food_ranking
WHERE ranking = 1;


-- 9. Find the most loyal customers for all restaurant
WITH loyal_users AS
(
SELECT r.r_name,
u.name,
COUNT(*) AS visits,
DENSE_RANK() OVER(PARTITION BY u.name ORDER BY COUNT(*) DESC) AS ranking
FROM swiggy..restaurants r
INNER JOIN swiggy..orders o
ON o.r_id = r.r_id
INNER JOIN swiggy..users u 
ON u.user_id = o.user_id
GROUP BY r.r_name, u.name
HAVING COUNT(*) > 1)
SELECT r_name,
name
FROM loyal_users
WHERE ranking = 1;
