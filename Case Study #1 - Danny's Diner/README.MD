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
SELECT s.customer_id, SUM(price) as total_spent
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
SELECT customer_id, count(Distinct order_date) as visit_counts
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
select s.product_id,m.product_name,count(s.product_id) as order_count
from dannys_diner.sales as s
join dannys_diner.menu as m
on s.product_id=m.product_id
group by s.product_id, m.product_name
order by count desc
limit 1
```

|product_id|product_name|order_count|
|----------|------------|-----------|
|3         |ramen       |8          |

---

### **Q5. Which item was the most popular for each customer?**
```sql
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
WITH cte_first_after_mem AS (
  SELECT 
    customer_id,
    product_name,
    order_date,
    RANK() OVER(
    PARTITION BY customer_id
    ORDER BY order_date) AS purchase_order
  FROM membership_validation
  WHERE membership = 'X'
)
SELECT * FROM cte_first_after_mem
WHERE purchase_order = 1;
```

| customer_id | product_name | order_date               | purchase_order |
| ----------- | ------------ | ------------------------ | -------------- |
| A           | curry        | 2021-01-07T00:00:00.000Z | 1              |
| B           | sushi        | 2021-01-11T00:00:00.000Z | 1              |

---

### **Q7. Which item was purchased just before the customer became a member?**
> ⚠️ Access [**here**](#️-question-7-which-item-was-purchased-just-before-the-customer-became-a-member) to view the limitations of this question

```sql
WITH cte_last_before_mem AS (
  SELECT 
    customer_id,
    product_name,
    order_date,
    RANK() OVER(
    PARTITION BY customer_id
    ORDER BY order_date DESC) AS purchase_order
  FROM membership_validation
  WHERE membership = ''
)
SELECT * FROM cte_last_before_mem
--since we used the ORDER BY DESC in the query above, the order 1 would mean the last date before the customer join in the membership
WHERE purchase_order = 1;
```

| customer_id | product_name | order_date               | purchase_order |
| ----------- | ------------ | ------------------------ | -------------- |
| A           | sushi        | 2021-01-01T00:00:00.000Z | 1              |
| A           | curry        | 2021-01-01T00:00:00.000Z | 1              |
| B           | sushi        | 2021-01-04T00:00:00.000Z | 1              |

---

### **Q8. What is the total items and amount spent for each member before they became a member?**
```sql
WITH cte_spent_before_mem AS (
  SELECT 
    customer_id,
    product_name,
    price
  FROM membership_validation
  WHERE membership = ''
)
SELECT 
  customer_id,
  SUM(price) AS total_spent,
  COUNT(*) AS total_items
FROM cte_spent_before_mem
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | total_spent | total_items |
| ----------- | ----------- | ----------- |
| A           | 25          | 2           |
| B           | 40          | 3           |


---

### **Q9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```sql
SELECT
  customer_id,
  SUM(
  CASE WHEN product_name = 'sushi'
  THEN (price * 20)
  ELSE (price * 10)
  END
  ) AS total_points
FROM membership_validation
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |

---

### **Q10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**

