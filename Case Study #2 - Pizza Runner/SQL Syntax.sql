1. SELECT
	COUNT(order_id)
FROM customer_orders ;

2. SELECT
	COUNT(DISTINCT(order_id))
FROM customer_orders ;

3. SELECT 
  runner_id,
  COUNT(DISTINCT order_id)
FROM pizza_runner.runner_orders
WHERE distance <> 'null'
GROUP BY 1 ;

4. How many of each type of pizza was delivered?
   SELECT name.pizza_name,
       COUNT(name.pizza_id)
FROM pizza_runner.pizza_names AS name
JOIN pizza_runner.customer_orders AS orders
ON name.pizza_id = orders.pizza_id
JOIN pizza_runner.runner_orders AS deliver
ON orders.order_id = deliver.order_id
WHERE deliver.distance <> 'null'
GROUP BY 1 ;
OR
SELECT
  name.pizza_name,
  COUNT(name.pizza_id)
FROM
  pizza_runner.customer_orders AS orders
JOIN pizza_runner.pizza_names AS name ON orders.pizza_id = name.pizza_id
WHERE
  EXISTS(
    SELECT
      1
    FROM
      pizza_runner.runner_orders AS delivery
    WHERE
      orders.order_id = delivery.order_id AND distance <> 'null'
  )
GROUP BY 1 ;

5.How many Vegetarian and Meatlovers were ordered by each customer?
SELECT orders.customer_id,
       name.pizza_name,
       COUNT(name.pizza_id) 
FROM pizza_runner.pizza_names AS name
JOIN pizza_runner.customer_orders AS orders
ON name.pizza_id = orders.pizza_id
GROUP BY 1, 2
ORDER BY 1, 2 ;

6. What was the maximum number of pizzas delivered in a single order?
WITH table_1 AS
(
SELECT orders.customer_id,
       COUNT(orders.customer_id) AS number_of_orders
FROM pizza_runner.customer_orders AS orders
JOIN pizza_runner.runner_orders AS deliver
ON orders.order_id = deliver.order_id
WHERE deliver.distance <> 'null'
GROUP BY 1
  )
SELECT MAX(number_of_orders)
FROM table_1

7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
  customer_id,
  SUM(
    CASE
      WHEN exclusions NOT IN ('', 'null')
      OR extras NOT IN ('', 'null') THEN 1
      ELSE 0
    END
  ) AS at_least_1_change,
  SUM(
    CASE
      WHEN exclusions IN ('', 'null')
      AND (extras IN ('', 'null') OR extras IS NULL) THEN 1
      ELSE 0
    END
  ) AS no_change
FROM
  pizza_runner.customer_orders AS orders
WHERE
  EXISTS(
    SELECT
      1
    FROM
      pizza_runner.runner_orders delivery
    WHERE
      orders.order_id = delivery.order_id
      AND distance <> 'null'
  )
GROUP BY 1
ORDER BY 1 ;

8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
       SUM(
           CASE WHEN exclusions NOT IN ('', 'null')
      AND extras NOT IN ('', 'null') THEN 1
      ELSE NULL
    END
  ) AS change
FROM pizza_runner.customer_orders AS orders
JOIN pizza_runner.runner_orders AS delivery ON orders.order_id = delivery.order_id
AND distance <> 'null'

9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATE_PART('HOUR',order_time) AS hour,
       COUNT(order_id)
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 1 ;

10. What was the volume of orders for each day of the week?
SELECT TO_CHAR(order_time,'DAY') AS day,
       COUNT(order_id)
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 1 ;

####

1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT TO_CHAR(registration_date,'WEEK') AS week,
       COUNT(runner_id)
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1 ;

2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH table_1 AS
(
SELECT DISTINCT runner_id, (EXTRACT(EPOCH FROM pickup_time :: TIMESTAMP) - EXTRACT(EPOCH FROM order_time))/60 AS times 
FROM pizza_runner.runner_orders AS delivery 
JOIN pizza_runner.customer_orders AS orders
ON delivery.order_id = orders.order_id
WHERE pickup_time <> 'null'
ORDER BY runner_id
 )
