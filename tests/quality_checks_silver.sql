-- ==============================================
-- Checking silver.crm_cust_info
-- ==============================================
-- Check for nulls or duplicates in Primary key
-- Exprected Result: No output
SELECT cst_id,
    count(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING count(*) > 1;
-- Check for unwanted spaces in string values
-- Exprected Result: No output
SELECT cst_firstname,
    cst_lastname
FROM silver.crm_cust_info
where cst_firstname <> TRIM(cst_firstname)
    or cst_lastname <> TRIM(cst_lastname);
-- Data Standardization and Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info;
-- ==============================================
-- Checking silver.crm_prd_info
-- ==============================================
-- check for negative numbers
-- result : no output
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0;
-- Data Standardization and Consistency
SELECT distinct prd_line
FROM silver.crm_prd_info;
-- check for invalid dates
-- result: No output
SELECT *
from silver.crm_prd_info
where prd_start_dt > prd_end_dt;
-- ==============================================
-- Checking silver.crm_sales_details
-- ==============================================
-- Check Date Consistency
select sls_order_dt
from
silver.crm_sales_details;

-- ==============================================
-- Checking silver.erp_cust_az12
-- ==============================================
-- invalid birth dates
select 
bdate
from 
silver.erp_cust_az12
where bdate > current_date() ;
-- standardization and consistency
select 
DISTINCT gen
from
silver.erp_cust_az12;
-- ==============================================
-- Checking silver.erp_loc_a101
-- ==============================================
-- standardization and normalization
select
DISTINCT cntry
from silver.erp_loc_a101;
-- ==============================================
-- Checking silver.erp_px_cat_g1v2
-- ==============================================
-- Data standardization and consistency
select DISTINCT maintenance
from bronze.erp_px_cat_g1v2;
-- unwanted spaces
SELECT cat,subcat
from bronze.erp_px_cat_g1v2
where cat <> trim(cat) or subcat <> trim(subcat);