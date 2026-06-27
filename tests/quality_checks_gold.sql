-- ==============================================
-- Purpose: This script performs various quality checks on gold schema views

-- ==============================================

-- ==============================================
-- Checking gold.dim_products
-- ==============================================
SELECT product_key, count(*)
From
gold.dim_products
group by product_key
Having count(*) > 1
;

-- ==============================================
-- Checking gold.fact_sales
-- ==============================================


SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
where p.product_key is NULL;