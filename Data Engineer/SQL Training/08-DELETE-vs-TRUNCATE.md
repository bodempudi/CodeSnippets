---
title: "Delete vs Truncate (Transact-SQL)"
description: Delete Vs Truncate in SQL Server.
author: venkat bodempudi
reviewer: venkat bodempudi
date: 02/16/2024
service: sql
subservice: t-sql
topic: reference
f1_keywords:
  - "DELETE_TSQL"
  - "TRUNCATE_TSQL"
helpviewer_keywords:
  - "DELETE Clause"
  - "delete rows in sql server"
  - "delete rows in sql server"
  - "truncate in sql server"
dev_langs:
  - "TSQL"
monikerRange: "=sqldb-current || sql-server-2016"
---
## Delete vs Truncate in SQL Server

There are many differences between Delete and Truncate in SQL Server. But very few of them are very important.

1. Delete is a DML command whereas Truncate is a DDL command.
2. ```Deletes specific rows or all rows from a table, with individual rows logging into logfile. Logging individual rows into logfile increases size of the logfile, time and resource consumption operation. Truncate, truncate the whole table without individual row logging, only the pages deallocated will get logged. So it completes its operation quickly with less resources. This is an important difference. At summary, where clause with truncate is not possible. where clause with delete is possible```.
3. There is no difference between delete and truncate in case of having it in a transaction(data can be rolled back in a transaction in case of both delete and truncate).
4. Both commands remove the data from a table, There is no way to get the data back unless you have a backup of your database.
5. Identity resets its value in case of truncate, it won't reset in case of delete.
6. you can fire triggers when a delete operation occurs, in the case of truncate we can not do that.
7. we can truncate specific partitions data using truncate, that is not possible using delete.
