---
title: "Joins in SQL Server (Transact-SQL)"
description: joins in sql server.
author: venkat bodempudi
reviewer: venkat bodempudi
date: 02/16/2024
service: sql
subservice: t-sql
topic: reference
f1_keywords:
  - "JOINS_TSQL"
  - "JOINS IN SQL SERVER"
helpviewer_keywords:
  - "JOINS in SQL Server"
  - "inner join in SQL Server"
  - "left join in SQL Server"
  - "join in sql server"
dev_langs:
  - "TSQL"
monikerRange: "=sqldb-current || sql-server-2016"
---
# Joins in SQL Server

As we know ```SQL Server``` has been created based on two mathematical concepts, they are ```Set Theory``` and ```Predicate Logic```. In set theory, the cartesian product is the basic operation. Joins in ``SQL Server``` also works in the same way as the Cartesian product.

In mathematics, the Cartesian Product of sets A and B is defined as the set of all ordered pairs (x, y) such that x belongs to A and y belongs to B. For example, if A = {1, 2} and B = {3, 4, 5}, then the Cartesian Product of A and B is {(1, 3), (1, 4), (1, 5), (2, 3), (2, 4), (2, 5)}.

When we apply joins between tables, the same cartesian product will happen first. 

Joins are required to return the data from multiple tables. These tables should have common functionally similar column to have a join condition
between tables.

We will understand the joins after taking a look at cross-join (cartesian product) first.
***CROSS JOIN***
When we apply cross join between two tables(TableA and TableB), every row in TableA will have a combination with every row in TableB.
Let's take an example and look at it.

```sql
IF OBJECT_ID('dbo.ProductCategory') IS NOT NULL
	DROP TABLE dbo.ProductCategory;

CREATE TABLE dbo.ProductCategory(
ProductCategoryId INT PRIMARY KEY IDENTITY,
CategoryName VARCHAR(500));
GO

INSERT INTO dbo.ProductCategory(CategoryName) VALUES('Fruits'); 
INSERT INTO dbo.ProductCategory(CategoryName) VALUES('Vegtables'); 
INSERT INTO dbo.ProductCategory(CategoryName) VALUES('Water'); 
INSERT INTO dbo.ProductCategory(CategoryName) VALUES('Dairy Based Food'); 
INSERT INTO dbo.ProductCategory(CategoryName) VALUES('Meat'); 
GO

SELECT * FROM dbo.ProductCategory;
GO



IF OBJECT_ID('dbo.Product') IS NOT NULL
	DROP TABLE dbo.Product;

CREATE TABLE dbo.Product(
ProductId INT PRIMARY KEY IDENTITY,
ProductName VARCHAR(500),
ProductCategoryId INT NOT NULL
);
GO

INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Apple',1); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Manago',1); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Capsicum',2); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Tomato',2); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Milk',4); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Curd',4); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Chicken',5); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Mutton',5); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Pasta',50); 
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Brown Rice',65); 
GO

SELECT * FROM dbo.Product;
GO

SELECT * FROM dbo.ProductCategory
CROSS JOIN
dbo.Product
```
In general, we refer to the left table as the ProductCategory table and the right table as the Product table. Every row from ProductCategory table will combine each row with each row from the product table.

Below is the one-part result of the cross join. Please run the above script to check the full resultset.
![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/7138f574-377e-41fe-8c1a-afeadf9dec55)

## Inner Join
when we apply ```INNER JOIN``` between tables, the result is going to be only the rows which are satisfying the given condition. Non-matching rows will be ignored.

```sql
SELECT 
 PC.ProductCategoryId	
,PC.CategoryName	
,P.ProductId	
,P.ProductName	
 FROM dbo.ProductCategory PC
INNER JOIN
dbo.Product P ON PC.ProductCategoryId=P.ProductCategoryId
```
![Inner Join](https://github.com/bodempudi/CodeSnippets/assets/2835142/247bce69-0327-4fe1-8c43-dd8d2164440e)

## LEFT OUTER JOIN / LEFT JOIN
when we apply ```LEFT JOIN``` between tables, the result is going to be only the rows which are satisfying the given condition plus Non-matching rows from left side table, null values will be returned for the corresponding rows from the right side table.
```sql
SELECT 
 PC.ProductCategoryId	
,PC.CategoryName	
,P.ProductId	
,P.ProductName	
 FROM dbo.ProductCategory PC
LEFT JOIN
dbo.Product P ON PC.ProductCategoryId=P.ProductCategoryId
```
![LEFT JOIN in SQL Server](https://github.com/bodempudi/CodeSnippets/assets/2835142/a8ae48e5-c0c7-437e-83cf-86413ab7f362)

## RIGHT OUTER JOIN / RIGHT JOIN
when we apply ```RIGHT JOIN``` between tables, the result is going to be only the rows which are satisfying the given condition plus Non-matching rows from RIGHT side table, null values will be returned for the corresponding rows from the LEFT side table.
```sql
SELECT 
 PC.ProductCategoryId	
,PC.CategoryName	
,P.ProductId	
,P.ProductName	
 FROM dbo.ProductCategory PC
RIGHT JOIN
dbo.Product P ON PC.ProductCategoryId=P.ProductCategoryId
```
![RIGHT JOIN in SQL Server](https://github.com/bodempudi/CodeSnippets/assets/2835142/74f8d2ec-cdfc-4800-aaee-a46fc02f99f4)

## FULL OUTER JOIN / FULL JOIN
when we apply ```FULL JOIN``` between tables, the result is going to be only the rows which are satisfying the given condition plus Non-matching rows from left side table, plus non-matching rows from right table, null values will be returned for the corresponding rows from the both side tables.
```sql
SELECT 
 PC.ProductCategoryId	
,PC.CategoryName	
,P.ProductId	
,P.ProductName	
 FROM dbo.ProductCategory PC
FULL JOIN
dbo.Product P ON PC.ProductCategoryId=P.ProductCategoryId
```
![full join in SQL server](https://github.com/bodempudi/CodeSnippets/assets/2835142/9120b524-bfce-4efb-9456-5589afa8f356)
