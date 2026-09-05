/*
================================================================================
Script Name:    silver_load.sql
Description:    Creates a stored procedure to load cleaned and transformed
                data from the Bronze layer into the Silver layer of the
                DataWarehouse.

                The Silver layer contains data that has been cleaned,
                standardized, validated, and transformed from the raw
                Bronze-layer data.

                The procedure performs a full refresh of the Silver layer by:
                - Truncating existing Silver-layer tables.
                - Transforming and cleaning data from Bronze tables.
                - Inserting the transformed data into Silver tables.
                - Tracking the load duration for each table.
                - Tracking the total batch load duration.
                - Displaying progress information during execution.
                - Handling errors using TRY...CATCH.

Procedure:
                silver.load_silver

Source Layer:
                Bronze

Source Systems:
                CRM:
                - Customer information
                - Product information
                - Sales details

                ERP:
                - Customer demographics
                - Customer location
                - Product categories

Target Tables:
                CRM:
                - silver.crm_cust_info
                - silver.crm_prd_info
                - silver.crm_sales_details

                ERP:
                - silver.erp_cust_az12
                - silver.erp_loc_a101
                - silver.erp_px_cat_g1v2

Transformations:
                Customer:
                - Removes duplicate customer records.
                - Trims names and standardizes marital status and gender.

                Product:
                - Extracts category and product identifiers.
                - Replaces missing product costs.
                - Standardizes product line values.
                - Converts product dates to DATE format.
                - Calculates product end dates using the next start date.

                Sales:
                - Validates and converts date values.
                - Corrects invalid sales amounts.
                - Corrects invalid or missing prices.

                ERP Customer:
                - Cleans customer IDs.
                - Handles future birth dates.
                - Standardizes gender values.

                ERP Location:
                - Removes hyphens from customer IDs.
                - Standardizes country names.

                ERP Product Category:
                - Splits the category field into category, subcategory,
                  and maintenance fields.

Load Strategy:
                Full Load

                Existing Silver-layer data is removed using TRUNCATE TABLE
                before the corresponding Bronze data is transformed and loaded.

Error Handling:
                TRY...CATCH is used to capture and display errors encountered
                during the loading process, including:
                - Error message
                - Error number
                - Error line

Usage:
                EXEC silver.load_silver;

Note:
                The Silver layer is loaded from Bronze tables rather than
                directly from source CSV files.

Author:         Aryan Grover
================================================================================
*/


