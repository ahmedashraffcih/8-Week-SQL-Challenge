# [8-Week SQL Challenge](https://github.com/ndleah/8-Week-SQL-Challenge) 

# 🍜 Case Study #1 - Danny's Diner
<p align="center">
<img src="/imgs/1.png" width=40% height=40%>

## 📕 Table Of Contents
* 🛠️ [Problem Statement](#problem-statement)
* 📂 [Dataset](#dataset)
* 🧙‍♂️ [Case Study Questions](#case-study-questions)
* 🚀 [Solutions](#solutions)
* 🐋 [Limitations](#limitations)
  
---

## 🛠️ Problem Statement

> Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

 <br /> 

---

## 📂 Dataset
Danny has shared with you 3 key datasets for this case study:

### **```sales```**

<details>
<summary>
View table
</summary>

The sales table captures all ```customer_id``` level purchases with an corresponding ```order_date``` and ```product_id``` information for when and what menu items were ordered.

|customer_id|order_date|product_id|
|-----------|----------|----------|
|A          |2021-01-01|1         |
|A          |2021-01-01|2         |
|A          |2021-01-07|2         |
|A          |2021-01-10|3         |
|A          |2021-01-11|3         |
|A          |2021-01-11|3         |
|B          |2021-01-01|2         |
|B          |2021-01-02|2         |
|B          |2021-01-04|1         |
|B          |2021-01-11|1         |
|B          |2021-01-16|3         |
|B          |2021-02-01|3         |
|C          |2021-01-01|3         |
|C          |2021-01-01|3         |
|C          |2021-01-07|3         |

 </details>

### **```menu```**

<details>
<summary>
View table
</summary>

The menu table maps the ```product_id``` to the actual ```product_name``` and price of each menu item.

|product_id |product_name|price     |
|-----------|------------|----------|
|1          |sushi       |10        |
|2          |curry       |15        |
|3          |ramen       |12        |

</details>

### **```members```**

<details>
<summary>
View table
</summary>

The final members table captures the ```join_date``` when a ```customer_id``` joined the beta version of the Danny’s Diner loyalty program.

|customer_id|join_date |
|-----------|----------|
|A          |1/7/2021  |
|B          |1/9/2021  |

 </details>

## 🧙‍♂️ Case Study Questions
<p align="center">
<img src="https://media3.giphy.com/media/JQXKbzdLTQJJKP176X/giphy.gif" width=80% height=80%>

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

 <br /> 

## 🚀 Solutions

### **Q1. What is the total amount each customer spent at the restaurant?**
```sql
SELECT s.customer_id, SUM(price) AS total_spent
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY customer_id
```

| customer_id | total_spent |
| ----------- | ----------- |
|      A      |     76      |
|      B      |     74      |
|      C      |     36      |

---

### **Q2. How many days has each customer visited the restaurant?**
```sql
SELECT customer_id, count(Distinct order_date) AS visit_counts
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id    
```

|customer_id|visit_counts|
|-----------|------------|
|     A     |     4      |
|     B     |     6      |
|     C     |     2      |


---

### **Q3. What was the first item from the menu purchased by each customer?**
```sql
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

```

**Result:**
| customer_id | product_name | item_order |
| ----------- | ------------ | ---------- |
| A           | sushi        | 1          |
| B           | curry        | 1          |
| C           | ramen        | 1          |

---

### **Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
```sql
SELECT s.product_id,m.product_name,count(s.product_id) AS order_count
FROM dannys_diner.sales AS s
join dannys_diner.menu AS m
ON s.product_id=m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY count desc
limit 1
```

|product_id|product_name|order_count|
|----------|------------|-----------|
|3         |ramen       |8          |

---

### **Q5. Which item was the most popular for each customer?**
```sql
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

```
|customer_id|product_name|order_count|rank|
|-----------|------------|-----------|----|
|     A     |   ramen    |     3     |  1 |  
|     B     |   ramen    |     2     |  1 | 
|     B     |   curry    |     2     |  1 | 
|     B     |   sushi    |     2     |  1 | 
|     C     |   ramen    |     3     |  1 | 

---

### **Q6. Which item was purchased first by the customer after they became a member?**

**Note:** In this question, the orders made during the join date are counted within the first order as well</span>

```sql
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
```

| customer_id | product_name | order_date               | purchase_order |
| ----------- | ------------ | ------------------------ | -------------- |
| A           | curry        | 2021-01-07T00:00:00.000Z | 1              |
| B           | sushi        | 2021-01-11T00:00:00.000Z | 1              |

---

### **Q7. Which item was purchased just before the customer became a member?**

```sql
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

```

| customer_id | product_name | order_date |  join_date |
| ----------- | ------------ | ---------- | ---------- |
| A           | sushi        | 2021-01-01 | 2021-01-07 |
| A           | curry        | 2021-01-01 | 2021-01-07 |
| B           | sushi        | 2021-01-04 | 2021-01-09 |

---

### **Q8. What is the total items and amount spent for each member before they became a member?**
```sql
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

```

| customer_id | items | total_price |
| ----------- | ------| ----------- |
| A           |   2   |      25     |
| B           |   3   |      40     |
  

---

### **Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```sql
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
```

| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| C           | 360          |

---

### **Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
```sql
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
```
| customer_id | total_points |
| ----------- | ------------ |
| A           | 1370         |
| B           | 820          |
---
<p>&copy; 2022 Ahmed Ashraf</p>