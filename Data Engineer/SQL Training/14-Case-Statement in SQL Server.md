---
title: "Case Statement - (Transact-SQL)"
description: Case statement in SQL Server.
author: venkat bodempudi
reviewer: venkat bodempudi
date: 02/17/2024
service: sql
subservice: t-sql
topic: reference
f1_keywords:
  - "CASE_STATEMENT_TSQL"
  - "CASE Statement in SQL Server"
helpviewer_keywords:
  - "CASE Statement in SQL Server"
  - "CASE Statement in SQL Server"
dev_langs:
  - "TSQL"
monikerRange: "=sqldb-current || sql-server-2016"
---

We can use case statements in SQL Server to derive a new column as part of your result set. This derivation will be based on existing columns from tables. In the query, we write this case statement as an expression everywhere (select/join condition, update set statement, group by, order by).

Case statement in SQL Server comes in two flavors. One is in the form of a Simple case statement and the other one is in the form Search(searchable) case statement. Case statement is like writing if, else if, else statements in your sql query. When the given condition is satisfied the respective expression will be evaluated and result will be returned.

Case statement is very useful in stored procedures to validate the user input. For example, the given parameter is null, or the given parameter value is against a range of values. These types of validations can be done easily with a Case statement.

```syntaxsql
  CASE
      WHEN CONDITION THEN EXPRESSION
      WHEN CONDITION THEN EXPRESSION
      ELSE
          DEFAULT EXPRESSION
      END AS AliasName
```

