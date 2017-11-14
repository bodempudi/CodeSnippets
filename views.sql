SELECT a.* FROM dbo.Store A
LEFT JOIN [ProjectStndrd].[dbo].[ProjectStrd] B ON A.GRID=B.GRID;


UPDATE dbo.Store
SET IsMatched=1
FROM  


UPDATE A
SET A.IsMatched=0
FROM dbo.Store A
LEFT JOIN [ProjectStndrd].[dbo].[ProjectStrd] B 
ON A.GRID=B.GRID
where b.grid is null

CREATE VIEW dbo.NonMatchingGrids
as
select GRID
,LW
,CO
,StoreName from dbo.store b where b.ismatched=0


CREATE VIEW dbo.MissingGrids
as
select grid from [ProjectStndrd].[dbo].[ProjectStrd]
except
select GRID
 from dbo.store b

