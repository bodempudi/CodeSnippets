## Creating tables in SQL Server database

Table in SQL Server is the low level object which contains the actual data.

Before getting started with creating a table in SQL Server, how to find all the existing tables in any database.

Open a query window, make sure your query window is pointing to right database. Write the below query

SELECT * from sys.tables where [type] = 'U'
click execute button to execute the query.
![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/3b992d31-db9c-4e44-b3d0-e1394bc9e050)

the reason for having the query condition is, in the above picture you can see the type_desc column which mentions that these tables are created by developer or user tables. So having where condition with type='U' is a best practise.

There is another way to find the tables in a SQL Server database. Below is the query

SELECT * from INFORMATION_SCHEMA.TABLES 

![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/597cf38d-9bf1-4731-b52d-fb9e97529e0c)

Below is the side by side comparison of the both query executions.

![image](https://github.com/bodempudi/CodeSnippets/assets/2835142/95b46a58-16a1-47b4-9a3a-a8590a9bcf26)

As part of every developer day to day activities, you might need to drop or truncate table if exists. So there are ways of doing it.

SQL Server 2016 ctp3 and all above editons supports the following command.
<pre>
DROP TABLE IF EXISTS dbo.Sampletable;

</pre>
In older versions we have to use the below query.
<pre>
IF OBJECT_ID('dbo.Sampletable','U') IS NOT NULL
BEGIN
	DROP TABLE dbo.Sampletable;
END
</pre>
In the above query second argument is very important, it differentiates the object type from table to other object types, which means that we are telling 
the SQL Server Query engine that Sampletable is user table object. 
<pre>
IF EXISTS(SELECT TOP 1 * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Sampletable' and TABLE_SCHEMA='dbo')
BEGIN
	DROP TABLE dbo.Sampletable;
END
</pre>
