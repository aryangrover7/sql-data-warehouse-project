/*
================================================================================
Script Name:    bronze_tests.sql
Description:    Data quality tests for the Bronze layer of the DataWarehouse.

                The tests validate:
                - NULL values in important columns
                - Duplicate records
                - Data completeness
                - Invalid or unexpected values
                - Basic data consistency

                Bronze data should remain as close as possible to the source
                data, so these tests focus mainly on source-data quality.

Tables Tested:
                CRM:
                - bronze.crm_cust_info
                - bronze.crm_prd_info
                - bronze.crm_sales_details

                ERP:
                - bronze.erp_loc_a101
                - bronze.erp_cust_az12
                - bronze.erp_px_cat_g1v2

Author:         Aryan Grover
================================================================================
*/


-- ============================================================================
-- CRM CUSTOMER INFORMATION
-- ============================================================================

-- Check for NULL customer IDs.
SELECT *
FROM bronze.crm_cust_info
WHERE cst_id IS NULL;


-- Check for duplicate customer IDs.
SELECT 
    cst_id,
    COUNT(*) AS duplicate_count
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;


-- Check for NULL customer keys.
SELECT *
FROM bronze.crm_cust_info
WHERE cst_key IS NULL;


-- Check for NULL customer creation dates.
SELECT *
FROM bronze.crm_cust_info
WHERE cst_create_date IS NULL;


-- Check for unexpected marital status values.
SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;


-- Check for unexpected gender values.
SELECT DISTINCT cst_gender
FROM bronze.crm_cust_info;



-- ============================================================================
-- CRM PRODUCT INFORMATION
-- ============================================================================

-- Check for NULL product IDs.
SELECT *
FROM bronze.crm_prd_info
WHERE prd_id IS NULL;


-- Check for duplicate product IDs.
SELECT 
    prd_id,
    COUNT(*) AS duplicate_count
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;


-- Check for NULL product keys.
SELECT *
FROM bronze.crm_prd_info
WHERE prd_key IS NULL;


-- Check for NULL product names.
SELECT *
FROM bronze.crm_prd_info
WHERE prd_nm IS NULL;


-- Check for negative product costs.
SELECT *
FROM bronze.crm_prd_info
WHERE prd_cost < 0;


-- Check for unexpected product line values.
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;



-- ============================================================================
-- CRM SALES DETAILS
-- ============================================================================

-- Check for NULL order numbers.
SELECT *
FROM bronze.crm_sales_details
WHERE sls_ord_num IS NULL;


-- Check for NULL product keys.
SELECT *
FROM bronze.crm_sales_details
WHERE sls_prd_key IS NULL;


-- Check for NULL customer IDs.
SELECT *
FROM bronze.crm_sales_details
WHERE sls_cust_id IS NULL;


-- Check for invalid sales values.
SELECT *
FROM bronze.crm_sales_details
WHERE sls_sales <= 0;


-- Check for invalid quantities.
SELECT *
FROM bronze.crm_sales_details
WHERE sls_quantity <= 0;


-- Check for invalid prices.
SELECT *
FROM bronze.crm_sales_details
WHERE sls_price <= 0;


-- Check for invalid date values.
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt = 0
   OR sls_ship_dt = 0
   OR sls_due_dt = 0;



-- ============================================================================
-- ERP CUSTOMER INFORMATION
-- ============================================================================

-- Check for NULL customer IDs.
SELECT *
FROM bronze.erp_cust_az12
WHERE cid IS NULL;


-- Check for duplicate customer IDs.
SELECT 
    cid,
    COUNT(*) AS duplicate_count
FROM bronze.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;


-- Check for future birth dates.
SELECT *
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE();


-- Check for unexpected gender values.
SELECT DISTINCT gen
FROM bronze.erp_cust_az12;



-- ============================================================================
-- ERP CUSTOMER LOCATION
-- ============================================================================

-- Check for NULL customer IDs.
SELECT *
FROM bronze.erp_loc_a101
WHERE cid IS NULL;


-- Check for duplicate customer IDs.
SELECT 
    cid,
    COUNT(*) AS duplicate_count
FROM bronze.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1;


-- Check for NULL country values.
SELECT *
FROM bronze.erp_loc_a101
WHERE cntry IS NULL;


-- Check for unexpected country values.
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101;



-- ============================================================================
-- ERP PRODUCT CATEGORY
-- ============================================================================

-- Check for NULL IDs.
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE id IS NULL;


-- Check for duplicate IDs.
SELECT 
    id,
    COUNT(*) AS duplicate_count
FROM bronze.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;


-- Check for NULL category values.
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat IS NULL;


-- Check for NULL category strings.
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE TRIM(cat) = '';


-- Check for unexpected category formatting.
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat NOT LIKE '%,%,%';
