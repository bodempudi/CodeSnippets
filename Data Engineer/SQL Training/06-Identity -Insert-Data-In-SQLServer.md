## Identity in SQL Server

Identity in an SQL Server table is a column-level property that you can use/tag/define to the column in a table. Once you define the identity property, SQL Server automatically assigns/generates the value to the column based on the identity property configuration(seed and increment).


```sql

--This will be used many times in your daily application development activities
IF OBJECT_ID('dbo.DimProduct', 'U') IS NOT NULL
  DROP TABLE dbo.DimProduct;
GO

CREATE TABLE dbo.DimProduct
(
	ProductKey INT IDENTITY(1,1) PRIMARY KEY,
	ProductName VARCHAR(500),
	UnitPrice DECIMAL(15,2),
	ProductCategory VARCHAR(500)
)
GO

INSERT INTO  dbo.DimProduct([ProductName], [UnitPrice], [ProductCategory]) VALUES('Aqua Gulf Water Bottles 1.5 Litters',0.295,'Drinking Water');

```
when you have an identity property defined on top of a column in the SQL Server table, you should not or not need to pass an explicit value to the column, unless you mention the identity property on.

Once you execute the above insert statement, below is the result.

![Identity](https://github.com/bodempudi/CodeSnippets/assets/2835142/6111a89d-f456-4572-8a83-df32afc4de62)

Automatically value 1 has been added to the ProductKey column in the DimProduct table.

when you are using insert statement to insert the data to the table, We recommend you add all your columns and values also in the same order. When you do not
mention your column explicitly you should remember the ordinal positions of the column. This might not be feasible in all cases. So, adding columns in the insert
statement helps you ensure the values you insert into the correct columns only. 

```sql

INSERT INTO  dbo.DimProduct([ProductName], [UnitPrice], [ProductCategory]) 
VALUES('Aqua Gulf Water Bottles 1.5 Litters',0.295,'Drinking Water'),
('Italy Apples',0.395,'Fruits'),
('Paistan Apples',0.495,'Fruits'),
('Jordan Onions',0.595,'Vegtables'),
('Indian Watermelon',0.230,'Fruits');
```
Below is the result once you insert the data.


![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/2971760a-337d-4091-8e3d-51e837255d0e)

when you delete data from a table, the identity value of a column will not reset whereas you truncate the table. The identity value of a column will reset and start with the configured seed.
This is one important difference between `DELETE and Truncate`.

There are a few important functions available for Identity property, which will be helpful to get the last generated identity value.

```syntaxsql
SELECT SCOPE_IDENTITY() [SCOPE_IDENTITY],@@IDENTITY [AtAtIdentity],IDENT_CURRENT('Customer') [IDENT_CURRENT];
GO
```

Understand each function and the differences among them.
