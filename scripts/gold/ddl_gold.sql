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
SELECT row_number() over (
        order by ci.cst_id
    ) as customer_key,
    ci.cst_id as customer_id,
    ci.cst_key customer_number,
    ci.cst_firstname first_name,
    ci.cst_lastname last_name,
    cl.cntry country,
    ci.cst_marital_status marital_status,
    case
        when ci.cst_gndr != "unknown" then ci.cst_gndr -- crm is the master table for gender Integration
        else coalesce(ca.gen, "unknown")
    end as gender,
    ca.bdate birthdate,
    ci.cst_create_date create_date
FROM silver.crm_cust_info ci
    LEFT JOIN silver.erp_cust_az12 ca ON ca.cid = ci.cst_key
    LEFT JOIN silver.erp_loc_a101 cl ON cl.cid = ci.cst_key;

-- Create Dimension Product View
CREATE VIEW gold.dim_products AS
SELECT ROW_NUMBER () over (
        order by prd_info.prd_start_dt,
            prd_info.prd_key
    ) as product_key,
    prd_info.cat_id as category_id,
    cat_info.cat category,
    cat_info.subcat subcategory,
    prd_info.prd_id AS product_id,
    prd_info.prd_key product_number,
    prd_info.prd_nm product_name,
    prd_info.prd_cost product_cost,
    prd_info.prd_line product_line,
    prd_info.prd_start_dt start_date,
    prd_info.prd_end_dt end_date,
    cat_info.maintenance
FROM silver.crm_prd_info as prd_info
    LEFT JOIN silver.erp_px_cat_g1v2 cat_info ON cat_info.id = prd_info.cat_id
WHERE prd_info.prd_end_dt is NULL;

-- Create Fact Sales View
CREATE VIEW gold.fact_sales as
SELECT sls_ord_num order_number,
    dp.product_key,
    dc.customer_key,
    sls_order_dt order_date,
    sls_ship_dt ship_date,
    sls_due_dt due_date,
    sls_sales sales_amount,
    sls_quantity quantity,
    sls_price price
FROM silver.crm_sales_details as sales
    LEFT JOIN gold.dim_customers dc ON dc.customer_id = sales.sls_cust_id
    LEFT JOIN gold.dim_products dp ON dp.product_number = sales.sls_prd_key;

