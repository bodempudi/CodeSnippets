## Datatypes in SQL Server

We have numerous datatypes available in SQL Server. 
  1. string/unicode-based string datatypes
  2. exact number based datatypes
  3. approximate number based datatypes
  4. datetime based datatypes
  5. blob based datatypes.

In every data model(One Specific business problem), we will have many entities(tables), and each entity(table) will have many attributes (columns)/fields(columns). Each field/column can hold different types of data. Let's take the Employee entity as an example, it will have many attributes(columns) like EmployeID, FirstName, LastName, MiddleName, DateOfBirth, Salary, ContactNumber, IsActive, etc. In the data model for every attribute, we will define the specific data type.

```
Data type defines the type of data that a column/variable/parameter can contain/hold permanently in the table,
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


## string functions in SQL Server
We have numerous string functions available in SQL Server, which we can use based on our requirements. In this lesson, we will cover the most important functions.



## Date functions in SQL Server