> ⚠️ Access [**here**](#️-question-10-in-the-first-week-after-a-customer-joins-the-program-including-their-join-date-they-earn-2x-points-on-all-items-not-just-sushi---how-many-points-do-customer-a-and-b-have-at-the-end-of-january) to view the limitations of this question

If we combine the condition from [**question 9**](#q9-if-each-1-spent-equates-to-10-points-and-sushi-has-a-2x-points-multiplier---how-many-points-would-each-customer-have) and the condition in this question, we will have 2 point calculation cases under:
- **Normal condition:** when **```product_name = 'sushi'```** = points X2, **```else```** = points X1
- **Conditions within the first week of membership:** when all menu items are awarded X2 points

I have created a timeline as illustration for wheareas we apply the conditions:
<p align="center">
<img src="https://github.com/ndleah/8-Week-SQL-Challenge/blob/main/IMG/timeline.png" width=100% height=100%>

### **Step 1:**

As transparent from the timeline, I could see that the first need to take is to seperate the timeframe that will apply **condition 1** (Normal condition) from **condition 2** (First week membership's condition). Thus, I will create a temp table for days validation within and without the first week:

> Note that I will use data from the **```membership_validation```** table from the previous question to exclude those customers did not join the membership program also
```sql
--create temp table for days validation within the first week membership
DROP TABLE IF EXISTS membership_first_week_validation;
CREATE TEMP TABLE membership_first_week_validation AS 
WITH cte_valid AS (
SELECT
  customer_id,
  order_date,
  product_name,
  price,
  /* since we use aggregate function for our condition clause, the query will require to have the GROUP BY clause which also include the order_date and product_name. 
  
  This can possibly combine those orders with same product name in the same date into 1, which can lead to errors in our final sum calculation. 
  
  Thus, I will count all the order_count group by order_date to avoid these mistakes */
  COUNT(*) AS order_count,
  CASE WHEN order_date BETWEEN join_date AND (join_date + 6)
  THEN 'X'
  ELSE ''
  END AS within_first_week
FROM membership_validation
GROUP BY 
  customer_id,
  order_date,
  product_name,
  price,
  join_date
 ORDER BY
  customer_id,
  order_date
)
SELECT * FROM cte_valid
--Since we only calculate total points of customers by the end of January, I set the order_date condition < '2021-02-01' to avoid all the unecessary sum orders calculation after January
WHERE order_date < '2021-02-01';
--inspect the table result
SELECT * FROM membership_first_week_validation;
```

| customer_id | order_date               | product_name | price | order_count | within_first_week |
| ----------- | ------------------------ | ------------ | ----- | ----------- | ----------------- |
| A           | 2021-01-01T00:00:00.000Z | curry        | 15    | 1           |                   |
| A           | 2021-01-01T00:00:00.000Z | sushi        | 10    | 1           |                   |
| A           | 2021-01-07T00:00:00.000Z | curry        | 15    | 1           | X                 |
| A           | 2021-01-10T00:00:00.000Z | ramen        | 12    | 1           | X                 |
| A           | 2021-01-11T00:00:00.000Z | ramen        | 12    | 2           | X                 |
| B           | 2021-01-01T00:00:00.000Z | curry        | 15    | 1           |                   |
| B           | 2021-01-02T00:00:00.000Z | curry        | 15    | 1           |                   |
| B           | 2021-01-04T00:00:00.000Z | sushi        | 10    | 1           |                   |
| B           | 2021-01-11T00:00:00.000Z | sushi        | 10    | 1           | X                 |
| B           | 2021-01-16T00:00:00.000Z | ramen        | 12    | 1           |                   |

After the table is generated, do you notice how the **```order_count```** from the **ramen order** made by **customer A** in ```'2021-01-11'``` is diplayed? If I didn't calculate the **```order_count```**, our calculation is possibly missing 1 order from ```'2021-01-11'```, so it is very crucial to also include this information when doing our calculation!

### **Step 2:**
Now that we have two sets of data to calculate different cases applying for condition 1 and 2, next step I will created 2 tables based on our previous **```first_week_validation```** table:
```sql
--create temp table for points calculation only in the first week of membership
DROP TABLE IF EXISTS membership_first_week_points;
CREATE TEMP TABLE membership_first_week_points AS 
WITH cte_first_week_count AS (
  SELECT * FROM membership_first_week_validation
  WHERE within_first_week = 'X'
)
SELECT
  customer_id,
  SUM(
  CASE WHEN within_first_week = 'X'
  THEN (price * order_count * 20)
  ELSE (price * order_count * 10)
  END
  ) AS total_points
FROM cte_first_week_count
GROUP BY customer_id;
--inspect table results
SELECT * FROM membership_first_week_points;
```

| customer_id | total_points |
| ----------- | ------------ |
| A           | 1020         |
| B           | 200          |


```sql
--create temp table for points calculation excluded the first week membership (before membership + after the first week membership)
DROP TABLE IF EXISTS membership_non_first_week_points;
CREATE TEMP TABLE membership_non_first_week_points AS 
WITH cte_first_week_count AS (
  SELECT * FROM membership_first_week_validation
  WHERE within_first_week = ''
)
SELECT
  customer_id,
  SUM(
  CASE WHEN product_name = 'sushi'
  THEN (price * order_count * 20)
  ELSE (price * order_count * 10)
  END
  ) AS total_points
FROM cte_first_week_count
GROUP BY customer_id;
--inspect table results
SELECT * FROM membership_non_first_week_points;
```

**Result:**
| customer_id | total_points |
| ----------- | ------------ |
| A           | 350          |
| B           | 620          |

**Finding**:
> Total points exclude the first week of membership program of:
> * **Customer A** is **350**
> * **Customer B** is **620**

### **Step 3:**

Now that we have total points for both conditions, let's aggregate all the points value together to get the final result!

```sql
--perform table union to aggregate our point values from both point calculation tables, then use SUM aggregate function to get our result
WITH cte_union AS (
  SELECT * FROM membership_first_week_points
  UNION
  SELECT * FROM membership_non_first_week_points
)
SELECT
  customer_id,
  SUM(total_points)
FROM cte_union
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | SUM          |
| ----------- | ------------ |
| A           | 1370         |
| B           | 820          |

 ## 🐋 Limitations
 
> This section includes all the limitations in terms of my understanding regarding the question and on the limited data information in response to the question 3, 5, 6, 7 and 10:

### ⚠️ **Question 3: What was the first item from the menu purchased by each customer?**
[View solution](#q3-what-was-the-first-item-from-the-menu-purchased-by-each-customer)

The limition of this question includes:

* Since the **```order_date```** information does not include details of the purchase time (hours, minute, second, etc.) and those orders purchased **on the same day** are sorted based on the **```product_id```** instead of time element, it is difficult for me to know which product is purchased first on the same day.

That's why, in this question I will sort the first purchase order by the **```product_id```**

---

### ⚠️ **Question 5: Which item was the most popular for each customer?**
[View solution](#q5-which-item-was-the-most-popular-for-each-customer)

The limition of this question includes:
* Since there is <span style="color:red">**no extra information**</span> to provide further conditions for **sorting popular items** for each customer, thus, those products have the same highest purchase counts are considered to be all popular

---

### ⚠️ **Question 6: Which item was purchased first by the customer after they became a member?**
[View solution](#q6-which-item-was-purchased-first-by-the-customer-after-they-became-a-member)

The limition of this question includes:

* Since it is not clear that those orders made during the **join_date** was <ins>**after**</ins> or <ins>**before**</ins> the customer joined in the membership program because of the lack of **```order_date```** and **```join_date```** information (does not include details of the purchase time), I will assume these orders were made after the customer had already joined the program. 
---

### ⚠️ **Question 7: Which item was purchased just before the customer became a member?**
[View solution](#q7-which-item-was-purchased-just-before-the-customer-became-a-member)

The limition of this question includes:
* Since the **```order_date```** information does not include details of the purchase time (hours, minute, second, etc.) and those orders purchased **on the same day** are sorted based on the **```product_id```** instead of time element, it is difficult for me to know which product is last purchased before the customer join in the membership program. 
 
Therefore, the result can be either 1 of those orders made during the last day before the **```join_date```**

---

### ⚠️ **Question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
[View solution](#q10-in-the-first-week-after-a-customer-joins-the-program-including-their-join-date-they-earn-2x-points-on-all-items-not-just-sushi---how-many-points-do-customer-a-and-b-have-at-the-end-of-january)

The limition of this question includes:
* Since it is not clear that the points in this question is only calculated **after the customer joins in the membership program** or not, I will also include the total points before the **```join_date```**.

---
<p>&copy; 2021 Leah Nguyen</p>


