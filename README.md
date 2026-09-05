# 🏢 SQL Data Warehouse Project

A modern **data warehouse built with SQL Server**, implementing a complete **Bronze → Silver → Gold** architecture with ETL processes, data transformation, data quality testing, and dimensional modelling.

The project uses CRM and ERP source data to build a clean, business-ready data warehouse suitable for analytics and reporting.

---

## 📌 Table of Contents

* [🎯 Project Overview](#-project-overview)
* [🏗️ Data Warehouse Architecture](#️-data-warehouse-architecture)
* [📂 Repository Structure](#-repository-structure)
* [🥉 Bronze Layer](#-bronze-layer)
* [🥈 Silver Layer](#-silver-layer)
* [🥇 Gold Layer](#-gold-layer)
* [🧪 Data Quality & Testing](#-data-quality--testing)
* [🔄 Data Flow](#-data-flow)
* [📊 Gold Data Model](#-gold-data-model)
* [🛠️ Technologies Used](#️-technologies-used)
* [▶️ How to Run the Project](#️-how-to-run-the-project)
* [📚 Documentation](#-documentation)
* [👤 Author](#-author)

---

## 🎯 Project Overview

This project demonstrates the development of a **modern data warehouse using SQL Server**.

The goal is to take raw data from **CRM and ERP source systems**, clean and transform it through multiple layers, and finally create a **business-ready dimensional model** for analytical use.

### The project covers:

* 🗄️ Database and schema creation
* 📥 Raw data ingestion from CSV files
* 🧹 Data cleaning and standardization
* 🔄 ETL transformations
* 🔍 Data quality validation
* 🧪 Automated-style SQL testing
* 🔗 Data integration between CRM and ERP systems
* ⭐ Dimensional modelling
* 📊 Fact and dimension views
* 📝 Data catalog documentation

---

# 🏗️ Data Warehouse Architecture

The warehouse follows a **Medallion-style layered architecture**:

```text
             ┌──────────────────────┐
             │    CRM / ERP Data    │
             │      CSV Sources     │
             └──────────┬───────────┘
                        │
                        ▼
             ┌──────────────────────┐
             │   🥉 BRONZE LAYER   │
             │      Raw Data        │
             │                      │
             │  Minimal / No        │
             │  Transformation      │
             └──────────┬───────────┘
                        │
                        ▼
             ┌──────────────────────┐
             │   🥈 SILVER LAYER   │
             │ Cleaned & Transformed│
             │                      │
             │ Standardization      │
             │ Validation           │
             │ Deduplication        │
             └──────────┬───────────┘
                        │
                        ▼
             ┌──────────────────────┐
             │    🥇 GOLD LAYER    │
             │ Business-Ready Data │
             │                      │
             │ Dimensions + Fact    │
             └──────────────────────┘
```

### Layer Responsibilities

| Layer         | Purpose                                                     |
| ------------- | ----------------------------------------------------------- |
| 🥉 **Bronze** | Stores raw data from CRM and ERP source systems             |
| 🥈 **Silver** | Cleans, standardizes, validates, and transforms Bronze data |
| 🥇 **Gold**   | Provides business-ready data using dimensional modelling    |

---

# 📂 Repository Structure

```text
sql-data-warehouse-project/
│
├── datasets/
│   ├── source_crm/
│   │   ├── cust_info.csv
│   │   ├── prd_info.csv
│   │   └── sales_details.csv
│   │
│   └── source_erp/
│       ├── cust_az12.csv
│       ├── loc_a101.csv
│       └── px_cat_g1v2.csv
│
├── scripts/
│   ├── init_database.sql
│   │
│   ├── bronze/
│   │   ├── bronze_ddl.sql
│   │   └── bronze_load.sql
│   │
│   ├── silver/
│   │   ├── silver_ddl.sql
│   │   └── silver_load.sql
│   │
│   └── gold/
│       └── gold_ddl.sql
│
├── tests/
│   ├── bronze_tests.sql
│   ├── silver_tests.sql
│   └── gold_tests.sql
│
├── docs/
│   ├── data_catalog_bronze.md
│   ├── data_catalog_silver.md
│   └── data_catalog_gold.md
│
└── README.md
```

---

# 🥉 Bronze Layer

The Bronze layer acts as the **raw landing area** for the source data.

Data is loaded from CSV files using `BULK INSERT` with minimal transformation.

### 📋 CRM Tables

#### `bronze.crm_cust_info`

Stores raw customer information:

* Customer ID
* Customer key
* First name
* Last name
* Marital status
* Gender
* Creation date

#### `bronze.crm_prd_info`

Stores raw product information:

* Product ID
* Product key
* Product name
* Product cost
* Product line
* Product start/end dates

#### `bronze.crm_sales_details`

Stores raw sales transactions:

* Order number
* Product key
* Customer ID
* Order date
* Shipping date
* Due date
* Sales amount
* Quantity
* Price

### 📋 ERP Tables

#### `bronze.erp_cust_az12`

Contains ERP customer demographic information.

#### `bronze.erp_loc_a101`

Contains customer location and country information.

#### `bronze.erp_px_cat_g1v2`

Contains product category, subcategory, and maintenance information.

### 📥 Bronze Loading

The Bronze layer is loaded through:

```sql
EXEC bronze.load_bronze;
```

The procedure:

* 📥 Loads CSV source files
* 🧹 Truncates existing Bronze data
* ⏱️ Tracks load duration
* 📊 Displays loading progress
* 🚨 Uses `TRY...CATCH` error handling
* ❌ Reports error message, number, and line

---

# 🥈 Silver Layer

The Silver layer transforms the raw Bronze data into **cleaned and standardized datasets**.

The loading process follows:

```text
🥉 Bronze
    ↓
🧹 Clean
    ↓
🔄 Transform
    ↓
🥈 Silver
```

### 🧹 Key Transformations

#### Customer Data

* Removes duplicate customer records using `ROW_NUMBER()`
* Trims first and last names
* Standardizes marital status:

  * `S → Single`
  * `M → Married`
  * Other values → `n/a`
* Standardizes gender:

  * `F → Female`
  * `M → Male`
  * Other values → `n/a`

#### Product Data

* Extracts category ID from the product key
* Converts `-` to `_` in category IDs
* Extracts the product number
* Replaces NULL product costs with `0`
* Standardizes product line values:

  * `M → Mountain`
  * `R → Road`
  * `S → Other Sales`
  * `T → Touring`
  * Other values → `n/a`
* Converts product dates to `DATE`
* Calculates product end dates using `LEAD()` and `DATEADD()`

#### Sales Data

* Validates and converts sales dates
* Handles invalid date values
* Corrects invalid sales amounts
* Corrects invalid prices
* Uses `NULLIF()` to avoid division-by-zero errors

#### ERP Customer Data

* Removes the `NAS` prefix from customer IDs
* Replaces future birth dates with NULL
* Standardizes gender values

#### ERP Location Data

* Removes hyphens from customer IDs
* Standardizes country values:

  * `DE → Germany`
  * `US / USA → United States`
  * Empty/NULL → `n/a`

#### ERP Product Category Data

The original category field is split into:

```text
Category,Subcategory,Maintenance
```

Resulting in:

```text
cat
subcat
maintenance
```

### 📥 Silver Loading

The Silver layer is loaded using:

```sql
EXEC silver.load_silver;
```

The procedure performs a **full refresh**:

```text
TRUNCATE
   ↓
Read Bronze
   ↓
Transform
   ↓
INSERT
   ↓
Silver
```

---

# 🥇 Gold Layer

The Gold layer contains **business-ready data** designed for analytics and reporting.

It follows a **Star Schema** consisting of:

### ⭐ Dimensions

* `gold.dim_customers`
* `gold.dim_products`

### 📊 Fact

* `gold.fact_sales`

---

## 👥 `gold.dim_customers`

The customer dimension combines CRM and ERP information.

### Includes:

* Customer surrogate key
* Customer ID
* Customer number
* First name
* Last name
* Country
* Marital status
* Gender
* Birth date
* Creation date

### 🔄 Gender Integration

CRM is treated as the **master source** for gender.

```sql
CASE
    WHEN ci.cst_gender != 'n/a'
        THEN ci.cst_gender
    ELSE COALESCE(ca.gen, 'n/a')
END
```

This means:

```text
CRM Gender Available
        ↓
    Use CRM
        ↓
CRM Gender = n/a
        ↓
    Use ERP
        ↓
No ERP Gender
        ↓
      n/a
```

---

## 🚲 `gold.dim_products`

The product dimension combines CRM product information with ERP category information.

### Includes:

* Product surrogate key
* Product ID
* Product number
* Product name
* Category ID
* Category
* Subcategory
* Maintenance
* Cost
* Product line
* Start date
* End date

Only **currently active products** are included:

```sql
WHERE prd_end_dt IS NULL
```

Historical product records are therefore excluded from the Gold dimension.

---

## 💰 `gold.fact_sales`

The sales fact contains transactional information and connects the sales data to the customer and product dimensions.

### Includes:

* Order number
* Customer surrogate key
* Product surrogate key
* Order date
* Shipping date
* Due date
* Sales
* Quantity
* Price

The fact table connects to the dimensions using:

```text
fact_sales.customer_key
        ↓
dim_customers.customer_key

fact_sales.product_key
        ↓
dim_products.product_key
```

---

# 🧪 Data Quality & Testing

The project includes dedicated SQL tests for each warehouse layer.

```text
tests/
├── bronze_tests.sql
├── silver_tests.sql
└── gold_tests.sql
```

## 🥉 Bronze Tests

Validate raw source data for:

* NULL values
* Duplicate IDs
* Invalid values
* Unexpected categorical values
* Invalid dates
* Negative costs
* Invalid sales quantities/prices
* Category formatting

---

## 🥈 Silver Tests

Validate:

* NULL values
* Duplicate records
* Data standardization
* `TRIM()` transformations
* `CASE WHEN` transformations
* Date transformations
* Sales calculations
* Product date consistency
* Country standardization
* Gender standardization
* Category splitting
* CRM/ERP consistency

---

## 🥇 Gold Tests

Validate:

* Dimension surrogate-key uniqueness
* Customer uniqueness
* Product uniqueness
* NULL foreign keys
* Active-product filtering
* Gender integration
* Country integration
* Product-category integration
* Sales calculations
* Date consistency
* Fact/dimension relationships
* Foreign-key integrity

### 🔗 Referential Integrity

The Gold tests verify that every fact record can be connected to a valid customer and product:

```text
             ┌──────────────────┐
             │ dim_customers    │
             │                  │
             │ customer_key     │
             └────────┬─────────┘
                      │
                      │
                      ▼
              ┌───────────────┐
              │  fact_sales   │
              │               │
              │ customer_key  │
              │ product_key   │
              └───────┬───────┘
                      │
                      │
                      ▼
             ┌──────────────────┐
             │ dim_products     │
             │                  │
             │ product_key      │
             └──────────────────┘
```

---

# 🔄 Data Flow

The complete ETL pipeline can be summarized as:

```text
             📁 CSV Source Files
                    │
                    ▼
          ┌─────────────────────┐
          │    🥉 BRONZE        │
          │                     │
          │     Raw Data        │
          └──────────┬──────────┘
                     │
                     ▼
          ┌─────────────────────┐
          │    🥈 SILVER        │
          │                     │
          │ Clean + Transform   │
          │ Standardize         │
          │ Validate            │
          └──────────┬──────────┘
                     │
                     ▼
          ┌─────────────────────┐
          │     🥇 GOLD         │
          │                     │
          │ Dimensions + Fact   │
          └──────────┬──────────┘
                     │
                     ▼
              📊 Analytics
```

---

# 📊 Gold Data Model

The Gold layer follows a **Star Schema**:

```text
                    ┌──────────────────────┐
                    │   dim_customers      │
                    │──────────────────────│
                    │ customer_key         │
                    │ customer_id          │
                    │ customer_number      │
                    │ first_name           │
                    │ last_name             │
                    │ country              │
                    │ marital_status       │
                    │ gender               │
                    │ birth_date           │
                    │ create_date          │
                    └──────────┬───────────┘
                               │
                               │
                               ▼
                    ┌──────────────────────┐
                    │     fact_sales       │
                    │──────────────────────│
                    │ order_number         │
                    │ customer_key         │
                    │ product_key          │
                    │ order_date           │
                    │ shipping_date        │
                    │ due_date             │
                    │ sales                │
                    │ quantity             │
                    │ price                │
                    └──────────┬───────────┘
                               │
                               │
                               ▼
                    ┌──────────────────────┐
                    │    dim_products      │
                    │──────────────────────│
                    │ product_key          │
                    │ product_id           │
                    │ product_number       │
                    │ product_name         │
                    │ category_id          │
                    │ category             │
                    │ subcategory          │
                    │ maintenance          │
                    │ cost                 │
                    │ product_line         │
                    │ start_date           │
                    │ end_date             │
                    └──────────────────────┘
```

---

# 🛠️ Technologies Used

| Technology              | Purpose                                       |
| ----------------------- | --------------------------------------------- |
| 🗄️ **SQL Server**      | Database and data warehouse                   |
| 💻 **T-SQL**            | ETL, transformations, views, and testing      |
| 📄 **CSV**              | Source data format                            |
| 🔄 **BULK INSERT**      | Loading raw source data                       |
| 🧮 **Window Functions** | Deduplication and surrogate-key generation    |
| 🔀 **CASE / COALESCE**  | Data standardization and integration          |
| 🔗 **JOINs**            | CRM/ERP integration and dimensional modelling |
| 🧪 **SQL Tests**        | Data quality and integrity validation         |
| 📝 **Markdown**         | Project documentation and data catalogs       |

---

# ▶️ How to Run the Project

## 1️⃣ Create the Database

Run:

```text
scripts/init_database.sql
```

This creates:

```text
DataWarehouse
├── bronze
├── silver
└── gold
```

> ⚠️ **Warning:** The initialization script drops and recreates the `DataWarehouse` database. Do not run it against a database containing data you want to keep.

---

## 2️⃣ Create Bronze Tables

Run:

```text
scripts/bronze/bronze_ddl.sql
```

This creates all Bronze-layer tables.

---

## 3️⃣ Load Bronze Data

Run:

```text
scripts/bronze/bronze_load.sql
```

Then execute:

```sql
EXEC bronze.load_bronze;
```

---

## 4️⃣ Create Silver Tables

Run:

```text
scripts/silver/silver_ddl.sql
```

---

## 5️⃣ Load Silver Data

Run:

```text
scripts/silver/silver_load.sql
```

Then execute:

```sql
EXEC silver.load_silver;
```

---

## 6️⃣ Create Gold Views

Run:

```text
scripts/gold/gold_ddl.sql
```

This creates:

```text
gold.dim_customers
gold.dim_products
gold.fact_sales
```

---

## 7️⃣ Run Data Quality Tests

Run the test scripts:

```text
tests/bronze_tests.sql
tests/silver_tests.sql
tests/gold_tests.sql
```

The tests are designed so that **queries returning zero rows generally indicate that the specific validation condition was satisfied**.

---

# 📚 Documentation

The project includes data catalogs documenting the warehouse layers and their columns.

```text
docs/
├── data_catalog_bronze.md
├── data_catalog_silver.md
└── data_catalog_gold.md
```

The catalogs document:

* 📋 Table/view definitions
* 🏷️ Column names
* 🔢 Data types
* 📖 Column descriptions
* 🔄 Transformations
* 🔗 Source relationships
* 💼 Business rules

---

# 🚧 Project Status

### Completed

* [x] 🗄️ Database initialization
* [x] 🥉 Bronze schema
* [x] 📥 Bronze data ingestion
* [x] 🥈 Silver schema
* [x] 🧹 Silver transformations
* [x] 🥇 Gold dimensional model
* [x] 👥 Customer dimension
* [x] 🚲 Product dimension
* [x] 💰 Sales fact
* [x] 🧪 Bronze data-quality tests
* [x] 🧪 Silver data-quality tests
* [x] 🧪 Gold data-quality tests
* [x] 📝 Data catalogs
* [x] 📚 Project documentation

### 🔜 Future Improvements

* [ ] 📊 Analytical SQL queries
* [ ] 📈 Business KPI analysis
* [ ] 📉 Reporting/dashboard layer
* [ ] ⚙️ Improved deployment portability
* [ ] 🔄 Additional ETL monitoring
* [ ] 🚀 Production-oriented optimizations

---

# 👤 Author

**Aryan Grover**

SQL Data Warehouse Project
Built using **SQL Server and T-SQL**.

---

## ⭐ Project Goal

The ultimate goal of this project is to demonstrate an end-to-end understanding of:

**Raw Data → ETL → Data Cleaning → Data Integration → Dimensional Modelling → Data Quality → Analytics**

```text
📁 Raw Data
    ↓
🥉 Bronze
    ↓
🧹 Cleaning & Transformation
    ↓
🥈 Silver
    ↓
🔗 Integration & Modelling
    ↓
🥇 Gold
    ↓
🧪 Testing
    ↓
📊 Analytics
```

> **From raw source files to a business-ready data warehouse. 🚀**

```

This version reflects what you've **actually built so far**, rather than inventing a bunch of future functionality and pretending you've already conquered the entire data engineering industry. The README is now also consistent with your current `scripts/`, `tests/`, and `docs/` structure.
```
