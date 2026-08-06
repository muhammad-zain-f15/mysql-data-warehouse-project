/*
-- ==================================================
-- DDL Script
-- Purpose: This Script Create views in the gold schema
    Gold Layer represent final dimension and fact tables (star Schema)

    Each view perform transformation and join multiple tables from silver layer and produce clean,
    enriched and business-ready data
    
-- Warning: If same name views already exist in the gold schema, running script will throw an error. Drop the views then run the script.
-- ==================================================
*/

-- Create Dimension Customer View
CREATE VIEW gold.dim_customers AS
select
row_number() over(order by cst_id) as customer_key,
a.cst_id as customer_id,
cst_firstname first_name,
cst_lastname last_name,
cst_marital_status marital_status,
case when cst_gndr != 'unknown' then cst_gndr
else coalesce(gen,'unknown')
end as gender,
cntry country,
bdate birthdate,
cst_create_date create_date
FROM silver.crm_cust_info a
join silver.erp_cust_az12 b
on a.cst_key = b.cid
join silver.erp_loc_a101 c
on a.cst_key = c.cid;

-- Create Dimension Product View
CREATE VIEW gold.dim_products AS
select distinct
prd_id product_key,
cat_id as category_id,
cat as category,
subcat as subcategory,
prd_key as product_number,
prd_nm as product_name,
prd_cost product_cost,
prd_line product_line,                                
maintenance
from silver.crm_prd_info pi
left join silver.erp_px_cat_g1v2 ci 
on pi.cat_id = ci.id ;

-- Create Fact Sales View
CREATE VIEW gold.fact_sales As
select
sls_ord_num as order_number,
customer_key,
product_key,
sls_order_dt order_date,
sls_ship_dt ship_date,
sls_due_dt due_date,
sls_quantity quantity,
sls_price price,
sls_sales sales,
p.product_cost,
(sls_sales-(p.product_cost*sls_quantity)) as profit
from silver.crm_sales_details s
join gold.dim_customers c on s.sls_cust_id = c.customer_id
join gold.dim_products p on s.sls_prd_key = p.product_number;


