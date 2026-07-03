-- ==================================================
-- DDL Script
-- Purpose: This Script Create tables in the silver schema
-- Warning: If same name tables already exist in the bronze schema, running script will throw an error. Drop the tables then run the script.
-- ==================================================

CREATE TABLE silver.crm_cust_info (
cst_id INT,
cst_key VARCHAR(15),
cst_firstname VARCHAR(15),
cst_lastname VARCHAR(15),
cst_marital_status VARCHAR(15) ,
cst_gndr VARCHAR(15),
cst_create_date DATE,
dwh_create_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.crm_prd_info (
prd_id INT,
cat_id varchar(20),
prd_key VARCHAR(20),
prd_nm VARCHAR(50),
prd_cost INT,
prd_line VARCHAR(15),
prd_start_dt DATE,
prd_end_dt DATE,
dwh_create_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.crm_sales_details (
sls_ord_num VARCHAR(20),
sls_prd_key VARCHAR(20),
sls_cust_id INT,
sls_order_dt DATE,
sls_ship_dt DATE,
sls_due_dt DATE,
sls_sales INT,
sls_quantity INT,
sls_price INT,
dwh_profit INT,
dwh_create_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.erp_cust_az12 (
cid VARCHAR(20),
bdate DATE,
gen VARCHAR(10),
dwh_create_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.erp_loc_a101 (
cid VARCHAR(20),
cntry VARCHAR(50),
dwh_create_date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE silver.erp_px_cat_g1v2 (
id VARCHAR(30),
cat VARCHAR(30),
subcat VARCHAR(30),
maintenance VARCHAR(30),
dwh_create_date DATETIME DEFAULT CURRENT_TIMESTAMP
);