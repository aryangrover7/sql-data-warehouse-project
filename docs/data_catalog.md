# Data Catalog

## Overview

This data catalog documents the three Gold-layer tables/views in the data warehouse.

The Gold layer is designed to provide business-ready data for analytics and reporting.

---

# 1. `gold.dim_customers`

**Type:** View  
**Layer:** Gold  
**Purpose:** Customer dimension containing customer identity, demographic, geographic, and creation-date information.

### Source Tables

- `silver.crm_cust_info`
- `silver.erp_cust_az12`
- `silver.erp_loc_a101`

### Columns

| Column | Data Type | Description | Source / Transformation |
|---|---|---|---|
| `customer_key` | BIGINT | Surrogate key for the customer dimension. | `ROW_NUMBER() OVER(ORDER BY cst_id)` |
| `customer_id` | INT | Unique customer identifier from the CRM system. | `silver.crm_cust_info.cst_id` |
| `customer_number` | NVARCHAR(50) | Customer business key from the CRM system. | `silver.crm_cust_info.cst_key` |
| `first_name` | NVARCHAR(50) | Customer first name. | `silver.crm_cust_info.cst_firstname` |
| `last_name` | NVARCHAR(50) | Customer last name. | `silver.crm_cust_info.cst_lastname` |
| `country` | NVARCHAR(50) | Customer country. | `silver.erp_loc_a101.cntry` |
| `marital_status` | NVARCHAR(50) | Customer marital status. | `silver.crm_cust_info.cst_marital_status` |
| `gender` | NVARCHAR(50) | Customer gender. CRM is treated as the master source. | CRM gender when not `n/a`; otherwise ERP gender using `COALESCE` |
| `birth_date` | DATE | Customer date of birth. | `silver.erp_cust_az12.bdate` |
| `create_date` | DATE | Date the customer record was created. | `silver.crm_cust_info.cst_create_date` |

### Business Rules

- CRM customer information is the primary source for customer attributes.
- CRM gender is used when available.
- ERP gender is used as a fallback when CRM gender is `n/a`.
- A surrogate `customer_key` is generated using `ROW_NUMBER()`.
- ERP customer and location information is joined using the customer business key.

---

# 2. `gold.dim_products`

**Type:** Dimension Table / View  
**Layer:** Gold  
**Purpose:** Product dimension containing product identifiers, descriptive information, category information, pricing, product line, and validity dates.

### Source Tables

- `silver.crm_prd_info`
- `silver.erp_px_cat_g1v2`

### Columns

| Column | Data Type | Description | Source / Transformation |
|---|---|---|---|
| `product_key` | BIGINT | Surrogate key for the product dimension. | Generated using `ROW_NUMBER()` |
| `product_id` | INT | Product identifier from CRM. | `silver.crm_prd_info.prd_id` |
| `product_number` | NVARCHAR(50) | Product business key. | `silver.crm_prd_info.prd_key` |
| `product_name` | NVARCHAR(50) | Product name. | `silver.crm_prd_info.prd_nm` |
| `category_id` | NVARCHAR(50) | Product category identifier. | `silver.crm_prd_info.cat_id` |
| `category` | NVARCHAR(50) | Product category. | `silver.erp_px_cat_g1v2.cat` |
| `subcategory` | NVARCHAR(50) | Product subcategory. | `silver.erp_px_cat_g1v2.subcat` |
| `maintenance` | NVARCHAR(50) | Product maintenance classification. | `silver.erp_px_cat_g1v2.maintenance` |
| `cost` | INT | Product cost. | `silver.crm_prd_info.prd_cost` |
| `product_line` | NVARCHAR(50) | Standardized product line. | `silver.crm_prd_info.prd_line` |
| `start_date` | DATE | Date the product became active. | `silver.crm_prd_info.prd_start_dt` |
| `end_date` | DATE | Date the product became inactive. | `silver.crm_prd_info.prd_end_dt` |

### Business Rules

- CRM is the primary source for product information.
- Product category attributes are sourced from ERP.
- Product category data is joined using the category identifier.
- Product keys are represented separately from warehouse surrogate keys.
- Product validity is represented using `start_date` and `end_date`.

> **Note:** The exact Gold `dim_products` SQL was not provided in the conversation, so the column definitions above document the intended structure based on the Silver tables and transformations already established. Verify the names and data types against the actual Gold view/table before treating this as the final catalog.

---

# 3. `gold.fact_sales`

**Type:** Fact Table / View  
**Layer:** Gold  
**Purpose:** Sales fact containing transactional measures and foreign keys linking sales transactions to customer and product dimensions.

### Source Tables

- `silver.crm_sales_details`
- `gold.dim_customers`
- `gold.dim_products`

### Columns

| Column | Data Type | Description | Source / Transformation |
|---|---|---|---|
| `order_number` | NVARCHAR(50) | Sales order number. | `silver.crm_sales_details.sls_ord_num` |
| `product_key` | BIGINT | Foreign key to the product dimension. | Lookup from `gold.dim_products` |
| `customer_key` | BIGINT | Foreign key to the customer dimension. | Lookup from `gold.dim_customers` |
| `order_date` | DATE | Date the order was placed. | `silver.crm_sales_details.sls_order_dt` |
| `shipping_date` | DATE | Date the order was shipped. | `silver.crm_sales_details.sls_ship_dt` |
| `due_date` | DATE | Expected delivery/due date. | `silver.crm_sales_details.sls_due_dt` |
| `sales_amount` | INT | Sales amount for the transaction. | `silver.crm_sales_details.sls_sales` |
| `quantity` | INT | Quantity of products sold. | `silver.crm_sales_details.sls_quantity` |
| `price` | INT | Price per product. | `silver.crm_sales_details.sls_price` |

### Business Rules

- The fact table uses surrogate keys from the Gold customer and product dimensions.
- Sales measures originate from the Silver sales table.
- Customer and product relationships are established through dimension lookups.
- `sales_amount` should be consistent with `quantity * price`.

---

# Data Flow

```text
CRM / ERP Source Systems
          |
          v
      Bronze Layer
      Raw Data
          |
          v
      Silver Layer
 Cleaned & Transformed
          |
          v
       Gold Layer
 Business-Ready Data
     /          \
    v            v
dim_customers  dim_products
       \        /
        \      /
         v    v
       fact_sales
```

## Gold Layer Model

The Gold layer follows a dimensional modelling approach:

- **Dimensions** provide descriptive business context.
- **Facts** contain measurable business events.
- `fact_sales` connects to `dim_customers` and `dim_products` through surrogate keys.

## Naming Conventions

| Prefix | Meaning |
|---|---|
| `dim_` | Dimension containing descriptive attributes |
| `fact_` | Fact containing measurable business events |
| `customer_key` | Warehouse-generated surrogate key |
| `customer_id` | Source-system customer identifier |
| `customer_number` | Source-system business key |
| `product_key` | Warehouse-generated product surrogate key |
| `product_id` | Source-system product identifier |
| `product_number` | Source-system product business key |

---

## Data Quality Expectations

The Gold layer should satisfy the following expectations:

- Dimension surrogate keys should be unique.
- Fact foreign keys should match valid dimension keys.
- Required identifiers should not be NULL.
- Sales amounts should be consistent with quantity and price.
- Customer and product attributes should use standardized values from the Silver layer.
- Gold objects should be suitable for analytical queries and reporting.
