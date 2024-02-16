## Select in SQL Server

`Select` is the basic data retrieval operation in `SQL Server`. You may be retrieving data from a table or view.

Let's make our hands dirty now, we will write `SQL` queries using select clause.

Let's create a table first and insert data into it.

```sql
CREATE TABLE dbo.Customer
(CustomerID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
FirstName VARCHAR(25) NOT NULL,
LastName VARCHAR(25) NOT NULL,
PhoneNumber VARCHAR(15) NOT NULL,
EmailAddress VARCHAR(25) NULL,
DateOfBirth DATE NOT NULL,
City VARCHAR(500),
Priority INT NOT NULL,
CreateDate DATETIME NOT NULL)ON [PRIMARY]
GO

ALTER TABLE [dbo].[Customer] ADD CONSTRAINT [DF_Customer_CreateDate] 
DEFAULT (getdate()) FOR [CreateDate]
GO

--Inserting data into the table
INSERT INTO dbo.Customer([FirstName], [LastName], [PhoneNumber], [EmailAddress],[DateOfBirth],  [City], [Priority])
VALUES('Adam','Bob',9234127894,'adam.bob@gmail.com','19890321','Houston',1)
,('Susan','Helen',9234137894,'Susan.Helen@gmail.com','19891221','LosAngels',1)
,('Mary','Kathy',9234147894,'Mary.Kathy@gmail.com','19880221','Ausit',1)
,('Karen','Carol',9234157894,'Karen.Carol@gmail.com','19880321','San Diego',0)
,('Patracia','Mary',9234167894,'Patracia.Mary@gmail.com','19870321','San Antonio',0)
,('Adam','Joe',9234177894,'Adam.Joe@gmail.com','19860321','Fort Worth',0)
,('Cathy','Sierra',9234187894,'Cathy.Sierra@gmail.com','19900321','Seattle',5)
,('Tom','Root',9234197894,'Tom.Root@gmail.com','19910321','Indianapolis',2)
,('Jeo','Root',9235127894,'Jeo.Root@gmail.com','19920321','Dallas',3)
,('Brain','Sure',9434127894,'Sure.bob@gmail.com','19900321','Phoenix',4)

```

Let's start writing the ```select``` statements now.

Below is the basic `SELECT` we write every time.
Here's some information on how to use the `SELECT` statement in SQL Server to retrieve data from a table or view.

To retrieve all the columns in the table, you can use the following `SELECT` statement:

```sql
SELECT * FROM dbo.Customer;
```

However, it's generally best practice to explicitly specify the columns you want to retrieve, like below:

```sql
SELECT
    [CustomerID],
    [FirstName],
    [LastName],
    [PhoneNumber],
    [EmailAddress],
    [DateOfBirth],
    [City],
    [Priority],
    [CreateDate]
FROM dbo.Customer;
```

If you want to retrieve a specific customer based on a filter, you can use the `WHERE` clause like below:

```sql
SELECT
    [CustomerID],
    [FirstName],
    [LastName],
    [PhoneNumber],
    [EmailAddress],
    [DateOfBirth],
    [City],
    [Priority],
    [CreateDate]
FROM dbo.Customer
WHERE CustomerID = 1;
```
```Where``` clause will be used to filter the ***data/rows/records*** based on the given value/condition. We can define any number of conditions/predicates we want.

Finally, if you want to retrieve multiple customers based on a filter, you can use the `IN` operator like this:

```sql
SELECT
    [CustomerID],
    [FirstName],
    [LastName],
    [PhoneNumber],
    [EmailAddress],
    [DateOfBirth],
    [City],
    [Priority],
    [CreateDate]
FROM dbo.Customer
WHERE CustomerID IN (1, 2, 3);
```
After learning how to filter numerical columns with basic SQL statements, it's time to write queries for filtering columns with string/varchar data types.
```sql
--Return all the customers from Austin City
SELECT
    [CustomerID],
    [FirstName],
    [LastName],
    [PhoneNumber],
    [EmailAddress],
    [DateOfBirth],
    [City],
    [Priority],
    [CreateDate]
FROM dbo.Customer
WHERE City IN ('Austin')
```
All of the queries mentioned above are exact match queries. It's time to move on to pattern-based match queries.

```sql
SELECT
[CustomerID], [FirstName], [LastName], [PhoneNumber], [EmailAddress], [DateOfBirth], [City], [Priority], [CreateDate]
FROM Customer
WHERE LastName LIKE '%ar%'
```
The above query returns all the rows from the customer table where LastName contains value **ar** anywhere in the lastname column.


```sql
SELECT
[CustomerID], [FirstName], [LastName], [PhoneNumber], [EmailAddress], [DateOfBirth], [City], [Priority], [CreateDate]
FROM Customer
WHERE LastName LIKE 'ar%'
```
The above query returns all the rows from the customer table where LastName starts with a value **ar**.

```sql
SELECT
[CustomerID], [FirstName], [LastName], [PhoneNumber], [EmailAddress], [DateOfBirth], [City], [Priority], [CreateDate]
FROM Customer
WHERE LastName LIKE '%ar'
```
The above query returns all the rows from the customer table where LastName ends with a value **ar**.

Between is another operator can be used to filter the data.

```sql
SELECT
[ProductKey], [ProductName], [UnitPrice], [ProductCategory]
FROM DimProduct
WHERE UnitPrice BETWEEN 0.250 AND 0.450
```
