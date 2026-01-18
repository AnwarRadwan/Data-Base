-- =========================
-- Create DB + Use
-- =========================
CREATE DATABASE IF NOT EXISTS SileenSystem;
USE SileenSystem;

-- =========================
-- Reset (Drop)
-- =========================
SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables (children -> parents)
DROP TABLE IF EXISTS customer_user_accounts;
DROP TABLE IF EXISTS returns;
DROP TABLE IF EXISTS sale_items;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS sales_orders;

DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS purchase_order_items;
DROP TABLE IF EXISTS purchase_orders;

DROP TABLE IF EXISTS stock_items;     -- boutique items
DROP TABLE IF EXISTS items;           -- original items
DROP TABLE IF EXISTS categories;

DROP TABLE IF EXISTS warehouses;
DROP TABLE IF EXISTS customers;

DROP TABLE IF EXISTS user_accounts;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS managers;
DROP TABLE IF EXISTS branches;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================
-- (A) Original System Tables
-- =========================

-- =========================
-- 1) Branches
-- =========================
CREATE TABLE branches (
  branch_id       INT AUTO_INCREMENT PRIMARY KEY,
  name            VARCHAR(100) NOT NULL,
  location        VARCHAR(200) NOT NULL,
  contact_person  VARCHAR(100)
);

