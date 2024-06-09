--GO is a batch separator
--In a SQL Server Management Studio Query window, we can write many T-SQL Statements.
--These queries can be DML or DDL commands
--when we want to send the T-SQL code as a Batch we use GO in SSMS query window. GO itself is not a T-SQL command, it is command utility that signals
to execute the commands as a single batch in SQL Server

-
alter proc proc1(@id int)
as
begin
	print 'proc1'
end
 
alter proc proc2(@id int)
as
begin
	print 'proc2'
end


object_id
object_name
db_id
db_name
schema_name
schema_id


