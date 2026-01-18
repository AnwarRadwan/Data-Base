
import mysql.connector
from mysql.connector import Error

def seed_boutique():
    config = {
        'host': 'localhost',
        'user': 'root',
        'password': 'Anwar@2004',
        'database': 'SileenSystem'
    }

    try:
        conn = mysql.connector.connect(**config)
        if conn.is_connected():
            print("Connected to SileenSystem database.")
            cursor = conn.cursor()

            # 1. Add image_path column if not exists for stock_items
            try:
                print("Checking for image_path column in stock_items...")
                cursor.execute("ALTER TABLE stock_items ADD COLUMN image_path VARCHAR(255)")
                print("Added image_path column to stock_items.")
            except Error as e:
                if e.errno == 1060:
                    print("image_path column already exists in stock_items.")
                else:
                    print(f"Comparison error (likely already exists): {e}")

            # 1.5 Add image_path column to categories
            try:
                print("Checking for image_path column in categories...")
                cursor.execute("ALTER TABLE categories ADD COLUMN image_path VARCHAR(255)")
                print("Added image_path column to categories.")
            except Error as e:
                if e.errno == 1060:
                    print("image_path column already exists in categories.")
                else:
                    print(f"Comparison error (likely already exists): {e}")

            # 2. Update Data
            print("Updating database with Boutique items...")
            
            # Disable FK checks to allow truncation
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            
            # Clear tables
            tables_to_clear = ['sale_items', 'returns', 'stock_items', 'categories']
            for table in tables_to_clear:
                cursor.execute(f"TRUNCATE TABLE {table}")
                print(f"Truncated {table}.")

            # Insert Categories
            print("Inserting Categories...")
            categories_sql = """
            INSERT INTO categories (category_id, name, description, image_path) VALUES
            (1, 'Skirt', 'Stylish skirts for all occasions', 'images/categories/skirt.png'),
            (2, 'Dress', 'Elegant evening and casual dresses', 'images/categories/dress_cat.png'),
            (3, 'Hijab', 'Premium quality hijabs', 'images/categories/hijab.png'),
            (4, 'Jacket', 'Fashionable jackets and outerwear', 'images/categories/jacket.png'),
            (5, 'Accessory', 'Beautiful accessories and jewelry', 'images/categories/accessory.png');
            """
            cursor.execute(categories_sql)

            # Insert Stock Items with Images
            print("Inserting Stock Items (Products)...")
            stock_items_sql = """
            INSERT INTO stock_items (name, description, stock_quantity, unit_price, category_id, image_path) VALUES
            -- Skirt Products (category_id = 1)
            ('Pleated Midi Skirt', 'Elegant black pleated midi skirt', 15, 89.99, 1, 'images/products/skirt_1.png'),
            ('A-Line Long Skirt', 'Classic beige A-line long skirt', 12, 79.99, 1, 'images/products/skirt_2.png'),
            ('Pencil Skirt', 'Professional black pencil skirt', 20, 65.00, 1, 'images/products/skirt_1.png'),
            
            -- Dress Products (category_id = 2)
            ('Silk Evening Dress', 'Premium silk evening dress in soft pink', 10, 250.00, 2, 'images/products/dress_1.png'),
            ('Emerald Green Dress', 'Elegant emerald green satin dress', 8, 280.00, 2, 'images/products/green_dress.png'),
            ('Classic Beige Dress', 'Timeless beige long dress', 15, 199.00, 2, 'images/products/dress_1.png'),
            
            -- Hijab Products (category_id = 3)
            ('Chiffon Premium Hijab', 'Soft cream chiffon hijab', 50, 35.00, 3, 'images/products/hijab_1.png'),
            ('Jersey Cotton Hijab', 'Comfortable dusty rose jersey hijab', 40, 28.00, 3, 'images/products/hijab_1.png'),
            ('Silk Blend Hijab', 'Luxurious silk blend hijab in beige', 30, 55.00, 3, 'images/products/hijab_1.png'),
            
            -- Jacket Products (category_id = 4)
            ('Wool Blazer', 'Classic beige wool blazer', 8, 189.00, 4, 'images/products/jacket_1.png'),
            ('Leather Jacket', 'Trendy black leather jacket', 6, 250.00, 4, 'images/products/jacket_1.png'),
            ('Trench Coat', 'Elegant camel trench coat', 10, 220.00, 4, 'images/products/jacket_1.png'),
            
            -- Accessory Products (category_id = 5)
            ('Gold Hoop Earrings', 'Elegant gold hoop earrings', 25, 45.00, 5, 'images/products/accessory_1.png'),
            ('Designer Handbag', 'Premium beige leather handbag', 5, 350.00, 5, 'images/products/accessory_1.png'),
            ('Pearl Necklace', 'Classic freshwater pearl necklace', 15, 125.00, 5, 'images/products/accessory_1.png');
            """
            cursor.execute(stock_items_sql)
            

            # Restore FK checks
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
            
            conn.commit()
            print("Boutique data seeded successfully!")

    except Error as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()
            print("Connection closed.")

if __name__ == '__main__':
    seed_boutique()
