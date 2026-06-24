# ====================================
# Purpose: This Python script load data from the external csv files into mysql tables
# It Truncate the tables and load Data from csv files
# Warning: Path of files must be kept same or change for proper data ingestion
# ====================================

import mysql.connector
import time
def load_data(table_name,file_path):

    start_time = time.perf_counter()

    truncate_query = f"TRUNCATE TABLE {table_name}"
    load_query = f"""
        LOAD DATA LOCAL INFILE "{file_path}"
        INTO TABLE {table_name}
        FIELDS TERMINATED BY ","
        ENCLOSED BY '"'
        LINES TERMINATED BY "\r\n"
        IGNORE 1 LINES
        """
    try:
        print(f">> Truncating Table {table_name}")
        cursor.execute(truncate_query)

        print(f">> Inserting Data into: {table_name}")
        cursor.execute(load_query)
        print('='*50)
        print(f"Successfully loaded {cursor.rowcount} into table {table_name}")
        print('='*50)
    except mysql.connector.Error as err:
        print(f"Error Occured: {err}")
    finally:
        end_time = time.perf_counter()
        time_difference = end_time-start_time
        print('-'*50)
        print(f">> Load Duration: {time_difference:.2f} seconds")
        print('-'*50)
    return time_difference
    

cnx = mysql.connector.connect(
    user = "root", password = "password",
    host = "localhost", database = "bronze",
    allow_local_infile = True
)

cursor = cnx.cursor()

# Fetch table names of Bronze Layer
tables = cursor.execute('SHOW TABLES')
tables = cursor.fetchall()

# Path of Files to load data from
files_path = [
    "D:/source_crm/cust_info.csv",
    "D:/source_crm/prd_info.csv",
    "D:/source_crm/sales_details.csv",
    "D:/source_erp/cust_az12.csv",
    "D:/source_erp/loc_a101.csv",
    "D:/source_erp/px_cat_g1v2.csv"
    ]

print("="*20)
print("LOADING DATA INTO BRONZE LAYER")
print("="*20)

total_loading_time = 0

for i in range(len(files_path)):
    total_loading_time+= load_data(tables[i][0],files_path[i])

print('='*50)
print(f"Total Loading time of Bronze layer = {total_loading_time:.2f}")
print('='*50)

cnx.commit()
cursor.close()
cnx.close()
