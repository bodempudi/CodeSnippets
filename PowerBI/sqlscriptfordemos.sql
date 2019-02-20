//power query sql script
//when you write individual queries database name is mandatory

CREATE DATABASE DevDB;
GO

CREATE DATABASE ProdDB;
GO

CREATE TABLE dbo.TestTable1(
id int primary key,
firstname varchar(50),
lastname varchar(50),
sal decimal(20,2)
);

declare @a int = 1;
while @a<= 100000//for dev it is 100
begin
	insert into dbo.TestTable1 values(@a,'firstname'+cast(@a as varchar(4)),'lastname'+cast(@a as varchar(4)),1000+@a);
	set @a = @a + 1;
end



--mixing filters demo
IF OBJECT_ID('dbo.MixingFiltersDemo') IS NOT NULL
	DROP TABLE dbo.MixingFiltersDemo;
CREATE TABLE dbo.MixingFiltersDemo(
City VARCHAR(50),
Channel VARCHAR(50),
Color VARCHAR(50),
Size VARCHAR(50),
Qunatity INT,
PRICE INT
);

INSERT INTO dbo.MixingFiltersDemo values('Paris','Store','Red','Large',1,15);
INSERT INTO dbo.MixingFiltersDemo values('Paris','Store','Red','Small',2,17);
INSERT INTO dbo.MixingFiltersDemo values('Toronto','Store','Green','Large',4,11);
INSERT INTO dbo.MixingFiltersDemo values('New York','Store','Green','Small',6,9);
INSERT INTO dbo.MixingFiltersDemo values(NULL,'Internet','Red','Large',16,7);
INSERT INTO dbo.MixingFiltersDemo values(NULL,'Internet','Red','Small',12,7);
INSERT INTO dbo.MixingFiltersDemo values(NULL,'Internet','Green','Large',50,17);
INSERT INTO dbo.MixingFiltersDemo values(NULL,'Internet','Green','Small',60,70);

SELECT * FROM dbo.MixingFiltersDemo

--verification
SELECT a.Color,sum(Qunatity*PRICE) FROM dbo.MixingFiltersDemo A 
--WHERE A.Channel='Internet'
group by a.Color


SELECT sum(Qunatity*PRICE) FROM dbo.MixingFiltersDemo A WHERE A.Channel='Internet'

SELECT sum(Qunatity*PRICE) FROM dbo.MixingFiltersDemo A 


--other table functions
if OBJECT_ID('dbo.Products') IS NOT NULL
	DROP TABLE dbo.Products;
CREATE TABLE dbo.Products(
id int,
name varchar(50));

CREATE TABLE dbo.Sales(
ProductId int,
Sales DECIMAL(10,2));

INSERT INTO dbo.Products values(1,'Lenovo');
INSERT INTO dbo.Products values(2,'HP');
INSERT INTO dbo.Products values(3,'Dell');

INSERT INTO dbo.Sales values(1,150);
INSERT INTO dbo.Sales values(2,250);
INSERT INTO dbo.Sales values(3,350);
INSERT INTO dbo.Sales values(1,1050);
INSERT INTO dbo.Sales values(2,2050);
INSERT INTO dbo.Sales values(3,3050);
INSERT INTO dbo.Sales values(4,450);


SELECT * FROM dbo.Products	
select * from dbo.Sales
	      
	      
	      
	      
----


-- drop table dbo.Dimdate

create table dbo.Dimdate(
Date_Key INT,
FullDate DATE,
YEAR INT,
MONTH VARCHAR(500),
MonthNumber INT,
Quarter VARCHAR(500),
WeekRange VARCHAR(500));
GO

INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190201',CAST('02/01/2019' AS DATE),2019,'February',2,'Q1','Jan 27 - Feb 2');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190202',CAST('02/02/2019' AS DATE),2019,'February',2,'Q1','Jan 27 - Feb 2');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190203',CAST('02/03/2019' AS DATE),2019,'February',2,'Q1','Feb 3 - Feb 9');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190204',CAST('02/04/2019' AS DATE),2019,'February',2,'Q1','Feb 3 - Feb 9');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190205',CAST('02/05/2019' AS DATE),2019,'February',2,'Q1','Feb 3 - Feb 9');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190206',CAST('02/06/2019' AS DATE),2019,'February',2,'Q1','Feb 3 - Feb 9');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190207',CAST('02/07/2019' AS DATE),2019,'February',2,'Q1','Feb 3 - Feb 9');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190208',CAST('02/08/2019' AS DATE),2019,'February',2,'Q1','Feb 3 - Feb 9');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190209',CAST('02/09/2019' AS DATE),2019,'February',2,'Q1','Feb 3 - Feb 9');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190210',CAST('02/10/2019' AS DATE),2019,'February',2,'Q1','Feb 10 - Feb 16');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190211',CAST('02/11/2019' AS DATE),2019,'February',2,'Q1','Feb 10 - Feb 16');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190212',CAST('02/12/2019' AS DATE),2019,'February',2,'Q1','Feb 10 - Feb 16');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190213',CAST('02/13/2019' AS DATE),2019,'February',2,'Q1','Feb 10 - Feb 16');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190214',CAST('02/14/2019' AS DATE),2019,'February',2,'Q1','Feb 10 - Feb 16');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190215',CAST('02/15/2019' AS DATE),2019,'February',2,'Q1','Feb 10 - Feb 16');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190216',CAST('02/16/2019' AS DATE),2019,'February',2,'Q1','Feb 10 - Feb 16');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190217',CAST('02/17/2019' AS DATE),2019,'February',2,'Q1','Feb 17 - Feb 23');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190218',CAST('02/18/2019' AS DATE),2019,'February',2,'Q1','Feb 17 - Feb 23');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190219',CAST('02/19/2019' AS DATE),2019,'February',2,'Q1','Feb 17 - Feb 23');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190220',CAST('02/20/2019' AS DATE),2019,'February',2,'Q1','Feb 17 - Feb 23');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190221',CAST('02/21/2019' AS DATE),2019,'February',2,'Q1','Feb 17 - Feb 23');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190222',CAST('02/22/2019' AS DATE),2019,'February',2,'Q1','Feb 17 - Feb 23');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190223',CAST('02/23/2019' AS DATE),2019,'February',2,'Q1','Feb 17 - Feb 23');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190224',CAST('02/24/2019' AS DATE),2019,'February',2,'Q1','Feb 24 - Feb 28');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190225',CAST('02/25/2019' AS DATE),2019,'February',2,'Q1','Feb 24 - Feb 28');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190226',CAST('02/26/2019' AS DATE),2019,'February',2,'Q1','Feb 24 - Feb 28');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190227',CAST('02/27/2019' AS DATE),2019,'February',2,'Q1','Feb 24 - Feb 28');
INSERT INTO dbo.DimDate(Date_Key,FULLDATE,[YEAR],[MONTH],[MonthNumber],Quarter,WeekRange) VALUES('20190228',CAST('02/28/2019' AS DATE),2019,'February',2,'Q1','Feb 24 - Feb 28'); 
GO

SELECT * FROM dbo.DimDate;
GO
CREATE TABLE dbo.DimCountry(
COUNTRYKey INT,
Name VARCHAR(500));
GO

INSERT INTO dbo.DimCountry VALUES(1,'USA');
INSERT INTO dbo.DimCountry VALUES(2,'UK');
INSERT INTO dbo.DimCountry VALUES(3,'INDIA');
INSERT INTO dbo.DimCountry VALUES(4,'JAPAN');
INSERT INTO dbo.DimCountry VALUES(5,'Germany');
go

select * from dbo.DimCountry


CREATE TABLE dbo.FactSales(
DateKey INT,
CountryKey INT,
SALES INT
);
GO

INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190201,1,100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190201,2,200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190201,3,300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190201,4,400);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190201,5,500);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190202,1,600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190202,2,700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190202,3,800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190202,4,900);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190202,5,1000);




INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190203,1,1100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190203,2,1200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190203,3,1300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190203,4,1400);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190203,5,1500);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190204,1,1600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190204,2,1700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190204,3,1800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190204,4,1900);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190204,5,2000);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190205,1,2100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190205,2,2200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190205,3,2300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190205,4,2400);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190205,5,2500);




INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190206,1,2500);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190206,2,2600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190206,3,2700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190206,4,2800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190206,5,2900);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190207,1,3000);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190207,2,3100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190207,3,3200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190207,4,3300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190207,5,3400);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190208,1,3500);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190208,2,3600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190208,3,3700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190208,4,3800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190208,5,3900);

INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190209,1,4000);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190209,2,4100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190209,3,4200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190209,4,4300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190209,5,4400);





INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190210,1,4500);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190210,2,4600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190210,3,4700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190210,4,4800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190210,5,4900);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190211,1,5000);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190211,2,5100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190211,3,5200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190211,4,5300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190211,5,5400);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190212,1,5500);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190212,2,5600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190212,3,5700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190212,4,5800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190212,5,5900);




INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190213,1,6000);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190213,2,6100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190213,3,6200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190213,4,6300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190213,5,6400);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190214,1,6500);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190214,2,6600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190214,3,6700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190214,4,6800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190214,5,6900);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190215,1,7000);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190215,2,7100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190215,3,7200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190215,4,7300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190215,5,7400);

INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190216,1,7500);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190216,2,7600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190216,3,7700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190216,4,7800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190216,5,7900);



INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190217,1,8000);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190217,2,8100);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190217,3,8200);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190217,4,8300);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190217,5,8400);


INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190218,1,8500);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190218,2,8600);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190218,3,8700);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190218,4,8800);
INSERT INTO dbo.FactSales(DateKey,CountryKey,SALES) VALUES(20190218,5,8900);

SELECT * FROM dbo.FactSales
