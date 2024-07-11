import os
import psycopg2
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# PostgreSQL connection parameters
db_host = os.getenv("POSTGRES_HOST")
db_port = os.getenv("POSTGRES_PORT")
db_user = os.getenv("POSTGRES_USER")
db_password = os.getenv("POSTGRES_PASSWORD")
db_name = os.getenv("POSTGRES_DB_NAME")

# SQL commands to create schemas and grant privileges
sql_commands = [
    "CREATE SCHEMA IF NOT EXISTS n8n_core AUTHORIZATION {};".format(db_user),
    "CREATE SCHEMA IF NOT EXISTS keycloak AUTHORIZATION {};".format(db_user),
    "GRANT ALL PRIVILEGES ON SCHEMA n8n_core TO {};".format(db_user),
    "GRANT ALL PRIVILEGES ON SCHEMA keycloak TO {};".format(db_user)
]

def execute_sql(sql_commands):
    conn = None
    try:
        # Connect to the PostgreSQL server
        conn = psycopg2.connect(
            database=db_name,
            user=db_user,
            password=db_password,
            host=db_host,
            port=db_port
        )

        # Create a cursor object using the cursor() method
        cursor = conn.cursor()

        # Execute SQL commands
        for command in sql_commands:
            cursor.execute(command)

        # Commit changes
        conn.commit()

        print("Initialization complete.")

    except psycopg2.Error as e:
        print("Error executing SQL commands:", e)

    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    execute_sql(sql_commands)