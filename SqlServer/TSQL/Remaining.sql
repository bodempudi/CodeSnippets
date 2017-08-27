use adventuredwworks2012;
go
--CTE IS NOTHING Common Table Expressions
WITH cteEmployees(EmployeeKey
	, ParentEmployeeKey
	, EmployeeNationalIDAlternateKey
	, ParentEmployeeNationalIDAlternateKey
	, SalesTerritoryKey, FirstName, LastName
	, MiddleName
	, NameStyle
	, Title
	, HireDate
	, BirthDate
	, EmailAddress) AS
(
	SELECT EmployeeKey
	, ParentEmployeeKey
	, EmployeeNationalIDAlternateKey
	, ParentEmployeeNationalIDAlternateKey
	, SalesTerritoryKey, FirstName, LastName
	, MiddleName
	, NameStyle
	, Title
	, HireDate
	, BirthDate
	, EmailAddress FROM  dbo.DimEmployee 
)
SELECT * FROM cteEmployees;

WITH RecursiveCTE AS
(
	SELECT 
	  EmployeeKey
	, ParentEmployeeKey, 1 as Lvl
	, EmployeeNationalIDAlternateKey
	, ParentEmployeeNationalIDAlternateKey
	, SalesTerritoryKey, FirstName, LastName
	, MiddleName
	, NameStyle
	, Title
	, HireDate
	, BirthDate
	, EmailAddress
	 FROM  dbo.DimEmployee A WHERE A.ParentEmployeeKey IS NULL
UNION ALL
	SELECT 
	  B.EmployeeKey
	, B.ParentEmployeeKey, A.Lvl+1 
	, B.EmployeeNationalIDAlternateKey
	, B.ParentEmployeeNationalIDAlternateKey
	, B.SalesTerritoryKey, A.FirstName, A.LastName
	, B.MiddleName
	, B.NameStyle
	, B.Title
	, B.HireDate
	, B.BirthDate
	, B.EmailAddress 	
    FROM RecursiveCTE A INNER JOIN dbo.DimEmployee B
        ON B.ParentEmployeeKey = A.EmployeeKey 
)
SELECT * FROM RecursiveCTE;

--sub queries

SELECT productid, productname, unitprice
FROM Production.Products
WHERE unitprice =
(SELECT MIN(unitprice)
FROM Production.Products);

SELECT productid, productname, unitprice
FROM Production.Products
WHERE supplierid IN
(SELECT supplierid
FROM Production.Suppliers
WHERE country = N'Japan');

SELECT categoryid, productid, productname, unitprice
FROM Production.Products AS P1
WHERE unitprice =
(SELECT MIN(unitprice)
FROM Production.Products AS P2
WHERE P2.categoryid = P1.categoryid);

--OLAP Functions
SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY GROUPING SETS
(
( shipperid, YEAR(shippeddate) ),
( shipperid ),
( YEAR(shippeddate) ),
( )
);

SELECT shipperid, YEAR(shippeddate) AS shipyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY CUBE( shipperid, YEAR(shippeddate) );

SELECT shipcountry, shipregion, shipcity, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY ROLLUP( shipcountry, shipregion, shipcity );




