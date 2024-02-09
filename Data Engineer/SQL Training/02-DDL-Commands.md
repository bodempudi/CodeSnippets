# Comments in SQL Server
  You can write comments in SQL Server. Basically comments will be used to explain the business case and expalin the logic that you written.
  Comments in SQL Server can be written in two ways.
  1. Single Line Comment
  2. Multi Line Comment

You can write single line comment using --
ex: --this is a SQL Server single line comment

You can write multi line comment using /*  */
Ex: /* This is a SQL Server multiline Comment */

Now we will start looking at the different DDL commands which are required.

There are few catalog views which provides information about meta data in the SQL Server. Metadata means data about data, which means if you take one column in SQL Server as an example, what is the name of the column, data type of the column, size. These types details are called metadata.

SELECT * FROM sys.tables

select * from INFORMATION_SCHEMA.TABLES

These are the views which gives information about user created tables in the selected database. In the below you can see the same.

![User Tables in a data](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/User%20tables.png)

There are two views available which gives information about tables in SQL Server. In the picture i have selected the database ** Sample **, so all the tables
in the database are displayed. You can use respective view as you need.

Please see below picture.

![All Columns View](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/Columns.png)

When take a look at above view, the data coming from sys view is having system related as well where as columns coming from information_schema view is having only. So when you do any column implementations, consider taking columns from information_schema view rather sys.views.

I recommed you always using views from Information_Schema schema. You please do you own investigation before taking your decision.

When we create a table in SQL Server, It will always be inside a SQL Server schema. By default it is dbo in SQL Server, we can define a user defined
schema as well.

Basically a database is a container for tables, stored procudes and other objects. a schema is nothing but a sub-container(or container) in a database. Similar to a folder in your computer. How we manage our files in Folders, similary we create our tables 
in schemas.

Basically following is the hierarchial order
<pre>
SQL Server Instance ----> Database A
                              |
                              |---->Schema 1(Table1, Table2, Table3)
                              |
                              |---->Schema 2(Table1,Table2,Table3)
                    ----> Database B
                    ----> Database C
</pre>
Table is the low level entity, every table will be inside a schema.

To know all the schemas inside a database, below is the Query.
SELECT * FROM sys.schemas
to create a schema in database.


CREATE SCHEMA SchemaName;
GO

 Here GO is a end of batch

 Batch is nothing a series commands executed in single batch.

--Basic Table Creation Syntax
CREATE TABLE dbo.SampleApplication(
ApplicationID INT IDENTITY PRIMARY KEY,
ApplicationName VARCHAR(50),
AddedDate DATETIME
);

When write any SQL Code, Please make sure your names and code is neat and meaning full.
In this code, SampleApplication is a table created in dbo schema, when you do not specify a schema name along with your table name, your table is going
to be created in dbo schema. dbo is a default schema in SQL Server. 

Every table belongs to a file group, default file group is primary. When you want your table to be created in a different file group you speficy that. File groups is different subject, we will take a look at it in later point of time.

Below is the reference to see the file group of a table.

![table file groups](https://github.com/bodempudi/CodeSnippets/assets/2835142/c7004650-96de-4e78-88e3-6b4f76aaec21)

Now lets have a basic understanding of data files in SQL Server.
mdf file - In this file the actual data contents will be there. Tables, Views, Indexes, all such objects actually exists in this file.
ldf file - This file always keeps track of all the operations you do with your database. This file is very very important to the SQL Server, since SQL Server is going to use the informaion in this server
to make your database consistant. For example, When you add/delete any data to database, SQL Server will add that information first to the log file and then it will add to the database.

### Adding columns to an existing table.
ALTER TABLE TABLENAME ADD YOURColumnName DATATYPE
adding columns to an existing table, alter columns, altering constraints all these operations syntaxes can be find in internet and you can use it for your work completion. Just know about all these operations.


EX: ALTER TABLE SampleApplication ADD IsActive BIT NOT NULL;

SQL has several categories of statements, including Data Definition Language (DDL), Data Manipulation Language (DML), and Data Control Language (DCL). 
DDL deals with object definitions and includes statements such as CREATE, ALTER, and DROP. 
DML allows you to query and modify data and includes statements such as SELECT, INSERT, UPDATE, DELETE, TRUNCATE, and MERGE. 
It’s a common misunderstanding that DML includes only data modification statements, but as I mentioned, it also includes SELECT. 
Another common misunderstanding is that TRUNCATE is a DDL statement, but in fact it is a DML statement. 
DCL deals with permissions and includes statements such as GRANT and REVOKE.

 collation at the database level that will determine language support, case sensitivity, and sort order for character data in that database. If you do not specify a collation for the database when you create it, the new database will use the default collation of the instance (chosen upon installation). 
