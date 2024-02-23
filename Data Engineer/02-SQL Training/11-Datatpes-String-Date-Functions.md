## Datatypes in SQL Server

We have numerous datatypes available in SQL Server. 
  1. string/unicode-based string datatypes
  2. exact number based datatypes
  3. approximate number based datatypes
  4. datetime based datatypes
  5. blob based datatypes.

```
**Data type** defines the type of data that column/variable/parameter can contain/hold permanently in the table,
temporarily in stored procedure/functions as a parameter, temporarily in a variable in SQL Server.
```

## BIT
This data type is similar to the boolean data type in programming languages. In most cases, this data type will used to define the status of the record/row in a table.
Either 1 or 0 will be the values for this data type that it can hold. 1 is similar to true and 0 is similar to false.

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


## string functions in SQL Server
We have numerous string functions available in SQL Server, which we can use based on our requirements. In this lesson, we will cover the most important functions.



## Date functions in SQL Server
