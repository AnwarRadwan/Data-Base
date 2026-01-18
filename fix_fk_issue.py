
import mysql.connector
from mysql.connector import Error

def fix_database_issue():
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

            # 1. Clear stock_movements to avoid conflicts with existing data
            print("Clearing stock_movements table...")
            cursor.execute("TRUNCATE TABLE stock_movements")
            
            # 2. Drop the incorrect Foreign Key
            print("Dropping incorrect foreign key (referencing items)...")
            try:
                cursor.execute("ALTER TABLE stock_movements DROP FOREIGN KEY stock_movements_ibfk_1")
            except Error as e:
                print(f"Warning dropping FK (might not exist): {e}")

            # 3. Add the correct Foreign Key (referencing stock_items)
            print("Adding correct foreign key (referencing stock_items)...")
            cursor.execute("""
                ALTER TABLE stock_movements 
                ADD CONSTRAINT stock_movements_ibfk_1 
                FOREIGN KEY (item_id) REFERENCES stock_items(item_id) 
                ON DELETE CASCADE ON UPDATE CASCADE
            """)

            conn.commit()
            print("Database fixed successfully! stock_movements now references stock_items.")

    except Error as e:
        print(f"Error: {e}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()
            print("Connection closed.")

if __name__ == '__main__':
    fix_database_issue()
