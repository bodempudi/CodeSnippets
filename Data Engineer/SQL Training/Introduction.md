Make sure you installed SQL Server any edition in your laptop. We usually install developer edition, which is free and can be downloaded Microsoft Website.
Make sure SQL Server Management Studio is installed on your computer.
SQL Server Management Studio in short SSMS is an integrated development environment where you can write our TSQL Code or TSQL Statements  or TSQL Script, 
which will be used to insert(add) the data or manage the data or managing the databases.
SQL Server is an RDBMS from Microsoft, T-SQL is a language which will be used to store or manage the data in SQL Server.

Now i will be adding all the important details you should know before you start working with SQL Server.

As mentioned earlier, SQL Server Management Studio is an integrated development environment. Please open your SSMS in your laptop.
Click start button and start typing SSMS in windows search, it starts displaying as below.

![SQL Server Management Studio](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/Search-SSMS.png)

Once you find your SSMS, pin to your laptop task bar so that i will be easy to access it from next time. You can do this as below.

![SSMS Pin To Task Bar](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/SSMS-Pint-Taskbar.png)

Now you can open your SSMS by going to taskbar as below.

![Open SSMS from Taskbar](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/Open%20SSMS%20from%20Taskbar.png)

Now you have your SSMS is ready to get started as below.

![SSMS Opened](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/Open-SSMS.png)

Now we should know the Server details from team if you work in a company. Please try to collect the server details from the team. Now as we are learning the SQL Server now and already installed it in our laptop. Try connecting to it from your SSMS.

usually the server name is either a name or an ip address. They will give you this and username and password as well.

Once you connet to the SQL Server from SSMS, you can find it as below.

![Connected to SSMS](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/Open-SSMS.png)

Once you connect to SQL Server, first thing you should know is version of the SQL Server.

**SELECT @@VERSION**

we can use this command to know the same. Run this command in SSIS and see the result.

**Understand the difference between windows authentication and SQL Server authentication**
In case of windows authentication your windows username and password is going to be used to connect to the sql server. Incase of SQL Server authentication you need username and password from the team to connect to the SQL Server

To write any query in SSMS, we should first open a query window. You can use Ctrl+N or File menu to open a new query window. Make you sure your query window is pointing to correct database. The query you write should be executed in correct database.

Server level information is going to be same irrespective of the database. For example, **SELECT @@SERVER** gives same information in case of any database, Because this is server level information.

To make sure your query window pointing to correct database. Please use below commands in your query windows.

use YourDatabaseName;
GO

Before you execute use command, it looks like below

![Use Database before](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/Usedatabase-Before.png)

After you execute use command, it looks like below.

![After Database before](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/Use-Database-After.png)

You use dropdown box as below to change the database for your query window as below

![Change Data](https://github.com/bodempudi/CodeSnippets/blob/master/images/SQLServer/Select-Database.png)

**System Databases**
Now lets try to the understand the systems databases we have in SQL Server.
**master** Database	Records all the system-level information for an instance of SQL Server. It stores all the required built in SQL Server information.

msdb Database	Is used by SQL Server Agent for scheduling alerts and jobs.

model Database	Is used as the template for all databases created on the instance of SQL Server. Modifications made to the model database, such as database size, collation, recovery model, and other database options, are applied to any databases created afterward.

tempdb Database	Is a workspace for holding temporary objects or intermediate result

**Database files**

**Query Executions**
Various Query Executions








