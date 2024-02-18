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

Case statement in SQL Server comes in two flavors. One is in the form of a Simple case statement and the other one is in the form of a Search(searchable) case statement. Case statement is like writing if, else if, and else statements in your sql query. When the given condition is satisfied the respective expression will be evaluated and the result returned.

Case statement is handy in stored procedures to validate the user input. For example, the given parameter is null, or the given parameter value is against a range of values. These types of validations can be done easily with a Case statement.

```syntaxsql
  CASE
      WHEN CONDITION THEN EXPRESSION
      WHEN CONDITION THEN EXPRESSION
      ELSE                        --This can be optional, null value will be returned in case of no matches
          DEFAULT EXPRESSION
      END AS AliasName
```

Case statement is something similar to a Switch(Simple Case Statement) and if, else if, else(searchable) statement. These two forms of case can be written either in Query or in Stored Procedure.

```syntaxsql
USE [Sample];
GO
--Simple CASE Statement
SELECT TOP (1000) [CustomerID]
      ,[FirstName]
      ,[LastName]
      ,[PhoneNumber]
      ,[EmailAddress]
      ,[DateOfBirth]
      ,[City]
      ,[Priority]
      ,[CreateDate]
	  ,[PriorityDescription]=CASE [Priority] --see this, this is similar to switch statement
			WHEN 0 THEN 'Executive Leadership Team'
			WHEN 1 THEN 'Directors'
			WHEN 2 THEN 'Senior Managers'
			WHEN 3 THEN 'Managers'
			WHEN 4 THEN 'Senior Developers'
			WHEN 5 THEN 'Junior Developers'
			ELSE 'Support Staff' END
  FROM [dbo].[Customer]
```

