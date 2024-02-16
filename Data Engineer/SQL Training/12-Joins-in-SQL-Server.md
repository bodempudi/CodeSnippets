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
```
