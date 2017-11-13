--select nth max sal 
DECLARE @MAXSAL INT = (SELECT MAX(SAL) FROM Allegiance.Emp);
DECLARE @SALRANK INT = 3;
DECLARE @INITIAL INT = 1;
IF(@SALRANK = 1)
    SET @MAXSAL = @MAXSAL;
ELSE
BEGIN
    WHILE @INITIAL < @SALRANK
    BEGIN
        SET @MAXSAL = (SELECT MAX(A.SAL) FROM Allegiance.EMP A WHERE A.SAL < @MAXSAL);
        SET @INITIAL = @INITIAL + 1;
    END
END
SELECT @MAXSAL;


--finding max sal by dept
;WITH MAXSALS AS(
 select A.name,A.Sal,B.name [DNAME],DENSE_RANK() OVER(PARTITION BY B.Name ORDER BY A.SAL DESC) RANK from Allegiance.Emp A INNER JOIN Allegiance.DeptTest B ON A.deptid = B.id
 )
 SELECT A.name,A.Sal,A.[DNAME] FROM MAXSALS A WHERE A.[RANK]=2;



;WITH MAXSALS AS(
 select A.name,A.Sal,B.name [DNAME],DENSE_RANK() OVER(PARTITION BY B.Name ORDER BY A.SAL DESC) RANK from Allegiance.Emp A INNER JOIN Allegiance.DeptTest B ON A.deptid = B.id
 )
 SELECT A.name,A.Sal,A.[DNAME] FROM MAXSALS A WHERE A.[RANK]=1;



IF CONVERT(VARCHAR(MAX),(
    SELECT * 
      FROM authors ORDER BY au_id FOR XML path, root))
  =
      CONVERT(VARCHAR(MAX),(
    SELECT * 
      FROM authorscopy ORDER BY au_id FOR XMLpath, root))
SELECT 'they are  the same'
ELSE
SELECT 'they are different'
