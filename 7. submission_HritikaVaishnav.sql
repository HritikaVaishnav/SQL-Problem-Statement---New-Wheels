/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  USE vehdb;
  SELECT * FROM `customer_t`;
  SELECT * FROM `order_t`;
  SELECT * FROM `product_t`;
  SELECT * FROM `shipper_t`;
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

SELECT state, COUNT(*) AS customer_count
FROM customer_t
GROUP BY state
ORDER BY customer_count DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

WITH FeedbackMapping AS (
  SELECT
    CASE customer_feedback
      WHEN 'Very Bad' THEN 1
      WHEN 'Bad' THEN 2
      WHEN 'Okay' THEN 3
      WHEN 'Good' THEN 4
      WHEN 'Very Good' THEN 5
    END AS feedback_value,
    quarter_number
  FROM order_t
  WHERE customer_feedback IN ('Very Bad', 'Bad', 'Okay', 'Good', 'Very Good')
)

SELECT quarter_number, AVG(feedback_value) AS average_rating
FROM FeedbackMapping
GROUP BY quarter_number
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.*/
            
WITH FeedbackCounts AS (
  SELECT
    quarter_number,
    SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) AS very_bad_count,
    SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) AS bad_count,
    SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) AS okay_count,
    SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) AS good_count,
    SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS very_good_count,
    COUNT(*) AS total_feedback_count
  FROM order_t
  WHERE customer_feedback IN ('Very Bad', 'Bad', 'Okay', 'Good', 'Very Good')
  GROUP BY quarter_number
)

SELECT
  q.quarter_number,
  q.very_bad_count,
  q.bad_count,
  q.okay_count,
  q.good_count,
  q.very_good_count,
  q.total_feedback_count,
  (q.very_bad_count / q.total_feedback_count) * 100 AS very_bad_percentage,
  (q.bad_count / q.total_feedback_count) * 100 AS bad_percentage,
  (q.okay_count / q.total_feedback_count) * 100 AS okay_percentage,
  (q.good_count / q.total_feedback_count) * 100 AS good_percentage,
  (q.very_good_count / q.total_feedback_count) * 100 AS very_good_percentage
FROM FeedbackCounts q;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

SELECT vehicle_maker, COUNT(customer_id) AS customer_count
FROM product_t
INNER JOIN order_t ON product_t.product_id = order_t.product_id
GROUP BY vehicle_maker
ORDER BY customer_count DESC
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

WITH RankedMakes AS (
    SELECT
        c.state,
        p.vehicle_maker,
        COUNT(c.customer_id) AS customer_count,
        RANK() OVER (PARTITION BY c.state ORDER BY COUNT(c.customer_id) DESC) AS ranking
    FROM
        customer_t c
    JOIN
        order_t o ON c.customer_id = o.customer_id
    JOIN
        product_t p ON o.product_id = p.product_id
    GROUP BY
        c.state,
        p.vehicle_maker
)

SELECT
    state,
    vehicle_maker AS most_preferred_vehicle_make,
    ranking AS ranks
FROM RankedMakes
WHERE
    ranking = 1;

- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

SELECT
    YEAR(order_date) AS year,
    QUARTER(order_date) AS quarter,
    COUNT(*) AS number_of_orders
FROM
    order_t
GROUP BY
    YEAR(order_date), QUARTER(order_date)
ORDER BY
    YEAR(order_date), QUARTER(order_date);

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
   WITH QuarterRevenue AS (
    SELECT
        YEAR(order_date) AS year,
        QUARTER(order_date) AS quarter,
        SUM(vehicle_price * quantity) AS revenue
    FROM
        order_t
    GROUP BY
        YEAR(order_date), QUARTER(order_date)
    ORDER BY
        YEAR(order_date), QUARTER(order_date)
)

SELECT
    CONCAT(year, ' Q', quarter) AS quarter,
    revenue,
    ((revenue - LAG(revenue) OVER (ORDER BY year, quarter)) / LAG(revenue) OVER (ORDER BY year, quarter)) * 100 AS qoq_percentage_change
FROM
    QuarterRevenue;

    -- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

SELECT
    CONCAT(YEAR(order_date), ' Q', QUARTER(order_date)) AS quarter,
    SUM(vehicle_price * quantity) AS revenue,
    COUNT(order_id) AS number_of_orders
FROM
    order_t
GROUP BY
    YEAR(order_date), QUARTER(order_date), quarter
ORDER BY
    YEAR(order_date), QUARTER(order_date);

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

SELECT
    customer_t.credit_card_type,
    AVG(order_t.discount) AS average_discount
FROM
    order_t
JOIN
    customer_t ON order_t.customer_id = customer_t.customer_id
GROUP BY
    customer_t.credit_card_type;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
SELECT
    CONCAT(YEAR(order_date), ' Q', QUARTER(order_date)) AS quarter,
    AVG(DATEDIFF(ship_date, order_date)) AS average_shipping_time
FROM
    order_t
GROUP BY
    YEAR(order_date), QUARTER(order_date), quarter
ORDER BY
    YEAR(order_date), QUARTER(order_date);

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------
/*[1] 0.5 pts for each metric present in the overview slide 
(Total Revenue, Total Orders, Total Customers, Average Rating, Last Quarter Revenue, Last Quarter Orders, 
Average Days to Ship, % Good Feedback) (0.5 * 8)*/

-- 1. Total Revenue:
SELECT SUM(vehicle_price * quantity) AS total_revenue
FROM order_t;

-- 2. Total Orders:
SELECT COUNT(order_id) AS total_orders
FROM order_t;

-- 3. Total Customers:
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM customer_t;

-- 4. Average Rating
SELECT
    AVG(CASE
        WHEN customer_feedback = 'Good' THEN 5
        WHEN customer_feedback = 'Average' THEN 3
        WHEN customer_feedback = 'Poor' THEN 1
        ELSE 0
    END) AS average_rating
FROM
    order_t;

-- 5. Last Quarter Revenue:
SELECT
    SUM(vehicle_price * quantity) AS last_quarter_revenue
FROM
    order_t
WHERE
    YEAR(order_date) = YEAR(CURRENT_DATE - INTERVAL 3 MONTH)
    AND QUARTER(order_date) = QUARTER(CURRENT_DATE - INTERVAL 3 MONTH);

-- 6. Last Quarter Orders:
SELECT
    COUNT(order_id) AS last_quarter_orders
FROM
    order_t
WHERE
    YEAR(order_date) = YEAR(CURRENT_DATE - INTERVAL 3 MONTH)
    AND QUARTER(order_date) = QUARTER(CURRENT_DATE - INTERVAL 3 MONTH);
    
-- 7. Average Days to Ship:
SELECT AVG(DATEDIFF(ship_date, order_date)) AS average_days_to_ship
FROM order_t;

-- 8. % Good Feedback
SELECT
    (SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) / COUNT(customer_feedback)) * 100 AS percent_good_feedback
FROM order_t;
-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



