1.SELECT
  	s.customer_id,
    sum(m.price) AS total
FROM dannys_diner.menu AS m
JOIN dannys_diner.sales AS s ON m.product_id= s.product_id
GROUP by 1
ORDER BY 1 ;

2.SELECT
  	customer_id,
    COUNT(DISTINCT(order_date)) AS total
FROM dannys_diner.sales 
GROUP by 1
ORDER BY 1 ;

3. WITH first_purchase AS
 ( 
   SELECT
  	customer_id,
    product_id,
    order_date,
    ROW_NUMBER () OVER (PARTITION BY customer_id order by order_date) AS occurrence
FROM dannys_diner.sales 
 )
SELECT f.customer_id,
       m.product_name
FROM first_purchase AS f
INNER JOIN dannys_diner.menu AS m ON f.product_id = m.product_id
WHERE occurrence = 1 ;

4.SELECT 
       m.product_name,
       COUNT(s.product_id)
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s ON m.product_id = s.product_id 
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1 ;

5. WITH favorite_item AS
(
SELECT 
       customer_id,
       product_id,
       RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(customer_id) DESC) AS most_purchase
FROM dannys_diner.sales
GROUP BY 1,2
)
SELECT 
       f.customer_id, 
       m.product_name
FROM favorite_item AS f
INNER JOIN dannys_diner.menu AS m ON f.product_id = m.product_id
WHERE f.most_purchase = 1
ORDER BY 1 ;

6. WITH member_1st_purchase AS
(
SELECT  
        s.customer_id,
        m.product_name,
	    RANK() OVER (PARTITION BY s.Customer_id ORDER BY s.Order_date) AS Rank
FROM dannys_diner.Sales s
JOIN dannys_diner.menu m ON m.product_id = s.product_id
JOIN dannys_diner.members mem ON mem.Customer_id = s.customer_id
WHERE s.order_date >= mem.join_date  
)  
SELECT 
       customer_id,
       product_name
FROM member_1st_purchase
WHERE rank=1 ;

7. WITH just_be4 AS
(
  SELECT  
        s.customer_id,
        m.product_name,
	    DENSE_RANK() OVER (PARTITION BY s.Customer_id ORDER BY s.Order_date DESC) AS Rank
FROM dannys_diner.Sales s
JOIN dannys_diner.menu m ON m.product_id = s.product_id
JOIN dannys_diner.members mem ON mem.Customer_id = s.customer_id
WHERE s.order_date < mem.join_date  
)
SELECT 
        customer_id,
        product_name
FROM just_be4
WHERE rank = 1;

8. SELECT
       s.customer_id,
       COUNT(s.product_id), 
       SUM(m.price)
FROM dannys_diner.sales AS s
JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
GROUP BY 1;

9. WITH points AS
(
SELECT product_id,
       product_name,
       price,
       CASE WHEN product_id = 1 THEN price*20
            ELSE price*10 END AS points
FROM dannys_diner.menu
)
SELECT s.customer_id, 
       SUM(p.points) as total
FROM dannys_diner.sales s
JOIN points p ON p.product_id = s.product_id
GROUP BY 1 ;

10. WITH dates AS
(
  SELECT 
       customer_id,
       join_date,
       join_date + 6 as valid
FROM dannys_diner.members
 )
SELECT 
       s.customer_id,
       SUM(CASE WHEN s.product_id = 1 THEN m.price*20
       WHEN s.order_date BETWEEN d.join_date AND d.valid THEN m.price*20 ELSE m.price*10 END) AS points
FROM dates AS d
JOIN dannys_diner.sales AS s ON d.customer_id = s.customer_id
JOIN dannys_diner.menu AS m on s.product_id = m.product_id 
WHERE s.order_date <= '2021-01-31'
GROUP BY 1;

11. SELECT 
       s.customer_id,
       s.order_date,
       m.product_name,
       m.price,
       CASE 
       WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member
       
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.members as mem ON s.customer_id = mem.customer_id
JOIN dannys_diner.menu as m ON s.product_id = m.product_id
ORDER BY 1,2 ;

12. WITH table_1 AS
(
  SELECT 
       s.customer_id,
       s.order_date,
       m.product_name,
       m.price,
       CASE 
       WHEN s.order_date >= mem.join_date THEN 'Y' ELSE 'N' END AS member
       
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.members as mem ON s.customer_id = mem.customer_id
JOIN dannys_diner.menu as m ON s.product_id = m.product_id
ORDER BY 1,2 
 )
SELECT 
       *,
       CASE WHEN member = 'N' THEN Null ELSE
       RANK () OVER(PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM table_1 ;
      
