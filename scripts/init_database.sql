
/*
Script Purpose:
This script creates a database named as DataWarehouse and three schemas named as bronze, silver 
and gold

Warning: 
If Database and schema with above mentioned names already exists. Running script will 
throw an error.
Make sure to delete old database and schemas if their names match with above mentioned database 
and schema names.

*/

-- Create Database
CREATE DATABASE DataWarehouse;
USE DataWarehouse;

-- Create Schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA Gold;
