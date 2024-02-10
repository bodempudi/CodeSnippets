## Identity in SQL Server

Identity in SQL Server table is a property that you can use/tag/define to the column in a table. Once you define the identity property, SQL Server automatically assigns the value to the column based on identity property configuration.


```sql
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
when you have identity property defined on top of a column in SQL Server table, you should not pass an explicit value to the column, unless you mention
identity property on.

Once you execute the above insert statement, below is the result.

![Identity](https://github.com/bodempudi/CodeSnippets/assets/2835142/6111a89d-f456-4572-8a83-df32afc4de62)

Automatically value 1 has been added to the ProductKey column in DimProduct table.

