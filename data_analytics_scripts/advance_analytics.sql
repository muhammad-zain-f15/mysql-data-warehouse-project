-- Analyze Sales Performance Over Time

SELECT 
	date_format(order_date,"%Y-%M") as order_date,
    sum(sales_amount) as "Sales",
    count(DISTINCT customer_key) as "Total No of Customers",
    sum(quantity) as "Total quantity"
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY date_format(order_date,"%Y-%M");

-- How many new customers were added each each
SELECT
	year(order_date) as "order_year",
    count(DISTINCT customer_key) as "No of Customers"
FROM gold.fact_sales
WHERE year(order_date) IS NOT NULL
GROUP BY year(order_date);

-- calculate the total sales per month and the running total of sales overtime

SELECT
	order_date,
    sales,
    sum(sales) over(partition by date_format(order_date,"%Y") order by order_date) as running_total
FROM
(
	SELECT
		date_format(order_date,"%Y-%m-%d") as "order_date",
		sum(sales_amount) as "sales"
	FROM gold.fact_sales
	WHERE date_format(order_date,"%Y-%m-%d") IS NOT NULL
	GROUP BY date_format(order_date,"%Y-%m-%d")
) as sub_table;

SELECT
	order_date,
    sales,
    sum(sales) over( order by order_date) as running_total,
     avg(avg_price) over( order by order_date) as moving_avg_price
FROM
(
	SELECT
		date_format(order_date,"%Y") as "order_date",
		sum(sales_amount) as "sales",
        avg(price) as avg_price
	FROM gold.fact_sales
	WHERE date_format(order_date,"%Y") IS NOT NULL
	GROUP BY date_format(order_date,"%Y")
) as sub_table;


-- Peformance Analysis
-- Analyze the yearly performance of each product by comparing with its average sale and previous year sale
WITH yearly_product_sales AS(
	SELECT 
		date_format(order_date,"%Y") as order_date,
		product_name,
		sum(sales_amount) as revenue
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON p.product_key = f.product_key
	WHERE date_format(order_date,"%Y") IS NOT NULL
	GROUP BY date_format(order_date,"%Y"),product_name
)
SELECT
	order_date,
    product_name,
    revenue,
    avg(revenue) over(PARTITION BY product_name) as "avg_revenue",
    revenue- avg(revenue) over(PARTITION BY product_name) as "diff_avg",
    case 
		when revenue- avg(revenue) over(PARTITION BY product_name)  > 0 THEN  "Above Avg"
		when revenue- avg(revenue) over(PARTITION BY product_name) < 0 Then "Below Avg"
		else "Avg"
    end as avg_flag,
    LAG(revenue) over(partition by product_name order by order_date) as "Previous year Sales",
    revenue- LAG(revenue) over(partition by product_name order by order_date) as diff_py,
    case 
		when revenue- LAG(revenue) over(partition by product_name order by order_date)   > 0 THEN  "Increase"
		when revenue- LAG(revenue) over(partition by product_name order by order_date) < 0 Then "Decrease"
		else "No Change"
    end as previous_year_flag
FROM yearly_product_sales
ORDER BY product_name,order_date ;


-- Part to whole Analysis

-- which categories contribute most to the overall sales
WITH category_sales As(
SELECT
	category,
    sum(sales_amount) as "Revenue"
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY category)

SELECT 
	category,
    Revenue,
    sum(Revenue) over() as "Total Revenue",
    concat((Revenue/sum(Revenue) over())*100,"%")as "% of Total"  
FROM category_sales;

-- Data Segmentation

-- Segment Products into categories and count how many products fall into each categories
WITH product_segment As
(
SELECT
	product_key,
    product_name,
    product_cost,
    case when product_cost <100 then "below 100"
		when product_cost <500 then "100-500"
        when product_cost < 1000 then "500-1000"
		else "Above 1000"
	end as cost_range
FROM gold.dim_products)

SELECT 
	cost_range,
    count(product_name) as "No of products"
FROM product_segment
GROUP BY cost_range
;

