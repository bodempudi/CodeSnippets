---
title: "Where vs having (Transact-SQL)"
description: Difference between where and having clause in SQL Server.
author: venkat bodempudi
reviewer: venkat bodempudi
date: 02/16/2024
service: sql
subservice: t-sql
topic: reference
f1_keywords:
  - "where clause in SQL Server"
  - "having clause in SQL Server"
helpviewer_keywords:
  - "where clause in SQL Server"
  - "having clause in SQL Server"
  - "autonumbers, having clause in SQL Server"
dev_langs:
  - "TSQL"
monikerRange: "=sqldb-current || sql-server-2016"
---
## Group by in SQL Server

```Group by``` in SQL Server groups the rows with same values to generate the summary result. 

Let's take the below example to understand the result.

![Group by in SQL Server](https://github.com/bodempudi/CodeSnippets/assets/2835142/2a025292-cd12-46f8-ad8f-5533aefa635e)

Now we will try to find out max price and min price in each product category.
Every product category will have many products in them. We have to aggregate the unit price column.
Here product category is the non-aggregated column and unit price is the aggregated column.

![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/4d2f7283-90c9-4137-92da-9f190a0d9db1)

In the above image, SQL Server engine takes all the rows with same value and it groups them. It will find the minimum of unit price from those rows and the maximum of unit price from those rows and displays the summary result. Here we will loose the remaining columns data.

Now lets take a look at understanding the difference between WHERE and HAVING.

where clause is going to be used to filter the individual rows. Having clause is used to filter groups after aggregation.
Where applies the filter on top an individual row where as having applies filter on top of group(summary)

```sql
SELECT
 *
FROM DimProduct
 where  ProductCategory='Drinking Water'
 


SELECT
 [ProductCategory],MIN( [UnitPrice]) MinUnitPrice,MAX( [UnitPrice]) MaxUnitPrice
FROM DimProduct
 GROUP BY [ProductCategory]
 HAVING MIN(UnitPrice) > 0.200
```
![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/228d85fb-0340-4990-a01d-4d0655e2d2e2)
