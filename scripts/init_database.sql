```sql
/*
================================================================================
Script Name:    init_database.sql
Description:    Creates and initializes the DataWarehouse database.

                The script:
                - Drops the existing DataWarehouse database if it exists.
                - Creates a fresh DataWarehouse database.
                - Creates the Bronze, Silver, and Gold schemas used
                  throughout the data warehouse.

                Bronze: Raw data loaded from source systems
                Silver: Cleaned and transformed data
                Gold:   Business-ready data for analytics

Usage:          Execute this script in SQL Server Management Studio (SSMS)
                to initialize or reset the data warehouse environment.

Warning:        This script DROPS the existing DataWarehouse database.
                Any existing data will be permanently deleted.

Author:         Aryan Grover
================================================================================
*/

USE master;
GO

-- ============================================================================
-- Drop and recreate the DataWarehouse database
-- ============================================================================
-- Check whether the DataWarehouse database already exists.
-- If it exists, force all active connections to close and then drop the database.
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    -- Switch the database to SINGLE_USER mode and immediately
    -- terminate any existing connections.
    ALTER DATABASE DataWarehouse 
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    -- Permanently remove the existing database.
    DROP DATABASE DataWarehouse;
END;
GO

-- ============================================================================
-- Create the DataWarehouse database
-- ============================================================================
CREATE DATABASE DataWarehouse;
GO

-- Switch the current database context to DataWarehouse.
USE DataWarehouse;
GO

-- ============================================================================
-- Create Data Warehouse Schemas
-- ============================================================================

-- Bronze Layer
-- Stores raw data loaded directly from source systems.
CREATE SCHEMA bronze;
GO

-- Silver Layer
-- Stores cleaned, standardized, and transformed data.
CREATE SCHEMA silver;
GO

-- Gold Layer
-- Stores business-ready data used for analytics and reporting.
CREATE SCHEMA gold;
GO
```
