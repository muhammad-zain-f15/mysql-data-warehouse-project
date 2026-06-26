-- Check for nulls or duplicates in Primary key
-- Exprected Result: No output

SELECT cst_id,count(*)
FROM
bronze.crm_cust_info
GROUP BY 
HAVING count(*) > 1;

-- Check for unwanted spaces in string values
-- Exprected Result: No output

SELECT cst_firstname,cst_lastname
FROM bronze.crm_cust_info
where cst_firstname <> TRIM(cst_firstname)
or cst_lastname <> TRIM(cst_lastname);

-- Data Standardization and ConsistencySELECT DISTINCT cst_gndr
From bronze.crm_cust_info
WHERE cst_gndr IS NULL;