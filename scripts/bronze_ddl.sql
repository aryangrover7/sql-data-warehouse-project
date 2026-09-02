```sql
/*
================================================================================
Script Name:    bronze_ddl.sql
Description:    Creates the tables required for the Bronze layer of the
                DataWarehouse.

                The Bronze layer stores raw data ingested from CRM and ERP
                source systems with minimal transformation.

                The script:
                - Drops existing Bronze-layer tables if they exist.
                - Creates the required Bronze-layer tables.
                - Defines the columns and data types for each source dataset.

Source Systems:
                CRM - Customer information, product information, and sales data
                ERP - Customer location, customer demographic, and product
                      category information

Tables Created:
                CRM:
                - bronze.crm_cust_info
                - bronze.crm_prd_info
                - bronze.crm_sales_details

                ERP:
                - bronze.erp_loc_a101
                - bronze.erp_cust_az12
                - bronze.erp_px_cat_g1v2

Usage:          Execute this script after initializing the DataWarehouse
                database and creating the Bronze, Silver, and Gold schemas.

Note:           Bronze tables are designed to preserve the structure of the
                incoming source data. Data cleansing and transformation will
                be handled in subsequent layers.

Author:         Aryan Grover
================================================================================
*/


-- ============================================================================
-- CRM: Customer Information
-- ============================================================================
-- Drop the table if it already exists to ensure a clean table definition.
IF OBJECT_ID ('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;

-- Create the raw customer information table.
CREATE TABLE bronze.crm_cust_info
(
    cst_id INT, 
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gender NVARCHAR(50),
    cst_create_date DATE
);


-- ============================================================================
-- CRM: Product Information
-- ============================================================================
-- Drop the table if it already exists to ensure a clean table definition.
IF OBJECT_ID ('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

-- Create the raw product information table.
CREATE TABLE bronze.crm_prd_info
(
    prd_id INT, 
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE
);


-- ============================================================================
-- CRM: Sales Details
-- ============================================================================
-- Drop the table if it already exists to ensure a clean table definition.
IF OBJECT_ID ('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;

-- Create the raw sales transaction table.
CREATE TABLE bronze.crm_sales_details
(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT, 
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT, 
    sls_price INT
);


-- ============================================================================
-- ERP: Customer Location
-- ============================================================================
-- Drop the table if it already exists to ensure a clean table definition.
IF OBJECT_ID ('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;

-- Create the raw customer location table.
CREATE TABLE bronze.erp_loc_a101
(
    cid NVARCHAR(50),
    cntry NVARCHAR(50)
);


-- ============================================================================
-- ERP: Customer Demographics
-- ============================================================================
-- Drop the table if it already exists to ensure a clean table definition.
IF OBJECT_ID ('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;

-- Create the raw customer demographic table.
CREATE TABLE bronze.erp_cust_az12
(
    cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR(50)
);


-- ============================================================================
-- ERP: Product Category
-- ============================================================================
-- Drop the table if it already exists to ensure a clean table definition.
IF OBJECT_ID ('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;

-- Create the raw product category table.
CREATE TABLE bronze.erp_px_cat_g1v2
(
    id NVARCHAR(50),
    cat NVARCHAR(50)
);
```
