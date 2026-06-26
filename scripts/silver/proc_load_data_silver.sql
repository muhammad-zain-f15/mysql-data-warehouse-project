/* =====================================================================================
    Purpose: This script creates stored procedure to truncate and insert data from bronze->silver
    Warning: If stored procedure already exist or bronze layer is not properly setup, running script will throw error
    MySql Example usage: call silver.load_crm_cust_info();
*/
-- load crm_cust_info data
DELIMITER // CREATE PROCEDURE silver.load_crm_cust_info() BEGIN TRUNCATE TABLE silver.crm_cust_info;
INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
SELECT sub_table.cst_id,
    sub_table.cst_key,
    TRIM(sub_table.cst_firstname) AS cst_firstname,
    TRIM(sub_table.cst_lastname) AS cst_lastname,
    CASE
        UPPER(TRIM(sub_table.cst_marital_status))
        when 'S' then "Single"
        when "M" then "Married"
        else "Unknown"
    END AS cst_marital_status,
    CASE
        UPPER(TRIM(sub_table.cst_gndr))
        when 'F' then "Female"
        when "M" then "Male"
        else "Unknown"
    END AS cst_gndr,
    sub_table.cst_create_date
FROM (
        SELECT *,
            row_number() over(
                PARTITION BY cst_id
                order by cst_create_date DESC
            ) as flag_last
        FROM bronze.crm_cust_info
    ) as sub_table
WHERE sub_table.flag_last = 1
    and sub_table.cst_id <> 0;
END // DELIMITER;

-- load crm_prd_info data
DELIMITER // CREATE PROCEDURE silver.load_crm_prd_info() BEGIN TRUNCATE TABLE silver.crm_prd_info;
INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
SELECT prd_id,
    REPLACE(substring(prd_key, 1, 5), '-', '_') As cat_id,
    SUBSTRING(prd_key, 7, length(prd_key)) As prd_key,
    prd_nm,
    prd_cost,
    CASE
        upper(trim(prd_line))
        when 'M' then "Mountain"
        when "R" then "Road"
        when "S" then "Other Sales"
        when "T" then "Touring"
        else "n/a"
    end as prd_line,
    prd_start_dt,
    date_sub(
        LEAD(prd_start_dt) over (
            partition by prd_key
            order by prd_start_dt ASC
        ),
        INTERVAL 1 DAY
    ) as prd_end_dt -- calculate end date as one day before the next start date
FROM bronze.crm_prd_info;
END // DELIMITER;

-- load crm_sales_details data
DELIMITER // CREATE PROCEDURE silver.load_crm_sales_details() BEGIN TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_price,
        sls_quantity,
        sls_sales
    )
SELECT bronze_table.sls_ord_num,
    bronze_table.sls_prd_key,
    bronze_table.sls_cust_id,
    cast(bronze_table.sls_order_dt as Date),
    cast(bronze_table.sls_ship_dt as Date),
    cast(bronze_table.sls_due_dt as Date),
    bronze_table.sls_price,
    bronze_table.sls_quantity,
    case
        when bronze_table.sls_sales <= 0
        or bronze_table.sls_sales <> bronze_table.sls_price * bronze_table.sls_quantity then bronze_table.sls_price * bronze_table.sls_quantity
        else bronze_table.sls_sales
    end as sls_sales
from (
        SELECT sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            case
                sls_order_dt
                when 0 then NULL
                when length(sls_order_dt) <> 8 then NULL
                else cast(sls_ship_dt as CHAR)
            end as sls_order_dt,
            case
                sls_ship_dt
                when 0 then NULL
                when length(sls_ship_dt) <> 8 then NULL
                else cast(sls_ship_dt as CHAR)
            end as sls_ship_dt,
            case
                sls_due_dt
                when 0 then NULL
                when length(sls_due_dt) <> 8 then NULL
                else cast(sls_due_dt as CHAR)
            end as sls_due_dt,
            sls_sales,
            sls_quantity,
            case
                when sls_price <= 0 then sls_sales / NULLIF(sls_quantity, 0)
                else sls_price
            end as sls_price
        FROM bronze.crm_sales_details
    ) AS bronze_table;
END // DELIMITER;

-- load erp_cust_az12 data
DELIMITER // CREATE PROCEDURE silver.load_erp_cust_az12() BEGIN TRUNCATE TABLE silver.erp_cust_az12;
INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
select case
        when cid like 'NAS%' then substring(cid, 4, length(cid))
        else cid
    end as cid,
    case
        when bdate > current_date() then NULL
        else bdate
    end as bdate,
    case
        when upper(trim(gen)) in ("M", "Male") then "Male"
        when upper(trim(gen)) in ("F", "Female") then "Female"
        else "unknown"
    end as gen
from bronze.erp_cust_az12;
END // DELIMITER;

-- load erp_loc_a101 data
DELIMITER // CREATE PROCEDURE silver.load_erp_loc_a101() BEGIN TRUNCATE TABLE silver.erp_loc_a101;
INSERT INTO silver.erp_loc_a101 (cid, cntry)
select replace(cid, '-', '') as cid,
    case
        when UPPER(TRIM(cntry)) in ("US", "USA", "UNITED STATES") then "United States"
        when UPPER(TRIM(cntry)) = "DE" then "Germany"
        when UPPER(TRIM(cntry)) = "" then "n/a"
        else Trim(cntry)
    end as cntry
from bronze.erp_loc_a101;
END // DELIMITER;

-- load erp_px_cat_g1v2 data
DELIMITER // CREATE PROCEDURE silver.load_erp_px_cat_g1v2() BEGIN TRUNCATE TABLE silver.erp_px_cat_g1v2;
INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
SELECT id,
    cat,
    subcat,
    maintenance
from bronze.erp_px_cat_g1v2;
END // DELIMITER;