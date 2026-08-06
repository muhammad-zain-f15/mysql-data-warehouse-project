-- ==================================================
-- DDL Script
-- Purpose: For the silver Schema, Create 6 tables
-- ==================================================
IF OBJECT_ID('silver.crm_cust_info','U') IS NOT NULL
	DROP TABLE silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
	cst_id INT,
	cst_key VARCHAR(50),
	cst_firstname VARCHAR(50),
	cst_lastname VARCHAR(50),
	cst_marital_status VARCHAR(50) ,
	cst_gndr VARCHAR(50),
	cst_create_date DATE
);

IF OBJECT_ID('silver.crm_prd_info','U') IS NOT NULL
	DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
	prd_id INT,
	cat_id nvarchar(50),
	prd_key VARCHAR(20),
	prd_nm VARCHAR(50),
	prd_cost INT,
	prd_line VARCHAR(50)
);

IF OBJECT_ID('silver.crm_sales_details','U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details (
	sls_ord_num VARCHAR(20),
	sls_prd_key VARCHAR(20),
	sls_cust_id INT,
	sls_order_dt DATE,
	sls_ship_dt DATE,
	sls_due_dt DATE,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT
);
IF OBJECT_ID('silver.erp_cust_az12') IS NOT NULL
	DROP TABLE silver.erp_cust_az12;
CREATE TABLE silver.erp_cust_az12 (
	cid VARCHAR(20),
	bdate DATE,
	gen VARCHAR(10)
);

IF OBJECT_ID('silver.erp_loc_a101') IS NOT NULL
	DROP TABLE silver.erp_loc_a101;
CREATE TABLE silver.erp_loc_a101 (
	cid VARCHAR(20),
	cntry VARCHAR(50)
);

IF OBJECT_ID('silver.erp_px_cat_g1v2') IS NOT NULL 
	DROP TABLE silver.erp_px_cat_g1v2

CREATE TABLE silver.erp_px_cat_g1v2 (
id VARCHAR(30),
cat VARCHAR(30),
subcat VARCHAR(30),
maintenance VARCHAR(30)
);
