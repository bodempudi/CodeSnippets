
USE AdventureWorksDW2016;
GO

Server
	Database
		--Schema1
			--Table1
			--Table2

		--Schema2
			--Table1
			--Table2


		--Schema3

Use Sample

SELECT * FROM Sample.dbo.CardMaster

SELECT * FROM Sample.dbo.CardMaster


SELECT * FROM Sample.dbo.CardMaster


Sample.dbo.CardMaster
Sample.Sales.TableName
Sample.Procution.Table
Sample -- database name
dbo -- schema name
CardMaster -- Table name


--Creating a schema
CREATE SCHEMA Schema1;
GO

CREATE SCHEMA Schema2;
GO

CREATE TABLE Schema1.Table2(
id int
);


CREATE TABLE Schema2.Table2(
id int
);

 GO

SELECT @@SERVERNAME

SELECT @@VERSION


--all tables in the database

SELECT * FROM INFORMATION_SCHEMA.TABLES
SELECT * FROM sys.tables

--TABLES
--VIEWS
--COLUMNS
--FUNCTIONS
--STORED PROCEDURES
--TRIGGERS

SELECT * FROM INFORMATION_SCHEMA.ROUTINES--fu
SELECT * from sys.procedures
--ctrl+r
select * from INFORMATION_SCHEMA.COLUMNS

--creating a table in SQL Server
--DDL Commands
--CREATE,TRUNCATE,DROP
Select * from INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'SampleTable'

CREATE TABLE dbo.SampleTable(
Id INT,
FullName VARCHAR(500)
);
--DML Commands
--TCL Commands




Database -- Business
Production
Sales
