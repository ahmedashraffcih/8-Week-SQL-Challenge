/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(price) AS total_spent
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id

'''
- Result:
| customer_id | total_spent |
|-------------|-------------|
|      A      |      76     |
|      B      |      74     |
|      C      |      36     |
'''

-- extra. How many orders has each customer make?

SELECT customer_id, count(product_id) AS visits
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id

--2. How many days has each customer visited the restaurant?

SELECT customer_id, count(Distinct order_date) AS visit_counts
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id    

'''
- Result: 
+──────────────+───────────────+
| customer_id  | visit_counts  |
+──────────────+───────────────+
| A            | 4             |
| B            | 6             |
| C            | 2             |
+──────────────+───────────────+
'''


-- 3. What was the first item from the menu purchased by each customer?
WITH cte_order AS(
  SELECT 
  		customer_id,
  		m.product_name,
		ROW_NUMBER() OVER( 
          PARTITION BY customer_id 
          ORDER BY s.product_id,s.order_date) AS item_order
  FROM dannys_diner.sales AS s
	LEFT JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
)
SELECT * FROM cte_order
WHERE item_order=1

'''
- Result: 
+──────────────+───────────────+─────────────+
| customer_id  | product_name  | item_order  |
+──────────────+───────────────+─────────────+
| A            | sushi         | 1           |
| B            | curry         | 1           |
| C            | ramen         | 1           |
+──────────────+───────────────+─────────────+
'''

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT s.product_id,m.product_name,count(s.product_id) AS order_count
FROM dannys_diner.sales AS s
join dannys_diner.menu AS m
ON s.product_id=m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY count desc
limit 1

'''
-Result:
+─────────────+───────────────+──────────────+
| product_id  | product_name  | order_count  |
+─────────────+───────────────+──────────────+
| 3           | ramen         | 8            |
+─────────────+───────────────+──────────────+
'''

-- 5. Which item was the most popular for each customer?
WITH count_orders AS(
  SELECT 
  		customer_id,
  		m.product_name,
  		count(*) AS order_count
  FROM dannys_diner.sales AS s
	LEFT JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
  GROUP BY customer_id,m.product_name
  ORDER BY customer_id,order_count desc
),
popular AS (
	SELECT *, 
  	RANK() OVER(PARTITION BY customer_id ORDER BY order_count desc)AS rank
  FROM count_orders
)
SELECT * FROM popular
WHERE rank = 1


'''
- Result:
+──────────────+───────────────+──────────────+───────+
| customer_id  | product_name  | order_count  | rank  |
+──────────────+───────────────+──────────────+───────+
| A            | ramen         | 3            | 1     |
| B            | ramen         | 2            | 1     |
| B            | curry         | 2            | 1     |
| B            | sushi         | 2            | 1     |
| C            | ramen         | 3            | 1     |
+──────────────+───────────────+──────────────+───────+
'''

-- 6. Which item was purchased first by the customer after they became a member?
WITH members_orders AS(
  SELECT 
  		s.customer_id,
 		order_date,
  		join_date,
  		product_id,
		ROW_NUMBER() OVER( 
          PARTITION BY s.customer_id 
          ORDER BY s.order_date) AS item_order
  FROM dannys_diner.sales AS s
	LEFT JOIN dannys_diner.members AS m
	ON s.customer_id = m.customer_id
  WHERE order_date >= join_date
)
SELECT 
		customer_id,
		product_name,
        order_date,
        join_date
FROM members_orders AS o
LEFT JOIN dannys_diner.menu AS x
ON x.product_id =  o.product_id
WHERE item_order = 1 
ORDER BY customer_id

'''
- Result:
+──────────────+───────────────+──────────────+───────────+
| customer_id  | product_name  | order_date   | join_date |
+──────────────+───────────────+──────────────+───────────+
| A            | curry         | 2021-01-07   | 2021-01-07|
| B            | sushi         | 2021-01-11   | 2021-01-09|
+──────────────+───────────────+──────────────+───────────+
'''

-- 7. Which item was purchased just before the customer became a member?

with before_members_orders as(
  SELECT 
  		s.customer_id,
 		order_date,
  		join_date,
  		product_id,
		RANK() over( 
          partition by s.customer_id 
          order by s.order_date desc) AS item_order -- order the dates in descending order to get latest purchase first
  FROM dannys_diner.sales as s
	left join dannys_diner.members as m
	on s.customer_id = m.customer_id
  where order_date < join_date
)
select 
		customer_id,
		product_name,
        order_date,
        join_date
from before_members_orders as o
left join dannys_diner.menu as x
on x.product_id =  o.product_id
 where item_order=1
order by customer_id

'''
- Result:
+──────────────+───────────────+──────────────+───────────+
| customer_id  | product_name  | order_date   | join_date |
+──────────────+───────────────+──────────────+───────────+
| A            | sushi         | 2021-01-01   | 2021-01-07|
| B            | sushi         | 2021-01-04   | 2021-01-09|
+──────────────+───────────────+──────────────+───────────+
'''

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
		s.customer_id,
        COUNT(s.product_id) AS Items,
        SUM(price) AS total_price
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu as m
	ON s.product_id = m.product_id
JOIN dannys_diner.members as x
    ON s.customer_id = x.customer_id
WHERE order_date<join_date
GROUP BY s.customer_id
ORDER BY customer_id

'''
-Result:
+─────────────+────────+──────────────+
| customer_id | items  | total_price  |
+─────────────+────────+──────────────+
|      A      |   2    |      25      |
|      B      |   3    |      40      |
+─────────────+────────+──────────────+
'''
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
		s.customer_id,
        SUM(
        	CASE WHEN m.product_name = 'sushi' THEN price*20
          	ELSE price*10
          	END) AS total_points
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu as m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY customer_id

'''
-Result:
+────────────────────────────+
| customer_id | total_points |
+─────────────+──────────────+
|      A      |     860      |
|      B      |     940      |
|      C      |     360      |
+─────────────+──────────────+
'''

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH dates_cte AS 
(
   SELECT *, 
      DATEADD(DAY, 6, join_date) AS valid_date, 
      EOMONTH('2021-01-31') AS last_date
   FROM dannys_diner.members AS m
)
SELECT 
		s.customer_id,
        SUM(
        	CASE WHEN s.product_name = 'sushi' THEN price*20
          	WHEN s.order_date between d.join_date and d.valid_date THEN price*20
          ELSE price*10	END) AS total_points
FROM dates_cte AS d
JOIN dannys_diner.sales AS s
	ON s.customer_id = d.customer_id
JOIN menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date<= d.last_date
GROUP BY s.customer_id
ORDER BY customer_id

'''
-Result:
+────────────────────────────+
| customer_id | total_points |
+─────────────+──────────────+
|      A      |     1370     |
|      B      |     820      |
+─────────────+──────────────+
'''