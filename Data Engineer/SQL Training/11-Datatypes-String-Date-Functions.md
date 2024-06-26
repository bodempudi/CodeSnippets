## Data types in SQL Server

We have numerous datatypes available in SQL Server. 
  1. string/Unicode-based string datatypes
  2. exact number based datatypes
  3. approximate number based datatypes
  4. datetime based datatypes
  5. blob based datatypes.

In every data model(One Specific business problem), we will have many entities(tables), and each entity(table) will have many attributes (columns)/fields(columns). Each field/column can hold different types of data. Let's take the Employee entity as an example, it will have many attributes(columns) like EmployeID, FirstName, LastName, MiddleName, DateOfBirth, Salary, ContactNumber, IsActive, etc. In the data model for every attribute, we will define the specific data type.

When you are learning/understanding the concepts in SQL Server, there are a few model databases(AdventureWorks) available from Microsoft. We can download the
backup file of the database and restore it locally. Go through the table columns and observe the defined datatypes. You will understand the exact usage of the datatypes.

```
Datatype defines the type of data that a column/variable/parameter can contain/hold permanently in the table,
temporarily in stored procedure/functions as a parameter, temporarily in a variable in SQL Server in the defined scope.
```

## BIT
This data type is similar to the boolean data type in programming languages. In most cases, this data type will used to define the status of the record/row in a table.
Either 1 or 0 will be the possible values for this data type that it can hold. 1 is similar to true and 0 is similar to false. It accepts other numerical values as its values, try inserting other than 1 and 0 and verify how it works.

  Let's take an example 

```sql
IF OBJECT_ID('dbo.Employee') IS NOT NULL
  DROP TABLE dbo.Employee;

CREATE TABLE dbo.Employee(
EmployeeId INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(500),
MiddleName NVARCHAR(500),
LastName NVARCHAR(500),
Salary DECIMAL(10,3),
DateOfBirth DATE,
IsActive BIT--1 - Active Employees in the organization, 0 - inactive employees in the organization
);
```

## string 
We use these datatypes (char/nchar/varchar/nvarchar) to store text-based values in the columns. Like Names, Gender, Address, Description, etc. 

Char - fixed-length representation
Varchar - variable length representation
NCHAR/NVARCHAR - these types we will use to store any local language text descriptions in the columns. 
Ex: Arabic Description, Chinese Description. When we add data to the NVARCHAR columns
make sure of using N'yourvalue'. N is nothing but national.

```sql
CREATE TABLE dbo.Employee(
EmployeeId INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(500),
MiddleName NVARCHAR(500),
LastName NVARCHAR(500),
Address NVARCHAR(500),
AddressInArabic NVARCHAR(500),
Salary DECIMAL(10,3),
DateOfBirth DATE,
IsActive BIT--1 - Active Employees in the organization, 0 - inactive employees in the organization
);
```

```sql
INSERT INTO dbo.Employee( [FirstName], [MiddleName], [LastName], [Address],
AddressInLocalLanguage, [Salary], [DateOfBirth], [IsActive]) 
VALUES('Venkat',NULL,'Bodempudi','Hyderabad',N'హైదరాబాద్',10000,'1990-10-16',1);
GO

SELECT * from Employee
```

![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/3ee28e5b-81ce-44c6-a061-31b38d1e7572)

Now see what will happen without N.

```sql

INSERT INTO dbo.Employee( [FirstName], [MiddleName], [LastName], [Address],
AddressInLocalLanguage, [Salary], [DateOfBirth], [IsActive]) 
VALUES('Kiran',NULL,'Aruri','Hyderabad','హైదరాబాద్',10000,'1991-10-16',1);
GO

SELECT * from Employee

```
![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/cac8fa15-fe3d-4213-9fe4-80674dfc2fd1)




## Exact Numbers

We use these datatypes (smallint/int/bigint) to store the exact numbers, which means the numbers without any decimal places. For example, numbers like age, phone numbers, Pincode(postal code), etc.
    Ex: Primary Key Columns, Foreign Key Columns, Audit Columns, Records Counts, Order Quantity.

```sql
CREATE TABLE dbo.Employee(
EmployeeId INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(500),
MiddleName NVARCHAR(500),
LastName NVARCHAR(500),
Address NVARCHAR(500),
AddressInArabic NVARCHAR(500),
Age SMALLINT,
ContactNumber BIGINT,
Salary DECIMAL(10,3),
DateOfBirth DATE,
IsActive BIT--1 - Active Employees in the organization, 0 - inactive employees in the organization
);
```

## Approximate Numbers

We use these data types(decimal/money/float) to store numbers with fractional values (SalesAmount, ProductionCost, UnitPrice, Balance etc.)


```sql
CREATE TABLE dbo.Employee(
EmployeeId INT PRIMARY KEY IDENTITY,
FirstName NVARCHAR(500),
MiddleName NVARCHAR(500),
LastName NVARCHAR(500),
Address NVARCHAR(500),
AddressInArabic NVARCHAR(500),
Age SMALLINT,
ContactNumber BIGINT,
Salary DECIMAL(10,3),
DateOfBirth DATE,
IsActive BIT--1 - Active Employees in the organization, 0 - inactive employees in the organization
);
```

We mostly use DECIMAL datatype to store the approximate numbers in an SQL Server. 

There is a data type called VARCHAR(MAX)/NVARCHAR(MAX) to store text/string where we do not know the size of the incoming text (Ex: Comments). Ensure the usage of this data type because there are some performance issues with this data type as it consumes more memory to store the provided text.

BLOB/image datatypes will be used to store images in the database.

## Date / TIME / DATETIME / SMALLDATETIME / DATETIME2 data types

Whenever it is required to store Date, Time, Datetime, and datetime with required fractional time(milliseconds), We can consider using these datatypes
appropriately for columns in tables.

Ex: AddedDate, ModifiedDate, BirthDate, JoiningDate, DueDate, OrderDate, ShipDate, SwipeInTime, SwipeOutTime etc.

## string functions in SQL Server
We have numerous string functions available in SQL Server, which we can use based on our requirements. We will cover the most important functions.

UPPER, LOWER, CHARINDEX, LTRIM, RTRIM, LEFT, RIGHT, REPLACE, REVERSE, STUFF.

All these functions are self-explanatory and can find the syntaxes on the Microsoft website.

## Date functions in SQL Server

We have numerous DATE functions available in SQL Server, which we can use based on our requirements. We will cover the most important functions.

YEAR(), MONTH(), DATE(), DATETIMEFROMPARTS(), GETDATE(), EOMONTH(), DATEADD(), DATEPART(), GETUTCDATE(), DATENAME(), DATEDIFF(), ISDATE(), FORMAT()
other functions as well. All these functions are self-explanatory and can find the syntaxes on the Microsoft website.