SELECT runner_id, ROUND(AVG(times :: NUMERIC))
FROM table_1
GROUP BY 1
ORDER BY 1 ;

3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH table_1 AS
(
SELECT COUNT(orders.order_id) AS number_of_pizzas, (EXTRACT(EPOCH FROM pickup_time :: TIMESTAMP) - EXTRACT(EPOCH FROM order_time))/60 AS times 
FROM pizza_runner.runner_orders AS delivery 
JOIN pizza_runner.customer_orders AS orders
ON delivery.order_id = orders.order_id
WHERE pickup_time <> 'null'
GROUP BY pickup_time, orders.order_time
)
SELECT number_of_pizzas, ROUND(AVG(times::NUMERIC))
FROM table_1
GROUP BY 1
ORDER BY 1 ;

4. What was the average distance travelled for each customer?
WITH table_1 AS
(
SELECT customer_id, 
CASE WHEN distance LIKE '%km' 
        THEN TRIM('km' FROM distance) ELSE distance END AS distance
FROM pizza_runner.runner_orders AS delivery 
JOIN pizza_runner.customer_orders AS orders
ON delivery.order_id = orders.order_id
WHERE distance <> 'null'
)
SELECT customer_id, AVG(distance :: float)
FROM table_1
GROUP BY 1
ORDER BY 1 ;

5. What was the difference between the longest and shortest delivery times for all orders?

WITH table_1 AS
(
SELECT CASE WHEN duration <> 'null' THEN LEFT(duration,2) ELSE NULL END AS duration
FROM pizza_runner.runner_orders
  )
SELECT MAX(duration :: NUMERIC) - MIN(duration :: NUMERIC) AS difference
FROM table_1 

6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
WITH table_1 AS
(
SELECT runner_id,
       order_id,
       CASE WHEN duration <> 'null' THEN LEFT(duration,2) ELSE NULL END AS duration,
       CASE WHEN distance LIKE '%km' 
        THEN TRIM('km' FROM distance) ELSE distance END AS distance
FROM pizza_runner.runner_orders
WHERE distance <> 'null'
)
SELECT runner_id, 
       order_id,
       (distance :: NUMERIC) / ((duration :: NUMERIC)/60) AS speed
FROM table_1 ;
      

7. What is the successful delivery percentage for each runner?
SELECT runner_id, 
       ROUND(100 * SUM(CASE WHEN distance = 'null' THEN 0
    ELSE 1 END) / COUNT(*), 0) AS success_rate
FROM pizza_runner.runner_orders
GROUP BY 1
ORDER BY 1;

#####

1. What are the standard ingredients for each pizza?
WITH new_pizza_recipes AS 
(
  SELECT
    pizza_id,
    REGEXP_SPLIT_TO_TABLE(toppings, ',\s') :: INTEGER AS topping_id
  FROM
    pizza_runner.pizza_recipes
)
SELECT
  new.pizza_id,
  STRING_AGG(top.topping_name, ', ') as ingredients
FROM
  new_pizza_recipes AS new
JOIN pizza_runner.pizza_toppings AS top ON new.topping_id = top.topping_id
GROUP BY 1
ORDER BY 1 ;

2. What was the most commonly added extra?
WITH table_1 AS  
(
SELECT pizza_id,
       REGEXP_SPLIT_TO_TABLE(toppings, ',\s') :: INTEGER AS topping_id
FROM pizza_runner.pizza_recipes
) 
SELECT topping_name
       COUNT
FROM pizza_runner.customer_orders AS orders
JOIN table_1 AS recipe ON recipe.pizza_id = orders.pizza_id
JOIN pizza_runner.pizza_toppings AS top ON recipe.topping_id = top.topping_id

3. What was the most common exclusion?

4. Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

#####

1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

2. What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra

3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas

5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

#####

If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