-- =========================
-- 2) Warehouses
-- =========================
CREATE TABLE warehouses (
  warehouse_id  INT AUTO_INCREMENT PRIMARY KEY,
  branch_id     INT NOT NULL,
  name          VARCHAR(100) NOT NULL,
  location      VARCHAR(200) NOT NULL,
  capacity      INT,
  FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

-- =========================
-- 3) Managers
-- =========================
CREATE TABLE managers (
  manager_id    INT AUTO_INCREMENT PRIMARY KEY,
  branch_id     INT NOT NULL,
  name          VARCHAR(100) NOT NULL,
  role          VARCHAR(50),
  email         VARCHAR(150),
  phone_number  VARCHAR(30),
  FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

-- =========================
-- 4) Staff
-- =========================
CREATE TABLE staff (
  staff_id     INT AUTO_INCREMENT PRIMARY KEY,
  branch_id    INT NOT NULL,
  manager_id   INT,
  name         VARCHAR(100) NOT NULL,
  role         VARCHAR(50),
  phone        VARCHAR(30),
  email        VARCHAR(150),
  FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  FOREIGN KEY (manager_id) REFERENCES managers(manager_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

-- =========================
-- 5) User Accounts (Admin / Customer)
-- =========================
CREATE TABLE user_accounts (
  user_id       INT AUTO_INCREMENT PRIMARY KEY,
  staff_id      INT,
  username      VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          VARCHAR(20) NOT NULL,  -- Admin / Customer
  FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

-- =========================
-- 6) Purchase Orders (NO warehouse_id)
-- =========================
CREATE TABLE purchase_orders (
  purchase_order_id  INT AUTO_INCREMENT PRIMARY KEY,
  staff_id           INT,
  order_date         DATE NOT NULL,
  total_amount       DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status             VARCHAR(30) NOT NULL,
  FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

-- =========================
-- 7) Categories
-- =========================
CREATE TABLE categories (
  category_id   INT AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  description   VARCHAR(255),
  image_path    VARCHAR(255)
);

-- =========================
-- 8) Items (Original)
-- =========================
CREATE TABLE items (
  item_id        INT AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(150) NOT NULL,
  unit_price     DECIMAL(12,2) NOT NULL,
  stock_quantity INT NOT NULL DEFAULT 0,
  category_id    INT,
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

-- =========================
-- 9) Purchase Order Items (Ternary)
-- =========================
CREATE TABLE purchase_order_items (
  purchase_order_id INT NOT NULL,
  item_id           INT NOT NULL,
  warehouse_id      INT NOT NULL,
  quantity          INT NOT NULL,
  unit_price        DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (purchase_order_id, item_id, warehouse_id),
  FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(purchase_order_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES items(item_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

-- =========================
-- 10) Stock Movements
-- =========================
CREATE TABLE stock_movements (
  movement_id     INT AUTO_INCREMENT PRIMARY KEY,
  item_id         INT NOT NULL,
  warehouse_id    INT NOT NULL,
  movement_type   VARCHAR(10) NOT NULL,      -- IN / OUT
  quantity        INT NOT NULL,
  movement_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reference_type  VARCHAR(30),
  reference_id    INT,
  FOREIGN KEY (item_id) REFERENCES items(item_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

-- =========================
-- (B) Boutique Tables (Sales side)
-- =========================

-- =========================
-- 11) Customers
-- =========================
CREATE TABLE customers (
  customer_id          INT AUTO_INCREMENT PRIMARY KEY,
  name                 VARCHAR(255) NOT NULL,
  contact_information  VARCHAR(255),
  address              TEXT,
  email                VARCHAR(255) UNIQUE
);

-- =========================
-- 12) Customer <-> User Accounts (N:M)
-- =========================
CREATE TABLE customer_user_accounts (
  customer_id INT NOT NULL,
  user_id     INT NOT NULL,
  PRIMARY KEY (customer_id, user_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES user_accounts(user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- =========================
-- 13) Stock Items (Boutique)  (uses same categories + warehouses)
-- =========================
CREATE TABLE stock_items (
  item_id        INT AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(255) NOT NULL,
  description    TEXT,
  unit_price     DECIMAL(10,2) NOT NULL,
  stock_quantity INT NOT NULL DEFAULT 0,
  import_date    DATE,
  category_id    INT,
  warehouse_id   INT,
  image_path     VARCHAR(255),
  FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

-- =========================
-- 14) Sales Orders (with branch_id + staff_id)
-- =========================
CREATE TABLE sales_orders (
  sales_order_id  INT AUTO_INCREMENT PRIMARY KEY,
  customer_id     INT,
  branch_id       INT NOT NULL,
  staff_id        INT,
  order_date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status          VARCHAR(50) NOT NULL DEFAULT 'Pending',
  total_amount    DECIMAL(10,2) NOT NULL DEFAULT 0.00,

  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION,

  FOREIGN KEY (staff_id) REFERENCES staff(staff_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

-- =========================
-- 15) Invoices (1:1 with SalesOrders)
-- =========================
CREATE TABLE invoices (
  invoice_id      INT AUTO_INCREMENT PRIMARY KEY,
  sales_order_id  INT UNIQUE,
  invoice_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  amount          DECIMAL(10,2) NOT NULL,
  tax             DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  payment_status  VARCHAR(50) NOT NULL DEFAULT 'Unpaid',
  FOREIGN KEY (sales_order_id) REFERENCES sales_orders(sales_order_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- =========================
-- 16) Sale Items
-- =========================
CREATE TABLE sale_items (
  sale_item_id    INT AUTO_INCREMENT PRIMARY KEY,
  sales_order_id  INT NOT NULL,
  item_id         INT NOT NULL, -- references stock_items
  quantity        INT NOT NULL,
  unit_price      DECIMAL(10,2) NOT NULL,
  discount        DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  FOREIGN KEY (sales_order_id) REFERENCES sales_orders(sales_order_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES stock_items(item_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

-- =========================
-- 17) Returns
-- =========================
CREATE TABLE returns (
  return_id      INT AUTO_INCREMENT PRIMARY KEY,
  sales_order_id INT NOT NULL,
  item_id        INT NOT NULL, -- references stock_items
  return_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  quantity       INT NOT NULL,
  reason         TEXT,
  status         VARCHAR(50) NOT NULL DEFAULT 'Requested',
  FOREIGN KEY (sales_order_id) REFERENCES sales_orders(sales_order_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  FOREIGN KEY (item_id) REFERENCES stock_items(item_id)
    ON UPDATE CASCADE
    ON DELETE NO ACTION
);

-- =========================
-- Insert Data: Branches
-- =========================
INSERT INTO branches (name, location, contact_person) VALUES
('Ramallah Branch', 'Ramallah', 'Saleh'),
('Nablus Branch', 'Nablus', 'Anwar');

-- =========================
-- Insert Data: Warehouses
-- =========================
INSERT INTO warehouses (branch_id, name, location, capacity) VALUES
(1, 'Main Warehouse', 'Ramallah', 1000),
(2, 'North Warehouse', 'Nablus', 700);

-- =========================
-- Insert Data: Managers
-- =========================
INSERT INTO managers (branch_id, name, role, email, phone_number) VALUES
(1, 'Saleh Manager', 'Branch Manager', 'saleh.manager@company.com', '0599001122'),
(2, 'Anwar Manager', 'Branch Manager', 'anwar.manager@company.com', '0599887766');

-- =========================
-- Insert Data: Staff
-- =========================
INSERT INTO staff (branch_id, manager_id, name, role, phone, email) VALUES
(1, 1, 'Saleh', 'Admin', '0599111111', 'saleh@company.com'),
(2, 2, 'Anwar', 'Admin', '0599222222', 'anwar@company.com');

-- =========================
-- Insert Data: User Accounts (ONLY 2 Admins)
-- =========================
INSERT INTO user_accounts (staff_id, username, password_hash, role) VALUES
(1, 'saleh', 'hash_saleh_123', 'Admin'),
(2, 'anwar', 'hash_anwar_123', 'Admin');

-- =========================
-- Insert Data: Customers
-- =========================
INSERT INTO customers (name, contact_information, address, email) VALUES
('Ahmad Ali', '0599001122', 'Ramallah', 'ahmad@example.com'),
('Sara Hasan', '0599887766', 'Nablus', 'sara@example.com'),
('Omar Khaled', '0566778899', 'Hebron', 'omar@example.com');

-- =========================
-- Insert Data: Link Customers <-> User Accounts (N:M)
-- (اختياري) ربط العملاء بالحسابات
-- =========================
INSERT INTO customer_user_accounts (customer_id, user_id) VALUES
(1, 1),
(2, 2);

-- =========================
-- Insert Data: Categories
-- =========================
INSERT INTO categories (name, description, image_path) VALUES
('Dresses', 'Modest long women dresses', 'images/categories/dress.png'),
('Skirts', 'Long and modest skirts', 'images/categories/skirt.png'),
('Blouses', 'Long sleeve women blouses', 'images/categories/blouse.png'),
('Pants', 'Wide and modest pants', 'images/categories/pants.png'),
('Hijabs', 'Hijabs and scarves', 'images/categories/hijab.png'),
('Jackets', 'Long jackets and coats', 'images/categories/jacket.png'),
('Accessories', 'Women fashion accessories', 'images/categories/accessory.png');

-- =========================
-- Insert Data: Items (Original items table)
-- =========================
INSERT INTO items (name, unit_price, stock_quantity, category_id) VALUES
('Long Modest Dress', 180.00, 0, 1),
('Wide Fabric Skirt', 120.00, 0, 2),
('Cotton Long Sleeve Blouse', 90.00, 0, 3),
('Wide Fabric Pants', 110.00, 0, 4),
('Chiffon Hijab', 40.00, 0, 5),
('Long Winter Jacket', 250.00, 0, 6),
('Women Handbag', 150.00, 0, 7);

-- =========================
-- Insert Data: Purchase Orders
-- =========================
INSERT INTO purchase_orders (staff_id, order_date, total_amount, status) VALUES
(1, '2024-01-10', 1000.00, 'Completed'),
(2, '2024-02-05', 800.00, 'Completed');

-- =========================
-- Insert Data: Purchase Order Items (Ternary)
-- =========================
INSERT INTO purchase_order_items (purchase_order_id, item_id, warehouse_id, quantity, unit_price) VALUES
(1, 1, 1, 5, 180.00),
(1, 5, 1, 10, 40.00),
(2, 3, 2, 8, 90.00),
(2, 6, 2, 4, 250.00);

-- =========================
-- Insert Data: Stock Movements
-- =========================
INSERT INTO stock_movements (item_id, warehouse_id, movement_type, quantity, movement_date, reference_type, reference_id) VALUES
(1, 1, 'IN', 5, NOW(), 'PurchaseOrder', 1),
(5, 1, 'IN', 10, NOW(), 'PurchaseOrder', 1),
(3, 2, 'IN', 8, NOW(), 'PurchaseOrder', 2),
(6, 2, 'IN', 4, NOW(), 'PurchaseOrder', 2);

-- =========================
-- Insert Data: Stock Items (Boutique stock_items)
-- =========================
INSERT INTO stock_items (name, description, unit_price, stock_quantity, import_date, category_id, warehouse_id, image_path) VALUES
-- Dresses (Cat 1)
('Long Modest Dress', 'Elegant long modest dress', 220.00, 10, '2024-03-01', 1, 1, 'images/products/dress_1.png'),
('Floral Summer Dress', 'Lightweight floral print long dress', 195.00, 15, '2024-03-02', 1, 1, 'images/products/dress_1.png'),
('Evening Velvet Dress', 'Luxurious velvet dress for occasions', 350.00, 5, '2024-03-03', 1, 1, 'images/products/dress_1.png'),

-- Skirts (Cat 2)
('Black Wide Skirt', 'Comfortable long black skirt', 140.00, 15, '2024-03-05', 2, 1, 'images/products/skirt_1.png'),
('Pleated Midi Skirt', 'Classic pleated skirt in beige', 120.00, 20, '2024-03-06', 2, 1, 'images/products/skirt_2.png'),
('Denim Maxi Skirt', 'Trendy long denim skirt', 110.00, 18, '2024-03-07', 2, 1, 'images/products/skirt_1.png'),

-- Blouses (Cat 3)
('Cotton Long Sleeve Blouse', 'Soft cotton blouse', 100.00, 20, '2024-03-10', 3, 2, 'images/products/blouse_1.png'),
('Silk Formal Blouse', 'Elegant silk blouse for work', 180.00, 12, '2024-03-11', 3, 2, 'images/products/blouse_1.png'),
('White Linen Shirt', 'Breathable linen shirt', 95.00, 25, '2024-03-11', 3, 2, 'images/products/blouse_1.png'),

-- Pants (Cat 4)
('Wide Fabric Pants', 'Modest wide pants', 130.00, 12, '2024-03-12', 4, 2, 'images/products/pants_1.png'),
('High Waisted Trousers', 'Formal high waisted trousers', 150.00, 15, '2024-03-13', 4, 2, 'images/products/pants_1.png'),
('Culottes Culottes', 'Comfortable casual culottes', 110.00, 30, '2024-03-14', 4, 2, 'images/products/pants_1.png'),

-- Hijabs (Cat 5)
('Soft Chiffon Hijab', 'Chiffon hijab in multiple colors', 45.00, 30, '2024-03-15', 5, 1, 'images/products/hijab_1.png'),
('Jersey Instant Hijab', 'Easy to wear jersey hijab', 35.00, 50, '2024-03-16', 5, 1, 'images/products/hijab_1.png'),
('Premium Silk Scarf', 'Printed silk scarf', 85.00, 20, '2024-03-17', 5, 1, 'images/products/hijab_1.png'),

-- Jackets (Cat 6)
('Long Winter Jacket', 'Warm and modest winter jacket', 280.00, 8, '2024-03-18', 6, 2, 'images/products/jacket_1.png'),
('Trench Coat', 'Classic beige trench coat', 240.00, 10, '2024-03-19', 6, 2, 'images/products/jacket_1.png'),
('Cardigan Longline', 'Cozy knitted long cardigan', 160.00, 25, '2024-03-19', 6, 2, 'images/products/jacket_1.png'),

-- Accessories (Cat 7)
('Women Handbag', 'Stylish women handbag', 160.00, 10, '2024-03-20', 7, 1, 'images/products/accessory_1.png'),
('Leather Belt', 'Genuine leather belt', 60.00, 40, '2024-03-21', 7, 1, 'images/products/accessory_1.png'),
('Gold Plated Necklace', 'Minimalist gold necklace', 90.00, 30, '2024-03-22', 7, 1, 'images/products/accessory_1.png');

-- =========================
-- Insert Data: Sales Orders
-- =========================
INSERT INTO sales_orders (customer_id, branch_id, staff_id, status, total_amount) VALUES
(1, 1, 1, 'Completed', 310.00),
(2, 2, 2, 'Pending', 100.00),
(3, 2, 2, 'Completed', 144.00);

-- =========================
-- Insert Data: Invoices
-- =========================
INSERT INTO invoices (sales_order_id, amount, tax, payment_status) VALUES
(1, 310.00, 46.50, 'Paid'),
(2, 100.00, 15.00, 'Unpaid'),
(3, 144.00, 21.60, 'Paid');

-- =========================
-- Insert Data: Sale Items
-- =========================
INSERT INTO sale_items (sales_order_id, item_id, quantity, unit_price, discount) VALUES
(1, 1, 1, 220.00, 0.00),
(1, 5, 2, 45.00, 0.00),
(2, 3, 1, 100.00, 0.00),
(3, 7, 1, 160.00, 10.00);

-- =========================
-- Insert Data: Returns
-- =========================
INSERT INTO returns (sales_order_id, item_id, quantity, reason, status) VALUES
(1, 5, 1, 'Color not suitable', 'Requested'),
(3, 7, 1, 'Size not suitable', 'Approved');

-- =========================
-- Quick Check
-- =========================
SELECT * FROM user_accounts;


SELECT * FROM stock_items;
SELECT * FROM sales_orders;
SELECT * FROM sale_items;
SELECT * FROM items;
