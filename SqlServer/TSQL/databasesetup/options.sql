CREATE DATABASE SQLSchool;
GO

EXEC sys.sp_helpdb 'SQLSchool';
GO

SELECT * FROM sys.databases A WHERE A.name=N'SQLSchool';
GO

SELECT SERVERPROPERTY('INSTANCEDEFAULTDATAPATH') [DefaultDataFilePath],SERVERPROPERTY('INSTANCEDEFAULTLOGPATH') [DefaultLogFilePath];


DROP DATABASE SQLSchool;
GO

CREATE DATABASE SQLSchool
ON PRIMARY
(
	NAME='SQLSchool',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool.mdf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
)
LOG ON
(
	NAME='SQLSchool_log',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool_log.ldf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
);


CREATE DATABASE SQLSchool
ON PRIMARY
(
	NAME='SQLSchool',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool.mdf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
),
(
	NAME='SQLSchool2',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool_2.Ndf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
)
LOG ON
(
	NAME='SQLSchool_log',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool_log.ldf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
);

--add files to the database
ALTER DATABASE SQLSchool
ADD FILE 
(
	
	NAME='SQLSchool3',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool_3.Ndf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
)
TO FILEGROUP [Primary]
GO;
--remove files - only empty files can be removed
ALTER DATABASE SQLSchool
REMOVE FILE SQLSchool3;
GO;

--for removing a file which has data, first empty that and delete it.

--Adding a user file groups

ALTER DATABASE SQLSchool
ADD FILEGROUP [UserDefinedFG1];

--add files to user defined file groups
ALTER DATABASE SQLSchool
ADD FILE 
(
	
	NAME='SQLSchool4',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool_4.Ndf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
)
TO FILEGROUP [UserDefinedFG1]
GO

--to reomve a file group, first make groups empty
--with user defined file groups
CREATE DATABASE SQLSchool
ON PRIMARY
(
	NAME='SQLSchool',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool.mdf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
),
FILEGROUP [Application]
(
	NAME='SQLSchool2',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool_2.Ndf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
)
LOG ON
(
	NAME='SQLSchool_log',
	FILENAME='D:\Teaching\Demos\TSQL\Databases\SQLSchool_log.ldf',
	SIZE=1024MB,
	MAXSIZE=UNLIMITED,
	FILEGROWTH=1024MB
);

USE SQLSchool;
GO

SELECT * FROM sys.filegroups;
GO

ALTER DATABASE SQLSchool  
MODIFY FILEGROUP [APPLICATION] DEFAULT;  
GO

--modifying the file growth options
ALTER DATABASE SQLSchool
MODIFY FILE (NAME='SQLSchool' ,FILEGROWTH=8192MB);

--We can even modify the data file locations

CREATE TABLE dbo.HelloWorld(
id int primary key identity,
name varchar(50),
sal int
);

SELECT * FROM sys.objects a where a.type='U';

--checking the database owner
SELECT 
	A.name
	,A.database_id
	,A.source_database_id
	,A.owner_sid
	,B.name
	,A.create_date
 FROM sys.databases A 
LEFT JOIN sys.server_principals B ON A.owner_sid = B.sid;


EXEC sys.sp_helpdb;



















