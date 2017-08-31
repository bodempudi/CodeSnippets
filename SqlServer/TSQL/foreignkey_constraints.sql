CREATE TABLE dbo.Dept(
id int constraint PK_dbo_DEPT__ID  primary key,
name varchar(50),
loc varchar(50)
);

CREATE TABLE dbo.Emp(
id int constraint PK_dbo_EMP__ID primary key,
name varchar(50),
deptid int constraint FK_dbo_Emp__DeptID foreign key references dbo.Dept(id))
