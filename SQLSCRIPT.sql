CREATE DATABASE CompanyStndrd;
GO

USE CompanyStndrd;
GO

let
       Source = Sql.Database(ServerName, DatabaseName, [Query="SELECT DISTINCT A.CAL_YEAR,A.CAL_QTR,LEFT(A.CAL_MTH_NAME,3) CAL_MTH_NAME,A.ABBOTT_WEEK_START_DATE,ABBOTT_DATE,A.WEEKDATERANGE,A.WEEKS,A.CAL_SKEY,A.CAL_MTH,a.ABBOTT_WEEK FROM 
( SELECT A.CAL_YEAR,A.CAL_QTR,A.CAL_MTH_NAME,A.ABBOTT_WEEK_START_DATE,CAST(A.ABBOTT_WEEK_START_DATE AS DATE) ABBOTT_DATE,A.WEEK_DATE_RANGE WEEKDATERANGE,A.WEEKS,A.CAL_SKEY,A.CAL_MTH,
a.ABBOTT_WEEK 
 FROM RDM.DIM_CAL  A left JOIN RDM.vw_FACT_LIBRELINK B ON A.CAL_SKEY=B.CAL_SKEY 
 UNION 
 SELECT A.CAL_YEAR,A.CAL_QTR,LEFT(A.CAL_MTH_NAME,3) CAL_MTH_NAME,A.ABBOTT_WEEK_START_DATE,
CAST(A.ABBOTT_WEEK_START_DATE AS DATE) ABBOTT_DATE, A.WEEK_DATE_RANGE WEEKDATERANGE,A.WEEKS,A.CAL_SKEY,A.CAL_MTH,a.ABBOTT_WEEK  FROM RDM.DIM_CAL  A left JOIN 
RDM.vw_FACT_LIBRE_VIEW B ON A.CAL_SKEY=B.CAL_SKEY) A Where  CAL_YEAR  >= YEAR(GETDATE())-2 AND  CAL_YEAR  < YEAR(GETDATE()) 
 union 
SELECT DISTINCT A.CAL_YEAR,A.CAL_QTR,LEFT(A.CAL_MTH_NAME,3) CAL_MTH_NAME,A.ABBOTT_WEEK_START_DATE,ABBOTT_DATE,A.WEEKDATERANGE,A.WEEKS,A.CAL_SKEY,A.CAL_MTH,a.ABBOTT_WEEK FROM 
( SELECT A.CAL_YEAR,A.CAL_QTR,A.CAL_MTH_NAME,A.ABBOTT_WEEK_START_DATE,CAST(A.ABBOTT_WEEK_START_DATE AS DATE) ABBOTT_DATE,A.WEEK_DATE_RANGE WEEKDATERANGE,
A.WEEKS,A.CAL_SKEY,A.CAL_MTH ,a.ABBOTT_WEEK
 FROM RDM.DIM_CAL  A left JOIN RDM.vw_FACT_LIBRELINK B ON A.CAL_SKEY=B.CAL_SKEY 
 UNION
  SELECT A.CAL_YEAR,A.CAL_QTR,LEFT(A.CAL_MTH_NAME,3) CAL_MTH_NAME,
A.ABBOTT_WEEK_START_DATE,CAST(A.ABBOTT_WEEK_START_DATE AS DATE) ABBOTT_DATE, A.WEEK_DATE_RANGE WEEKDATERANGE,A.WEEKS,A.CAL_SKEY,A.CAL_MTH,a.ABBOTT_WEEK  FROM RDM.DIM_CAL  A 
left JOIN RDM.vw_FACT_LIBRE_VIEW B ON A.CAL_SKEY=B.CAL_SKEY) A 
Where  CAL_YEAR  = YEAR(GETDATE()) and CAL_MTH<=month(getdate()) ORDER BY CAL_SKEY"])
in
    Source

CREATE TABLE dbo.CompanyStrd(
LW INT,
CO INT
);

INSERT INtO dbo.CompanyStrd values(4,5);


CREATE DATABASE Store;
GO

USE Store;
GO

CREATE TABLE dbo.Store(
GRID VARCHAR(50),
LW INT,
CO INT,
StoreName VARCHAR(50),
IsMatched VARCHAR(50) DEFAULT(1));


INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.1',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.2',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.3',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.4',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.5',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.6',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.7',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.8',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.9',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.10',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.11',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.12',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.13',4,5,'Store1')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.14',4,5,'Store1')




INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.1',4,6,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.2',4,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.3',4,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.4',5,6,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.5',4,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.6',5,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.7',4,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('R.3',4,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.9',4,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.10',4,6,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.11',4,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.12',5,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.13',4,5,'Store2')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.14',4,5,'Store2')



INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.1',4,5,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.2',4,5,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.5',4,4,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.6',5,5,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.7',4,6,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('R.3',4,5,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.9',4,5,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.11',4,5,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.12',5,5,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.13',4,5,'Store3')
INSERT INTO dbo.Store(grid,lw,co,StoreName) values('A.14',4,5,'Store3')