/* Group customers into three segments based on their spending behavior.
	VIP: Customers with at least 12 months of history and spending more than $5000
    Regular: Customer at least 12 months of history but spending less than $5000
    New: Customers with less than 12 months of lifespan
    Find total no of customers in each group.
*/
WITH customer_lifespan AS
(
SELECT
	f.customer_key,
	timestampdiff(Month,min(order_date),max(order_date)) as life_span,
    sum(sales_amount) "total_spend"
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
GROUP BY f.customer_key
),
customer_segment AS(
SELECT 
	customer_key,
	life_span,
	total_spend,
    case 
		when total_spend > 5000 and life_span >=12 then "VIP"
		when life_span >=12 then "Regular"
		else "New" 
    end as "segment"
FROM customer_lifespan
)

SELECT 
	segment,
    count(customer_key)
FROM customer_segment
GROUP BY segment;

/*
	Customer Report (Consolidate All customer key metrics and behaviors
*/

/*
1. Base query: Retrive core columns from the database
*/
CREATE VIEW gold.report_customers AS
WITH base_query AS(
SELECT
	f.customer_key,
    f.product_key,
    f.order_date,
    f.order_number,
    f.sales_amount,
    f.quantity,
    concat(c.first_name," ",c.last_name) as customer_name,
    timestampdiff(Year,birthdate,curdate()) as Age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL),

-- Customer aggregation: summarize key metrics at customer level
customer_aggregation AS
(
SELECT 
	customer_key,
	customer_name,
    age,
    count(DISTINCT order_number) as "total_orders",
    sum(sales_amount) as "total_spend",
    sum(quantity) as "total_quantity",
    count(DISTINCT product_key) as "No_of_products",
    max(order_date) as last_order,
    timestampdiff(Month,min(order_date),max(order_date)) as lifespan
FROM base_query
GROUP BY customer_key,customer_name,age)

SELECT 
	customer_key,
	customer_name,
    age,
    case 
		when total_spend > 5000 and lifespan >=12 then "VIP"
		when lifespan >=12 then "Regular"
		else "New" 
    end as "segment",
    case 
		when age < 20 then "Under 20"
        when age <=30 then "20-30"
        when age < 45 then "30-45"
        else "Above 45"
	end as age_group,
    timestampdiff(month,last_order,curdate()) as recency,
    -- compute average order value (total_sales/total_orders)
    case
		when total_orders = 0
		THEN 0
		else total_spend/total_orders 
    end as average_order_value,
    -- compute average monthly spend
    case
		when lifespan =0
		THEN total_spend
		else total_spend/lifespan 
    end as avg_monthly_spend
FROM customer_aggregation;

/*
Products Report
*/

/*
1) Base query: Pick core columns from the tables
*/
CREATE VIEW gold.report_products AS
WITH base_query AS
(
SELECT 
	f.product_key,
    product_name,
    category,
    subcategory,
    product_cost,
    customer_key,
    order_number,
    quantity,
    sales_amount,
    order_date
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key),

/*
2) Product Aggregation
*/
product_aggregation as(
SELECT 
	product_key,
    product_name,
    category,
    subcategory,
    product_cost,
    count(DISTINCT order_number) as total_orders,
    sum(sales_amount) as total_sales,
    sum(quantity) as total_quantity_sold,
    timestampdiff(month,min(order_date),max(order_date)) as lifespan,
    max(order_date) as last_sale_date,
    avg(sales_amount) as average_selling_price,
    count(DISTINCT customer_key) as total_customers
FROM base_query
GROUP BY product_key,product_name,category, subcategory,product_cost)

SELECT
	product_key,
    product_name,
    category,
    subcategory,
    product_cost,
    total_sales,
    total_orders,
    total_quantity_sold,
    lifespan,
    average_selling_price,
    total_customers,
    last_sale_date,
    case
		when total_sales < 200000 then "Low Performers"
        when total_sales < 1000000 then "Mid-Range"
        else "High-Performers"
	end as "product_segment",
    timestampdiff(month,last_sale_date,curdate()) as recency,
    -- average order value
    case
		when total_orders = 0
		THEN 0
		else total_sales/total_orders 
    end as average_order_value,
	-- compute average monthly spend
    case
		when lifespan =0
		THEN total_sales
		else total_sales/lifespan 
    end as avg_monthly_revenue
FROM product_aggregation;

SELECT 
	*
From gold.report_products;
