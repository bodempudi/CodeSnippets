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
