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
INSERT INTO dbo.Product(ProductName,ProductCategoryId) VALUES('Brown Ric',65); 
GO

SELECT * FROM dbo.Product;
GO

SELECT * FROM dbo.ProductCategory
CROSS JOIN
dbo.Product
```
In general, we refer to the left table as the ProductCategory table and the right table as the Product table. Every row from ProductCategory table will combine each row with each row from the product table.

Below is the one part result of the cross join. Please run the above script to check the full resultset.
![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/7138f574-377e-41fe-8c1a-afeadf9dec55)

## Inner Join
