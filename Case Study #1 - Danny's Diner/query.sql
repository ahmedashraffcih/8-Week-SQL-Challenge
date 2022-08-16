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
SELECT s.customer_id, SUM(price) as total_spent
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

SELECT customer_id, count(product_id) as visits
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id

--2. How many days has each customer visited the restaurant?

SELECT customer_id, count(Distinct order_date) as visit_counts
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
with cte_order as(
  SELECT 
  		customer_id,
  		m.product_name,
		ROW_NUMBER() over( 
          partition by customer_id 
          order by s.product_id,s.order_date) AS item_order
  FROM dannys_diner.sales as s
	left join dannys_diner.menu as m
	on s.product_id = m.product_id
)
select * from cte_order
where item_order=1

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
select s.product_id,m.product_name,count(s.product_id) as order_count
from dannys_diner.sales as s
join dannys_diner.menu as m
on s.product_id=m.product_id
group by s.product_id, m.product_name
order by count desc
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
with count_orders as(
  SELECT 
  		customer_id,
  		m.product_name,
  		count(*) as order_count
  FROM dannys_diner.sales as s
	left join dannys_diner.menu as m
	on s.product_id = m.product_id
  group by customer_id,m.product_name
  order by customer_id,order_count desc
),
popular as (
	select *, 
  	RANK() OVER(PARTITION BY customer_id order by order_count desc)as rank
  from count_orders
)
select * from popular
where rank = 1


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