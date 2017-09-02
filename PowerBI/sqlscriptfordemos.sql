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
