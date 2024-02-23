## Datatypes in SQL Server

We have numerous datatypes available in SQL Server. 
  1. string/unicode-based datatypes
  2. exact number based datatypes
  3. approximate number based datatypes
  4. datetime based datatypes
  5. blob based datatypes.

#BIT
This data type is similar to the boolean data type in programming languages. In most cases, this data type will used for the status of the record/row in a table.
Either 1 or 0 will be the values for this data type that it can hold. 1 is similar to true and 0 is similar to false.

  Let's take an example 

```sql
IF OBJECT_ID('dbo.Employee') IS NOT NULL
  DROP TABLE dbo.Employee;

CREATE TABLE dbo.Employee(
```

## string functions in SQL Server
We have numerous string functions available in SQL Server, which we can use based on our requirements. In this lesson, we will cover the most important functions.



## Date functions in SQL Server
