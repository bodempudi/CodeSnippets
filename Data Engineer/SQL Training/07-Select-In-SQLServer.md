## Select in SQL Server

`Select` is the basic data retrieval operation in SQL Server. You might be retrieving data from a table or view.

Let's make our hands dirty now, we will write SQL queries using select caluse.

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


```
