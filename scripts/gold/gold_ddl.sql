```sql
/*
================================================================================
Script Name:    gold_ddl.sql
Description:    Creates the views required for the Gold layer of the
                DataWarehouse.

                The Gold layer contains business-ready data designed for
                analytics and reporting. It follows a dimensional modelling
                approach consisting of customer and product dimensions and
                a sales fact.

                The script:
                - Creates the customer dimension view.
                - Creates the product dimension view.
                - Creates the sales fact view.
                - Integrates data from the Silver layer.
                - Generates surrogate keys for dimension records.
                - Establishes relationships between dimensions and facts.

Data Model:
                Gold layer follows a Star Schema design.

                Dimensions:
                - gold.dim_customers
                - gold.dim_products

                Fact:
                - gold.fact_sales

Source Layer:
                Silver

Author:         Aryan Grover
================================================================================
*/


USE DataWarehouse;
GO


-- ============================================================================
-- Customer Dimension
-- ============================================================================
-- Creates the customer dimension by combining CRM customer information
-- with ERP customer demographic and location information.
--
-- Business Rules:
-- - CRM is the master source for customer gender.
-- - ERP gender is used as a fallback when CRM gender is 'n/a'.
-- - A surrogate customer key is generated using ROW_NUMBER().
-- ============================================================================

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    la.cntry AS country,
    ci.cst_marital_status AS marital_status,

    -- CRM is the master source for gender information.
    -- ERP gender is used when CRM gender is unavailable.
    CASE 
        WHEN ci.cst_gender != 'n/a' THEN ci.cst_gender
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,

    ca.bdate AS birth_date,
    ci.cst_create_date AS create_date

FROM silver.crm_cust_info ci

LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid

LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;

GO



-- ============================================================================
-- Product Dimension
-- ============================================================================
-- Creates the product dimension by combining CRM product information with
-- ERP product category information.
--
-- Business Rules:
-- - A surrogate product key is generated using ROW_NUMBER().
-- - Product category information is sourced from ERP.
-- - Historical product records are excluded.
-- - Only currently active products where prd_end_dt IS NULL are included.
-- ============================================================================

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER(
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key,

    pn.prd_id AS product_id,
    pn.prd_key AS product_number,
    pn.prd_nm AS product_name,
    pn.cat_id AS category_id,
    pc.cat AS category,
    pc.subcat AS subcategory,
    pc.maintenance,
    pn.prd_cost AS cost,
    pn.prd_line AS product_line,
    pn.prd_start_dt AS start_date,
    pn.prd_end_dt AS end_date

FROM silver.crm_prd_info pn

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id

-- Filter out historical product records.
WHERE pn.prd_end_dt IS NULL;

GO



-- ============================================================================
-- Sales Fact
-- ============================================================================
-- Creates the sales fact by combining CRM sales transactions with the
-- customer and product dimensions.
--
-- Business Rules:
-- - Product surrogate keys are obtained from gold.dim_products.
-- - Customer surrogate keys are obtained from gold.dim_customers.
-- - Sales measures are sourced from the Silver sales table.
-- - The fact table connects transactional data with descriptive dimensions.
-- ============================================================================

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price

FROM silver.crm_sales_details sd

LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number

LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;

GO
```
