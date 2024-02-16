---
title: "DELETE, UPDATE IN (Transact-SQL)"
description: delete, update in SQL Server.
author: venkat bodempudi
reviewer: venkat bodempudi
date: 02/16/2024
service: sql
subservice: t-sql
topic: reference
f1_keywords:
  - "DELETE_TSQL"
  - "DELETE IN SQL"
  - "UPDATE_TSQL"
  - "UPDATE IN SQL"
helpviewer_keywords:
  - "UPDATE in SQL Server"
  - "update in SQL Server"
  - "Delete in SQL Server"
  - "UPDATE in SQL Server"
  - "UPDATE, DELETE in SQL Server"
dev_langs:
  - "TSQL"
monikerRange: "=sqldb-current || sql-server-2016"
---
## Update, Delete in SQL Server

Update and Delete both are DML commands in SQL Server. 
Becare full with these two commands, once you update or delete the data. There is no way to get the data back unless your transaction is committed yet.
or you have a backup of your database.

```sql

DELETE FROM DimProduct;

DELETE FROM DimProduct
WHERE  ProductCategory='Drinking Water';
```
