
import mysql.connector
from mysql.connector import Error

def run_sql_file(filename, password):
    print(f"Trying password: {password}")
    try:
        conn = mysql.connector.connect(
            host='localhost',
            user='root',
            password='Anwar@2004'
        )
        if conn.is_connected():
            print("Connected to MySQL server")
            cursor = conn.cursor()
            
            with open(filename, 'r') as f:
                sql_script = f.read()
            
            # Split and execute statements
            statements = sql_script.split(';')
            for statement in statements:
                if statement.strip():
                    try:
                        cursor.execute(statement)
                        # Consume results to avoid "Unread result found"
                        while cursor.nextset():
                            pass 
                    except Error as e:
                        print(f"Skipping statement error: {e}")
            
            conn.commit()
            print("Database setup completed successfully.")
            return True
            
    except Error as e:
        print(f"Failed to connect with password '{password}': {e}")
        return False
    finally:
        if 'conn' in locals() and conn.is_connected():
            conn.close()

passwords = ['0000', 'Anwar@2004', 'root', '']
success = False
for pwd in passwords:
    if run_sql_file('Tables.sql', pwd):
        success = True
        # Update app.py if needed? OR just print the working password
        with open('working_password.txt', 'w') as f:
            f.write(pwd)
        break

if not success:
    print("Could not connect to database with common passwords.")
