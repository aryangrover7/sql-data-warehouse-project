```sql
/*
================================================================================
Script Name:    gold_tests.sql
Description:    Data quality and validation tests for the Gold layer of the
                DataWarehouse.

                The tests validate:
                - NULL values
                - Duplicate records
                - Data consistency
                - Dimension uniqueness
                - Transformation and integration logic
                - Referential integrity between fact and dimension views
                - Business-rule consistency

Objects Tested:
                Dimensions:
                - gold.dim_customers
                - gold.dim_products

                Fact:
                - gold.fact_sales

Author:         Aryan Grover
================================================================================
*/


USE DataWarehouse;
GO


-- ============================================================================
-- CUSTOMER DIMENSION
-- ============================================================================

-- Check for NULL customer keys.
-- Every customer should have a generated surrogate key.
SELECT *
FROM gold.dim_customers
WHERE customer_key IS NULL;


-- Check for duplicate customer surrogate keys.
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- Check for duplicate customer IDs.
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Check for NULL customer IDs.
SELECT *
FROM gold.dim_customers
WHERE customer_id IS NULL;


-- Check for NULL customer numbers.
SELECT *
FROM gold.dim_customers
WHERE customer_number IS NULL;


-- Check for NULL customer names.
SELECT *
FROM gold.dim_customers
WHERE first_name IS NULL
   OR last_name IS NULL;


-- Check gender standardization.
-- Only Female, Male, or n/a should exist.
SELECT DISTINCT gender
FROM gold.dim_customers
WHERE gender NOT IN ('Female', 'Male', 'n/a');


-- Check marital status standardization.
SELECT DISTINCT marital_status
FROM gold.dim_customers
WHERE marital_status NOT IN ('Single', 'Married', 'n/a');


-- Check for future birth dates.
SELECT *
FROM gold.dim_customers
WHERE birth_date > GETDATE();


-- Check customer integration between CRM and ERP gender.
-- CRM should be the master source when its gender is available.
SELECT DISTINCT
    ci.cst_gender AS crm_gender,
    ca.gen AS erp_gender,
    cu.gender AS gold_gender
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN gold.dim_customers cu
    ON ci.cst_id = cu.customer_id
WHERE cu.gender <>
    CASE
        WHEN ci.cst_gender != 'n/a' THEN ci.cst_gender
        ELSE COALESCE(ca.gen, 'n/a')
    END;


-- Check customer country integration.
-- Gold country should match the ERP location data.
SELECT *
FROM gold.dim_customers cu
LEFT JOIN silver.erp_loc_a101 la
    ON cu.customer_number = la.cid
WHERE cu.country <> la.cntry
   OR (cu.country IS NULL AND la.cntry IS NOT NULL)
   OR (cu.country IS NOT NULL AND la.cntry IS NULL);



-- ============================================================================
-- PRODUCT DIMENSION
-- ============================================================================

-- Check for NULL product keys.
-- Every product should have a generated surrogate key.
SELECT *
FROM gold.dim_products
WHERE product_key IS NULL;


-- Check for duplicate product surrogate keys.
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-- Check for duplicate active product numbers.
SELECT
    product_number,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_number
HAVING COUNT(*) > 1;


-- Check for NULL product IDs.
SELECT *
FROM gold.dim_products
WHERE product_id IS NULL;


-- Check for NULL product numbers.
SELECT *
FROM gold.dim_products
WHERE product_number IS NULL;


-- Check for NULL product names.
SELECT *
FROM gold.dim_products
WHERE product_name IS NULL;


-- Check that only active products are present.
-- Historical products should have been filtered out.
SELECT *
FROM gold.dim_products
WHERE end_date IS NOT NULL;


-- Check that product start dates are not NULL.
SELECT *
FROM gold.dim_products
WHERE start_date IS NULL;


-- Check that end dates are not earlier than start dates.
SELECT *
FROM gold.dim_products
WHERE end_date < start_date;


-- Check product maintenance values against Silver.
SELECT DISTINCT
    maintenance
FROM gold.dim_products
WHERE maintenance IS NULL;


-- Check product category integration.
-- Gold category information should match the ERP product category data.
SELECT *
FROM gold.dim_products p
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON p.category_id = pc.id
WHERE p.category <> pc.cat
   OR p.subcategory <> pc.subcat
   OR p.maintenance <> pc.maintenance;



-- ============================================================================
-- SALES FACT
-- ============================================================================

-- Check for NULL order numbers.
SELECT *
FROM gold.fact_sales
WHERE order_number IS NULL;


-- Check for NULL customer surrogate keys.
SELECT *
FROM gold.fact_sales
WHERE customer_key IS NULL;


-- Check for NULL product surrogate keys.
SELECT *
FROM gold.fact_sales
WHERE product_key IS NULL;


-- Check for invalid sales amounts.
SELECT *
FROM gold.fact_sales
WHERE sales <= 0;


-- Check for invalid quantities.
SELECT *
FROM gold.fact_sales
WHERE quantity <= 0;


-- Check for invalid prices.
SELECT *
FROM gold.fact_sales
WHERE price <= 0;


-- Check sales calculation consistency.
-- Sales should equal quantity multiplied by price.
SELECT *
FROM gold.fact_sales
WHERE sales <> quantity * ABS(price);


-- Check date consistency.
SELECT *
FROM gold.fact_sales
WHERE order_date > shipping_date
   OR shipping_date > due_date;


-- Check for NULL order dates.
SELECT *
FROM gold.fact_sales
WHERE order_date IS NULL;



-- ============================================================================
-- FOREIGN KEY / REFERENTIAL INTEGRITY
-- ============================================================================

-- Check that every customer key in the fact table exists
-- in the customer dimension.
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;


-- Check that every product key in the fact table exists
-- in the product dimension.
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL;


-- Combined foreign key integrity check.
-- The query should return zero rows.
SELECT
    f.order_number,
    f.customer_key,
    f.product_key
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE c.customer_key IS NULL
   OR p.product_key IS NULL;



-- ============================================================================
-- FACT / DIMENSION INTEGRATION
-- ============================================================================

-- Check that every sales customer can be traced back to the original
-- CRM customer ID.
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
WHERE c.customer_id IS NULL;


-- Check that every sales product can be traced back to the original
-- CRM product number.
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
WHERE p.product_number IS NULL;


-- Check that the product number used to generate the product surrogate key
-- exists in the Silver product table.
SELECT *
FROM gold.dim_products p
LEFT JOIN silver.crm_prd_info sp
    ON p.product_number = sp.prd_key
WHERE sp.prd_key IS NULL;


-- Check that the customer ID used in the customer dimension
-- exists in the Silver CRM customer table.
SELECT *
FROM gold.dim_customers c
LEFT JOIN silver.crm_cust_info sc
    ON c.customer_id = sc.cst_id
WHERE sc.cst_id IS NULL;



-- ============================================================================
-- GENERAL GOLD LAYER CHECKS
-- ============================================================================

-- Check the total number of records in each Gold object.
SELECT 'dim_customers' AS object_name, COUNT(*) AS record_count
FROM gold.dim_customers

UNION ALL

SELECT 'dim_products', COUNT(*)
FROM gold.dim_products

UNION ALL

SELECT 'fact_sales', COUNT(*)
FROM gold.fact_sales;


-- Check for duplicate sales transactions.
-- This identifies repeated combinations of order and product.
SELECT
    order_number,
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY
    order_number,
    product_key
HAVING COUNT(*) > 1;
```
