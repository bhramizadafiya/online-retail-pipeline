## STEP 1: TRANSFORM (CLEAN DATA IN STAGING)

## 1. Remove cancelled orders (Cancelled invoices start with C)

DELETE FROM stg_online_retail
WHERE invoice_no LIKE 'C%';

## 2️. Remove invalid records

DELETE FROM stg_online_retail
WHERE quantity <= 0
   OR unit_price <= 0
   OR customer_id IS NULL;
   
## 3️. Remove duplicates (if any)

DELETE t1
FROM stg_online_retail t1
JOIN stg_online_retail t2
  ON t1.invoice_no = t2.invoice_no
 AND t1.stock_code = t2.stock_code
 AND t1.invoice_date = t2.invoice_date
 AND t1.customer_id = t2.customer_id
 AND t1.quantity = t2.quantity
 AND t1.unit_price = t2.unit_price
WHERE t1.invoice_no > t2.invoice_no;

## STEP 2: LOAD DATA INTO FINAL TABLES
## 4️. Load CUSTOMERS

INSERT INTO customers (customer_id, country)
SELECT DISTINCT customer_id, country
FROM stg_online_retail;

## 5️. Load PRODUCTS

INSERT INTO products (product_id, description, unit_price)
SELECT DISTINCT stock_code, description, unit_price
FROM stg_online_retail;

## 6️. Load ORDERS

INSERT INTO orders (order_id, order_date, customer_id)
SELECT DISTINCT invoice_no, invoice_date, customer_id
FROM stg_online_retail;

## 7️. Load ORDER_ITEMS (FACT TABLE ⭐)

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT
    invoice_no,
    stock_code,
    quantity,
    unit_price
FROM stg_online_retail;


## STEP 3: DERIVE INVENTORY TABLE
## 8️. Populate INVENTORY

INSERT INTO inventory (product_id, total_quantity_sold, current_stock)
SELECT
    product_id,
    SUM(quantity) AS total_quantity_sold,
    1000 - SUM(quantity) AS current_stock
FROM order_items
GROUP BY product_id;

## STEP 4: VALIDATION QUERIES
## Run these to prove correctness:

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM inventory;