-- ============================================================================
-- Create or Alter Silver Load Procedure
-- ============================================================================
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN

    -- ========================================================================
    -- Declare Variables
    -- ========================================================================
    -- @start_time and @end_time track the duration of individual table loads.
    -- @batch_start_time and @batch_end_time track the overall batch duration.
    DECLARE 
        @start_time DATETIME, 
        @end_time DATETIME, 
        @batch_start_time DATETIME, 
        @batch_end_time DATETIME;

    BEGIN TRY

        -- ====================================================================
        -- Start Silver Layer Load
        -- ====================================================================
        SET @batch_start_time = GETDATE();

        PRINT '=================================================';
        PRINT 'Loading Silver Layer';
        PRINT '=================================================';


        -- ====================================================================
        -- Load CRM Tables
        -- ====================================================================
        PRINT '-------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-------------------------------------------------';


        -- --------------------------------------------------------------------
        -- CRM Customer Information
        -- --------------------------------------------------------------------
        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load.
        PRINT '>> Truncating Table silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        -- Transform and load customer data from the Bronze layer.
        PRINT '>> Inserting Data into silver.crm_cust_info';

        INSERT INTO silver.crm_cust_info(
            cst_id,
            cst_key,
            cst_firstname, 
            cst_lastname, 
            cst_marital_status,
            cst_gender,
            cst_create_date)

        SELECT 
	        cst_id, 
	        cst_key,
	        TRIM(cst_firstname) AS cst_firstname,
	        TRIM(cst_lastname) AS cst_lastname,
	        CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
		         WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		        ELSE 'n/a'
	        END AS cst_marital_status,
	        CASE WHEN UPPER(TRIM(cst_gender)) = 'F' THEN 'Female'
		         WHEN UPPER(TRIM(cst_gender)) = 'M' THEN 'Male'
		        ELSE 'n/a'
	        END AS cst_gender,
	        cst_create_date
        FROM
        (
	        SELECT 
		        *,
		        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	        FROM bronze.crm_cust_info 
	        WHERE cst_id IS NOT NULL
        )t
        WHERE flag_last = 1;


        -- Calculate and display the load duration.
        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- --------------------------------------------------------------------
        -- CRM Product Information
        -- --------------------------------------------------------------------
        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load.
        PRINT '>> Truncating Table silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        -- Transform and load product data from the Bronze layer.
        PRINT '>> Inserting Data into silver.crm_prd_info';

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
        SELECT 
	        prd_id,
	        REPLACE(SUBSTRING(prd_key, 1, 5), '-' , '_') AS cat_id,
	        SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
	        prd_nm,
	        ISNULL(prd_cost, 0) AS prd_cost,
	        CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
		         WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
		         WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
		         WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
		         ELSE 'n/a'
	        END AS prd_line,
	        CAST(prd_start_dt AS DATE) AS prd_start_dt,
	        DATEADD(DAY, -1, LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
        FROM bronze.crm_prd_info;


        -- Calculate and display the load duration.
        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- --------------------------------------------------------------------
        -- CRM Sales Details
        -- --------------------------------------------------------------------
        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load.
        PRINT '>> Truncating Table silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        -- Transform and load sales data from the Bronze layer.
        PRINT '>> Inserting Data into silver.crm_sales_details';

        INSERT INTO silver.crm_sales_details
        (
	        sls_ord_num,
	        sls_prd_key,
	        sls_cust_id,
	        sls_order_dt,
	        sls_ship_dt,
	        sls_due_dt,
	        sls_sales,
	        sls_quantity,
	        sls_price	
        )
        SELECT 
	        sls_ord_num,
	        sls_prd_key,
	        sls_cust_id,
	        CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	        END AS sls_order_dt,
	        CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	        END AS sls_ship_dt,
	        CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	        END AS sls_due_dt,
	        CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
			        THEN sls_quantity * ABS(sls_price)
		        ELSE sls_sales
	        END AS sls_sales,
	        sls_quantity,
	        CASE WHEN sls_price IS NULL OR sls_price <= 0 
			        THEN sls_sales / NULLIF(sls_quantity, 0)
		        ELSE sls_price
	        END AS sls_price
        FROM bronze.crm_sales_details;


        -- Calculate and display the load duration.
        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- ====================================================================
        -- Load ERP Tables
        -- ====================================================================
        PRINT '-------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-------------------------------------------------';


        -- --------------------------------------------------------------------
        -- ERP Customer Demographics
        -- --------------------------------------------------------------------
        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load.
        PRINT '>> Truncating Table silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        -- Transform and load customer demographic data from the Bronze layer.
        PRINT '>> Inserting Data into silver.erp_cust_az12';

        INSERT INTO silver.erp_cust_az12(
            cid,
            bdate,
            gen
            ) 
            SELECT 
	            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		            ELSE cid
	            END AS cid,
	            CASE WHEN bdate > GETDATE() THEN NULL
		            ELSE bdate
	            END AS bdate,
	            CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		             WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		             ELSE 'n/a'
	            END AS gen
            FROM bronze.erp_cust_az12;


        -- Calculate and display the load duration.
        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- --------------------------------------------------------------------
        -- ERP Customer Location
        -- --------------------------------------------------------------------
        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load.
        PRINT '>> Truncating Table silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        -- Transform and load customer location data from the Bronze layer.
        PRINT '>> Inserting Data into silver.erp_loc_a101';

        INSERT INTO silver.erp_loc_a101
            (cid, cntry)
            SELECT 
            REPLACE(cid, '-','') cid,
            CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	             WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	             WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	             ELSE TRIM(cntry)
            END AS cntry
            FROM bronze.erp_loc_a101;


        -- Calculate and display the load duration.
        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- --------------------------------------------------------------------
        -- ERP Product Category
        -- --------------------------------------------------------------------
        SET @start_time = GETDATE();

        -- Remove existing data before performing the full load.
        PRINT '>> Truncating Table silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        -- Transform and load product category data from the Bronze layer.
        PRINT '>> Inserting Data into silver.erp_px_cat_g1v2';

        INSERT INTO silver.erp_px_cat_g1v2
        (id, cat, subcat, maintenance)
        SELECT
	        id,
            LEFT(cat, CHARINDEX(',', cat) - 1) AS cat,
            SUBSTRING(cat, CHARINDEX(',', cat) + 1, CHARINDEX(',', cat, CHARINDEX(',', cat) + 1) - CHARINDEX(',', cat) - 1) AS subcat,
            RIGHT(cat, CHARINDEX(',', REVERSE(cat)) - 1) AS maintenance
        FROM bronze.erp_px_cat_g1v2;


        -- Calculate and display the load duration.
        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- ====================================================================
        -- Silver Layer Load Completed
        -- ====================================================================
        SET @batch_end_time = GETDATE();

        PRINT '==================================================';
        PRINT 'Loading Silver Layer is completed';
        PRINT '    - Total Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) 
            + ' seconds';
        PRINT '==================================================';


    END TRY


    -- ========================================================================
    -- Error Handling
    -- ========================================================================
    BEGIN CATCH

        PRINT '==========================================';
        PRINT 'Error Occurred During Loading Silver Layer';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '==========================================';

    END CATCH

END;
