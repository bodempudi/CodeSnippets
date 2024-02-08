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

Basically a schema is nothing but a container. Similar to a folder in your computer. How we manage our files in Folders, similary we create our tables 
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

 Here GO a end of batch

 Batch is nothing a series command executed in single batch.





