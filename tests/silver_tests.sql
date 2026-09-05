/*
================================================================================
Script Name:    silver_tests.sql
Description:    Data quality and transformation tests for the Silver layer
                of the DataWarehouse.

                The tests validate:
                - NULL values
                - Duplicate records
                - Data consistency
                - Data standardization
                - CASE WHEN transformations
                - Date transformations
                - Business-rule transformations
                - Referential consistency between Silver tables

Tables Tested:
                CRM:
                - silver.crm_cust_info
                - silver.crm_prd_info
                - silver.crm_sales_details

                ERP:
                - silver.erp_loc_a101
                - silver.erp_cust_az12
                - silver.erp_px_cat_g1v2

Author:         Aryan Grover
================================================================================
*/


-- ============================================================================
-- CRM CUSTOMER INFORMATION
-- ============================================================================

-- Check for NULL customer IDs.
SELECT *
FROM silver.crm_cust_info
WHERE cst_id IS NULL;


-- Check for duplicate customer IDs.
SELECT 
    cst_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;


-- Check for NULL customer keys.
SELECT *
FROM silver.crm_cust_info
WHERE cst_key IS NULL;


-- Check that first names do not contain leading/trailing spaces.
SELECT *
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname);


-- Check that last names do not contain leading/trailing spaces.
SELECT *
FROM silver.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname);


-- Check marital status transformation.
-- Only Single, Married, or n/a should exist.
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a');


-- Check gender transformation.
-- Only Female, Male, or n/a should exist.
SELECT DISTINCT cst_gender
FROM silver.crm_cust_info
WHERE cst_gender NOT IN ('Female', 'Male', 'n/a');


-- Check for NULL customer creation dates.
SELECT *
FROM silver.crm_cust_info
WHERE cst_create_date IS NULL;



-- ============================================================================
-- CRM PRODUCT INFORMATION
-- ============================================================================

-- Check for NULL product IDs.
SELECT *
FROM silver.crm_prd_info
WHERE prd_id IS NULL;


-- Check for duplicate product IDs.
SELECT 
    prd_id,
    COUNT(*) AS duplicate_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1;


-- Check for NULL product keys.
SELECT *
FROM silver.crm_prd_info
WHERE prd_key IS NULL;


-- Check that product cost is not negative.
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost < 0;


-- Check product line transformation.
-- Only the standardized values should exist.
SELECT DISTINCT prd_line
FROM silver.crm_prd_info
WHERE prd_line NOT IN
(
    'Mountain',
    'Road',
    'Other Sales',
    'Touring',
    'n/a'
);


-- Check that category IDs use underscores instead of hyphens.
SELECT *
FROM silver.crm_prd_info
WHERE cat_id LIKE '%-%';


-- Check product start dates.
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt IS NULL;


-- Check product date consistency.
-- End date should not be earlier than start date.
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;



-- ============================================================================
-- CRM SALES DETAILS
-- ============================================================================

-- Check for NULL order numbers.
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL;


-- Check for NULL product keys.
SELECT *
FROM silver.crm_sales_details
WHERE sls_prd_key IS NULL;


-- Check for NULL customer IDs.
SELECT *
FROM silver.crm_sales_details
WHERE sls_cust_id IS NULL;


-- Check for invalid sales values.
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales <= 0;


-- Check for invalid quantities.
SELECT *
FROM silver.crm_sales_details
WHERE sls_quantity <= 0;


-- Check for invalid prices.
SELECT *
FROM silver.crm_sales_details
WHERE sls_price <= 0;


-- Check sales consistency.
-- Sales should equal quantity multiplied by price.
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * ABS(sls_price);


-- Check date consistency.
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_ship_dt > sls_due_dt;



-- ============================================================================
-- ERP CUSTOMER INFORMATION
-- ============================================================================

-- Check for NULL customer IDs.
SELECT *
FROM silver.erp_cust_az12
WHERE cid IS NULL;


-- Check for duplicate customer IDs.
SELECT 
    cid,
    COUNT(*) AS duplicate_count
FROM silver.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;


-- Check that future birth dates were removed.
SELECT *
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();


-- Check gender transformation.
-- Only Female, Male, or n/a should exist.
SELECT DISTINCT gen
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Female', 'Male', 'n/a');


-- Check that NAS prefix has been removed from customer IDs.
SELECT *
FROM silver.erp_cust_az12
WHERE cid LIKE 'NAS%';



-- ============================================================================
-- ERP CUSTOMER LOCATION
-- ============================================================================

-- Check for NULL customer IDs.
SELECT *
FROM silver.erp_loc_a101
WHERE cid IS NULL;


-- Check that hyphens have been removed from customer IDs.
SELECT *
FROM silver.erp_loc_a101
WHERE cid LIKE '%-%';


-- Check country transformation.
SELECT DISTINCT cntry
FROM silver.erp_loc_a101;


-- Check that standardized country names are correct.
SELECT *
FROM silver.erp_loc_a101
WHERE cntry NOT IN
(
    'Germany',
    'United States',
    'n/a'
)
AND cntry IS NOT NULL;



-- ============================================================================
-- ERP PRODUCT CATEGORY
-- ============================================================================

-- Check for NULL IDs.
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE id IS NULL;


-- Check for duplicate IDs.
SELECT 
    id,
    COUNT(*) AS duplicate_count
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;


-- Check for NULL category values.
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat IS NULL;


-- Check for NULL subcategory values.
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE subcat IS NULL;


-- Check for NULL maintenance values.
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE maintenance IS NULL;


-- Check that category fields do not contain the original comma-separated
-- structure after transformation.
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat LIKE '%,%'
   OR subcat LIKE '%,%'
   OR maintenance LIKE '%,%';



-- ============================================================================
-- DATA CONSISTENCY BETWEEN SILVER TABLES
-- ============================================================================

-- Check that every sales customer exists in the Silver customer table.
SELECT DISTINCT
    s.sls_cust_id
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_cust_info c
    ON s.sls_cust_id = c.cst_id
WHERE c.cst_id IS NULL;


-- Check that every sales product exists in the Silver product table.
SELECT DISTINCT
    s.sls_prd_key
FROM silver.crm_sales_details s
LEFT JOIN silver.crm_prd_info p
    ON s.sls_prd_key = p.prd_key
WHERE p.prd_key IS NULL;


-- Check that ERP customer IDs exist in either CRM customer information
-- or ERP customer information.
SELECT DISTINCT
    l.cid
FROM silver.erp_loc_a101 l
LEFT JOIN silver.erp_cust_az12 c
    ON l.cid = c.cid
WHERE c.cid IS NULL;
