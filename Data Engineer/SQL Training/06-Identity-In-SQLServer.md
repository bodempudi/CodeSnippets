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
```
