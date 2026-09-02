```sql
/*
================================================================================
Description:    Creates a stored procedure to load raw data into the Bronze
                layer of the DataWarehouse.

                The procedure:
                - Truncates existing Bronze-layer tables.
                - Loads raw data from CRM and ERP CSV files.
                - Records individual table load durations.
                - Records the total batch load duration.
                - Displays progress and error messages during execution.

Procedure:
                bronze.load_bronze

Source Systems:
                CRM - Customer information, product information, and sales data
                ERP - Customer demographic, location, and product category data

Target Tables:
                CRM:
                - bronze.crm_cust_info
                - bronze.crm_prd_info
                - bronze.crm_sales_details

                ERP:
                - bronze.erp_cust_az12
                - bronze.erp_loc_a101
                - bronze.erp_px_cat_g1v2

Load Strategy:
                Full Load

                Existing data is removed using TRUNCATE TABLE before each
                source file is loaded using BULK INSERT.

Error Handling:
                TRY...CATCH is used to capture and display errors that occur
                during the Bronze-layer loading process.

Note:           The BULK INSERT file paths currently reference the local
                development environment. These paths may need to be updated
                when the project is executed on another machine.

Usage:
                EXEC bronze.load_bronze;

Author:         Aryan Grover
================================================================================
*/


CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

    -- =========================================================================
    -- Variable Declaration
    -- =========================================================================
    -- Variables are used to track the duration of individual table loads
    -- and the overall Bronze-layer loading process.
    DECLARE 
        @start_time DATETIME, 
        @end_time DATETIME, 
        @batch_start_time DATETIME, 
        @batch_end_time DATETIME;

    BEGIN TRY

        -- =====================================================================
        -- Start Bronze Layer Load
        -- =====================================================================
        SET @batch_start_time = GETDATE();

        PRINT '=================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=================================================';


        -- =====================================================================
        -- Load CRM Tables
        -- =====================================================================
        PRINT '-------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-------------------------------------------------';


        -- ---------------------------------------------------------------------
        -- CRM Customer Information
        -- ---------------------------------------------------------------------
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Inserting Data into bronze.crm_cust_info';

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\Aryan\SQL_YT_Course_Udemy\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH 
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- ---------------------------------------------------------------------
        -- CRM Product Information
        -- ---------------------------------------------------------------------
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Inserting Data into bronze.crm_prd_info';

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\Aryan\SQL_YT_Course_Udemy\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH 
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- ---------------------------------------------------------------------
        -- CRM Sales Details
        -- ---------------------------------------------------------------------
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Inserting Data into bronze.crm_sales_details';

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\Aryan\SQL_YT_Course_Udemy\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH 
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- =====================================================================
        -- Load ERP Tables
        -- =====================================================================
        PRINT '-------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-------------------------------------------------';


        -- ---------------------------------------------------------------------
        -- ERP Customer Demographics
        -- ---------------------------------------------------------------------
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Inserting Data into bronze.erp_cust_az12';

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\Aryan\SQL_YT_Course_Udemy\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
        WITH 
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- ---------------------------------------------------------------------
        -- ERP Customer Location
        -- ---------------------------------------------------------------------
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Inserting Data into bronze.erp_loc_a101';

        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\Aryan\SQL_YT_Course_Udemy\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        WITH 
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- ---------------------------------------------------------------------
        -- ERP Product Category
        -- ---------------------------------------------------------------------
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Inserting Data into bronze.erp_px_cat_g1v2';

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\Aryan\SQL_YT_Course_Udemy\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        WITH 
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) 
            + ' seconds';

        PRINT '-----------';


        -- =====================================================================
        -- Bronze Layer Load Completed
        -- =====================================================================
        SET @batch_end_time = GETDATE();

        PRINT '==================================================';
        PRINT 'Loading Bronze Layer is completed';
        PRINT ' - Total Load Duration : ' 
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) 
            + ' seconds';
        PRINT '==================================================';


    END TRY


    -- =========================================================================
    -- Error Handling
    -- =========================================================================
    BEGIN CATCH

        PRINT '==========================================';
        PRINT 'Error Occurred During Loading Bronze Layer';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '==========================================';

    END CATCH

END;
```
