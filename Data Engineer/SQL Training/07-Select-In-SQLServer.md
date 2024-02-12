## Select in SQL Server

`Select` is the basic data retrieval operation in SQL Server. You might be retrieving data from a table or view.

Let's make our hands dirty now, we will write SQL queries using select caluse.

Let's create a table first and insert data into it.

```sql
CREATE TABLE dbo.Product(
ProductId INT IDENTITY PRIMARY KEY,
Name NVARCHAR(500),
UnitPrice DECIMAL(10,3),
ProductCategory NVARCHAR(500));
```
