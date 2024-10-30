# Monday-Coffee
![MondayCoffee](https://github.com/Navn33t2k1/Monday-Coffee/blob/main/1.png)
# Objectives:
The business aims to expand by opening three coffee shops in India's top three major cities. Since its launch in January 2023, the company has successfully sold its products online and received an overwhelmingly
positive response in several cities. As a data analyst, My task is to analyze the sales data and provide insights to recommend the top three cities for this expansion.

## Schema
```sql
CREATE TABLE city
(
city_id INT PRIMARY KEY,
city_name VARCHAR(15),
population BIGINT,
estimated_rent FLOAT,
city_rank INT
);

CREATE TABLE customers
(
customer_id INT PRIMARY KEY,
customer_name VARCHAR(25),
city_id INT,
CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);

CREATE TABLE products
(
product_id INT PRIMARY KEY,
product_name VARCHAR(35),
price FLOAT
);

CREATE TABLE sales
(
sale_id INT PRIMARY KEY,
sale_date DATE,
product_id INT,
customer_id INT,
total FLOAT,
rating INT,
CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
```
### Getting Overview of dataset.

```sql
SELECT *
FROM city;

SELECT *
FROM products;

SELECT *
FROM customers;

SELECT *
FROM sales;
```

## Reports  & Data Analysis.
### 1. How many people in each city are estimated to consume coffee, given that 25% of the population does?
```sql
SELECT city_name, ROUND((population*0.25)/1000000, 2) AS coffee_consumers_in_millions, city_rank
FROM city
ORDER BY 2 DESC;
```

### 2. What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
```sql
WITH quarter AS (SELECT *, EXTRACT(YEAR FROM sale_date) AS year,
EXTRACT(quarter FROM sale_date) AS qtr
FROM sales s
INNER JOIN customers c
on s.customer_id= c.customer_id
INNER JOIN city ct
on c.city_id=ct.city_id)
SELECT city_name, SUM(total) AS total_revenue
FROM quarter
WHERE year=2023 AND qtr=4
GROUP BY 1
ORDER BY 2 DESC;
```

### 3. How many units of each coffee product have been sold?
```sql
SELECT p.product_name, COUNT(s.sale_id) AS no_of_units
FROM products p
LEFT JOIN sales s
ON p.product_id=s.product_id
GROUP BY 1
ORDER BY 2 DESC;
```

### 4. What is the average sales amount per customer in each city?
```sql
SELECT ci.city_name, COUNT(DISTINCT c.customer_id) AS total_customers, SUM(s.total) AS total_amount,
ROUND(SUM(s.total)::NUMERIC/COUNT(DISTINCT c.customer_id), 2)::NUMERIC AS Avg_sale_pr_cust
FROM city ci
INNER JOIN customers c
ON ci.city_id= c.city_id
INNER JOIN sales s
ON c.customer_id=s.customer_id
GROUP BY 1
ORDER BY 3 DESC;
```

### 5. Provide a list of cities along with their populations and estimated coffee consumers.
### Return city_name, total current customers, estimated coffee consumers (25%).
```sql
WITH city_table AS (SELECT city_name, ROUND((population*0.25)/1000000, 2) AS coffee_consumers
FROM city),

unique_customer_table AS (
SELECT ci.city_name, COUNT(DISTINCT c.customer_id) AS unique_customer
FROM sales s
JOIN customers c
ON c.customer_id=s.customer_id
JOIN city AS ci
ON ci.city_id=c.city_id
GROUP BY 1)

SELECT ct.city_name, ct.coffee_consumers AS coffee_consumer_in_millions, uct.unique_customer
FROM city_table ct
JOIN unique_customer_table uct
ON ct.city_name=uct.city_name;
```

### 6. What are the top 3 selling products in each city based on sales volume?
```sql
SELECT *
FROM (SELECT ci.city_name, p.product_name, COUNT(s.sale_id) AS total_order, DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS ranks
FROM city ci
JOIN customers c
ON ci.city_id=c.city_id
JOIN sales s
ON c.customer_id=s.customer_id
JOIN products p
ON s.product_id=p.product_id
GROUP BY 1,2
ORDER BY 1, 3 DESC) AS t1
WHERE RANKS<=3;
```

### 7. How many unique customers are there in each city who have purchased coffee products?
```sql
WITH coffee AS (SELECT *
FROM products
LIMIT 14)

SELECT ci.city_name, COUNT(DISTINCT c.customer_id) AS customer_count
FROM city ci
JOIN customers c
ON ci.city_id=c.city_id
JOIN sales s
ON c.customer_id=s.customer_id
JOIN coffee co
ON s.product_id=co.product_id
GROUP BY 1;
```

### 8. Find each city and their average sale per customer and avg rent per customer.
```sql
WITH city_table AS
(SELECT ci.city_name, COUNT(DISTINCT c.customer_id) AS total_customers,
ROUND(SUM(s.total)::NUMERIC/COUNT(DISTINCT c.customer_id), 2)::NUMERIC AS Avg_sale_pr_cust
FROM city ci
INNER JOIN customers c
ON ci.city_id= c.city_id
INNER JOIN sales s
ON c.customer_id=s.customer_id
GROUP BY 1
ORDER BY 3 DESC),

city_rent AS
(
SELECT city_name, estimated_rent
FROM city
)

SELECT cr.city_name, ct.avg_sale_pr_cust, ROUND(cr.estimated_rent::numeric/ct.total_customers::numeric, 2) AS avg_rent_pr_cust
FROM city_rent cr
JOIN city_table ct
ON cr.city_name=ct.city_name;
```

### 9. Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
```sql
WITH monthly_sales AS
(
SELECT ci.city_name, EXTRACT(MONTH FROM s.sale_date) AS month, EXTRACT(YEAR FROM s.sale_date) AS year ,
SUM(s.total) AS total_sale_pr_month
FROM sales s
JOIN customers cust
on s.customer_id=cust.customer_id
JOIN city ci
ON cust.city_id=ci.city_id
GROUP BY 1, 3, 2
ORDER BY 1,3, 2
),
growth_ratio
AS
(
SELECT city_name, month, year, total_sale_pr_month, LAG(total_sale_pr_month, 1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
FROM monthly_sales
)
SELECT city_name, month, year, total_sale_pr_month, last_month_sale, ROUND((total_sale_pr_month-last_month_sale)::NUMERIC/total_sale_pr_month::NUMERIC*100, 2) AS growth_ratio_pr_month
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;
```

### 10. Market Potential Analysis: Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumers.
```sql
WITH city_table AS
(SELECT ci.city_name, COUNT(DISTINCT c.customer_id) AS total_customers, SUM(s.total) AS total_revenue,
ROUND(SUM(s.total)::NUMERIC/COUNT(DISTINCT c.customer_id), 2)::NUMERIC AS Avg_sale_pr_cust
FROM city ci
INNER JOIN customers c
ON ci.city_id= c.city_id
INNER JOIN sales s
ON c.customer_id=s.customer_id
GROUP BY 1
ORDER BY 3 DESC),

city_rent AS
(
SELECT city_name, estimated_rent, ROUND((population*0.25)/1000000, 2) AS estimated_coffee_consumers_in_millions
FROM city
)

SELECT cr.city_name, ct.total_revenue, cr.estimated_rent AS total_rent, ct.total_customers, ct.avg_sale_pr_cust, ROUND(cr.estimated_rent::numeric/ct.total_customers::numeric, 2) AS avg_rent_pr_cust, cr.estimated_coffee_consumers_in_millions
FROM city_rent cr
JOIN city_table ct
ON cr.city_name=ct.city_name
ORDER BY 2 DESC;
```
## Recomendation:
**City 1: Pune**
* Avg rent per customer is very less.
* Highest total revenue.
* Avg_sale_pr_customer is also high.
 #
**City 2: Delhi**
* Highest estimated coffee consumers which is 7.7M.
* Highest total customer which is 68.
* Avg rent per customer 330 (still under 500).
 #
**City 3: Jaipur**
* Highest customer no. which is 69.
* Avg rent per customer is very less 156.
* Avg sale per customer is better which at 11.6K.
