# =====================================================================================
# Purpose: This Python script load data from the bronze layer to silver layer
# It call stored procedures to peform ETL (Extract, Transform, Load) on bronze layer  
# It Truncate the tables and load Data to silver layer tables
# ====================================================================================

import mysql.connector
import time
def load_silver(table_names):
    proc_names=[]
    for table_name in table_names:
        name = "silver.load_" +table_name[0]
        proc_names.append(name)
    total_duration = 0
    for i in range(len(proc_names)):
        start_time = time.perf_counter()
        print(f">> Truncating and Inserting Data in table {table_names[i][0]}.")
        try:
            cursor.callproc(proc_names[i])
            print('='*50)
            print(f"Successfully loaded data into table {table_names[i][0]}")
            
        except mysql.connector.Error as e:
            print(f"Fail Loading Data Error: {e}")
        end_time = time.perf_counter()
        duration = end_time-start_time
        print(f">> Load Duration:{duration:.2f} seconds")
        print('='*50)
        total_duration+= duration

    return total_duration


try:
    connection = mysql.connector.connect(
        host = "localhost", password = "password",
        user = "root", database = "sys"
    )

    cursor = connection.cursor()
    cursor.execute("Use Silver")
    tables = cursor.execute("SHOW TABLES")
    tables = cursor.fetchall()

    print("="*50)
    print("LOADING DATA INTO SILVER LAYER")
    print("="*50)

    total_time = load_silver(tables)

    print("-"*50)
    print(f"Total Loading Time: {total_time:.2f}")
    print("-"*50)

except mysql.connector.Error as e:
    print("Error: {e}")
