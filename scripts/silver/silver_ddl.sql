/*
================================================================================
Script Name:    silver_ddl.sql
Description:    Creates the tables required for the Silver layer of the
                DataWarehouse.

                The Silver layer stores cleaned, standardized, and transformed
                data from the Bronze layer. Data quality issues are addressed
                and the data is prepared for further modelling in the Gold layer.

                The script:
                - Drops existing Silver-layer tables if they already exist.
                - Creates the required Silver-layer tables.
                - Defines the columns and data types for each transformed dataset.
                - Adds a data warehouse load timestamp to each table.

Source Layer:
                Bronze

Tables Created:
                CRM:
                - silver.crm_cust_info
                - silver.crm_prd_info
                - silver.crm_sales_details

                ERP:
                - silver.erp_loc_a101
                - silver.erp_cust_az12
                - silver.erp_px_cat_g1v2

Transformation:
                Data loaded into the Silver layer is cleaned and transformed
                from the raw Bronze-layer data. Typical transformations include
                data standardization, handling invalid values, removing
                duplicates, and formatting data into a consistent structure.

Usage:
                Execute this script after the DataWarehouse database and
                Silver schema have been created.

Author:         Aryan Grover
================================================================================
*/


-- ============================================================================
-- CRM: Customer Information
-- Drops and recreates the Silver customer table.
-- Stores cleaned and standardized customer information.
-- ============================================================================

IF OBJECT_ID ('silver.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info
(
	cst_id INT, 
	cst_key NVARCHAR(50),
	cst_firstname NVARCHAR(50),
	cst_lastname NVARCHAR(50),
	cst_marital_status NVARCHAR(50),
	cst_gender NVARCHAR(50),
	cst_create_date DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


-- ============================================================================
-- CRM: Product Information
-- Drops and recreates the Silver product table.
-- Stores cleaned and standardized product information.
-- ============================================================================

IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info
(
	prd_id INT,
	cat_id NVARCHAR(50),
	prd_key NVARCHAR(50),
	prd_nm NVARCHAR(50),
	prd_cost INT,
	prd_line NVARCHAR(50),
	prd_start_dt DATE,
	prd_end_dt DATE,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


-- ============================================================================
-- CRM: Sales Details
-- Drops and recreates the Silver sales table.
-- Stores cleaned and standardized sales transaction information.
-- ============================================================================

IF OBJECT_ID ('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details
(
	sls_ord_num NVARCHAR(50),
	sls_prd_key NVARCHAR(50),
	sls_cust_id INT, 
	sls_order_dt DATE,
	sls_ship_dt DATE,
	sls_due_dt DATE,
	sls_sales INT,
	sls_quantity INT, 
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


-- ============================================================================
-- ERP: Location Information
-- Drops and recreates the Silver location table.
-- Stores cleaned and standardized customer location information.
-- ============================================================================

IF OBJECT_ID ('silver.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101
(
	cid NVARCHAR(50),
	cntry NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


-- ============================================================================
-- ERP: Customer Information
-- Drops and recreates the Silver ERP customer table.
-- Stores cleaned and standardized customer demographic information.
-- ============================================================================

IF OBJECT_ID ('silver.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12
(
	cid NVARCHAR(50),
	bdate DATE,
	gen NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);


-- ============================================================================
-- ERP: Product Category Information
-- Drops and recreates the Silver product category table.
-- Stores separated and standardized category, subcategory, and maintenance data.
-- ============================================================================

IF OBJECT_ID ('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2
(
	id NVARCHAR(50),
	cat NVARCHAR(50),
	subcat NVARCHAR(50),
    maintenance NVARCHAR(50),
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);
