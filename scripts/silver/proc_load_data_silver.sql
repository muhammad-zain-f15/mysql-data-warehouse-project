/* =====================================================================================
    Purpose: This script creates stored procedure to truncate and insert data from bronze->silver
    Warning: If stored procedure already exist or bronze layer is not properly setup, running script will throw error
    usage: EXEC silver.load_silver
*/

--   EXEC silver.load_silver
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	-- Load crm customer information 
	TRUNCATE TABLE silver.crm_cust_info;
	INSERT INTO silver.crm_cust_info 

	SELECT cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) AS cst_lastname,
		CASE
			UPPER(TRIM(cst_marital_status))
			when 'S' then 'Single'
			when 'M' then 'Married'
			else 'Unknown'
		END AS cst_marital_status,
		CASE
			UPPER(TRIM(cst_gndr))
			when 'F' then 'Female'
			when 'M' then 'Male'
			else 'Unknown'
		END AS cst_gndr,
		cst_create_date
	FROM (
			SELECT 
				*,
				row_number() over(PARTITION BY cst_id order by cst_create_date DESC) as flag_last
			FROM bronze.crm_cust_info
		) as sub_query
	WHERE flag_last = 1 and cst_id is not null

	-- LOAD crm product information
	TRUNCATE TABLE silver.crm_prd_info;
	INSERT INTO silver.crm_prd_info
	(
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line
	)

	select
	row_number() over(order by prd_id) as prd_id,
	category_id,
	prd_key,
	prd_nm,
	prd_cost,
	prd_line
	from
	(
	select
	prd_id,
	replace(substring(prd_key,1,5),'-','_') as category_id,
	substring(prd_key,7,len(prd_key)) as prd_key,
	prd_nm,
	isnull(prd_cost,0) as prd_cost,
	case upper(trim(prd_line))
		when 'M' then 'Mountain'
		when 'R' then 'Road'
		when 'S' then 'Other Sales'
		when 'T' then 'Touring'
	else 'unknown'
	end as prd_line,
	rank() over(partition by prd_nm order by prd_id desc) prd_rank
	from bronze.crm_prd_info
	) as subquery

	where prd_rank = 1
	order by prd_id

	-- load crm sales details 
	TRUNCATE TABLE silver.crm_sales_details;
	INSERT INTO silver.crm_sales_details

	select
	sls_ord_num,
	sls_prd_key,
	sls_cust_id,
	case when len(sls_order_dt) < 8 then null
		else cast(cast(sls_order_dt as varchar) as date) 
	end as sls_order_dt,
	case when len(sls_ship_dt) < 8 then null
		else cast(cast(sls_ship_dt as varchar) as date) 
	end as sls_ship_dt,
	case when len(sls_due_dt) < 8 then null
		else cast(cast(sls_due_dt as varchar) as date) 
	end as sls_due_dt,
	case 
		when sls_sales is null or abs(sls_sales) != abs(sls_quantity)*abs(sls_price)
		then abs(sls_quantity)*abs(sls_price)
		else abs(sls_sales)
	end as sls_sales,
	abs(sls_quantity) sls_quantity,
	case 
		when sls_quantity = 0 then 0
		when sls_price is null or sls_price <= 0
		then abs(sls_sales)/sls_quantity
		else sls_price
	end as sls_price
	from bronze.crm_sales_details 

	TRUNCATE TABLE silver.erp_cust_az12
	INSERT INTO silver.erp_cust_az12
	select
	case 
		when cid like 'NAS%'
		then substring(cid,4,len(cid))
		else cid
	end as cid,
	case 
		when bdate > getdate() then null
		else bdate
	end as bdate,
	case 
		when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
		when upper(trim(gen)) in ('M', 'MALE') then 'Male'
		else 'n/a'
	end as gen
	 from bronze.erp_cust_az12


	 TRUNCATE TABLE silver.erp_loc_a101
	 INSERT INTO silver.erp_loc_a101
	 select
		replace(cid,'-','') as cid,
		case 
			when upper(trim(cntry)) in ('US','UNITED STATES','USA') then 'United States'
			when upper(trim(cntry)) ='DE' then 'Germany'
			when cntry is null or cntry = '' then 'unknown'
			else trim(cntry)
		end as cntry
	 from bronze.erp_loc_a101

	 INSERT INTO silver.erp_px_cat_g1v2
	 select
	 id,
	 cat,
	 subcat,
	 maintenance
	 from bronze.erp_px_cat_g1v2

 END 
