/* ============================================================
   CASE 01 - SINGLE INNER JOIN
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id;


/* ============================================================
   CASE 02 - MULTIPLE CHAINED JOINS
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id
RIGHT JOIN dbo.TableD d
ON c.Id = d.Id
FULL JOIN dbo.TableE e
ON d.Id = e.Id;


/* ============================================================
   CASE 03 - MANY JOINS
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id
INNER JOIN dbo.TableD d
ON c.Id = d.Id
RIGHT JOIN dbo.TableE e
ON d.Id = e.Id
FULL JOIN dbo.TableF f
ON e.Id = f.Id
INNER JOIN dbo.TableG g
ON f.Id = g.Id;


/* ============================================================
   CASE 04 - JOIN WITH TABLE HINTS
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a WITH(NOLOCK)
INNER JOIN dbo.TableB b WITH(NOLOCK)
ON a.Id = b.Id
LEFT JOIN dbo.TableC c WITH(NOLOCK)
ON b.Id = c.Id;


/* ============================================================
   CASE 05 - JOIN WITH DERIVED TABLE
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN
(
SELECT
b.Id
FROM dbo.TableB b
) x
ON a.Id = x.Id;


/* ============================================================
   CASE 06 - JOIN INSIDE DERIVED TABLE
   ============================================================ */

SELECT
    x.Id
FROM
(
SELECT
b.Id
FROM dbo.TableB b
INNER JOIN dbo.TableC c
ON b.Id = c.Id
) x;


/* ============================================================
   CASE 07 - DERIVED TABLE AS FIRST FROM SOURCE
   THEN JOIN
   ============================================================ */

SELECT
    x.Id
FROM
(
SELECT
a.Id
FROM dbo.TableA a
) x
INNER JOIN dbo.TableB b
ON x.Id = b.Id;


/* ============================================================
   CASE 08 - DERIVED TABLE WITH MULTIPLE JOINS INSIDE
   ============================================================ */

SELECT
    x.Id
FROM
(
SELECT
b.Id
FROM dbo.TableB b
INNER JOIN dbo.TableC c
ON b.Id = c.Id
LEFT JOIN dbo.TableD d
ON c.Id = d.Id
INNER JOIN dbo.TableE e
ON d.Id = e.Id
) x
INNER JOIN dbo.TableF f
ON x.Id = f.Id;


/* ============================================================
   CASE 09 - NESTED DERIVED TABLE
   ============================================================ */

SELECT
    x.Id
FROM
(
SELECT
y.Id
FROM
(
SELECT
a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
) y
LEFT JOIN dbo.TableC c
ON y.Id = c.Id
) x
INNER JOIN dbo.TableD d
ON x.Id = d.Id;


/* ============================================================
   CASE 10 - JOIN WITH MULTIPLE ON CONDITIONS
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
AND a.CustomerId = b.CustomerId
AND b.IsActive = 1;


/* ============================================================
   CASE 11 - JOIN WITH PARENTHESIZED ON CONDITION
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON (a.Id = b.Id)
AND a.IsActive = 1;


/* ============================================================
   CASE 12 - JOIN WITH OR CONDITION
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
OR a.LegacyId = b.Id;


/* ============================================================
   CASE 13 - JOIN WITH COMMENT BEFORE JOIN
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
-- Customer lookup
INNER JOIN dbo.TableB b
ON a.Id = b.Id;


/* ============================================================
   CASE 14 - JOIN WITH COMMENT BEFORE ON
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
-- Match customer identifier
ON a.Id = b.Id;


/* ============================================================
   CASE 15 - INLINE COMMENT AROUND JOIN
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b -- Customer table
ON a.Id = b.Id;


/* ============================================================
   CASE 16 - BLOCK COMMENT AROUND JOIN
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
/* Customer mapping */
INNER JOIN dbo.TableB b
ON a.Id = b.Id;


/* ============================================================
   CASE 17 - JOIN INSIDE CTE
   ============================================================ */

WITH CustomerCTE AS
(
SELECT
a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id
)
SELECT
    Id
FROM CustomerCTE;


/* ============================================================
   CASE 18 - JOIN AFTER CTE
   ============================================================ */

WITH CustomerCTE AS
(
SELECT
a.Id
FROM dbo.TableA a
)
SELECT
    c.Id
FROM CustomerCTE c
INNER JOIN dbo.TableB b
ON c.Id = b.Id
LEFT JOIN dbo.TableC x
ON b.Id = x.Id;


/* ============================================================
   CASE 19 - JOIN INSIDE EXISTS
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
WHERE EXISTS
(
SELECT
1
FROM dbo.TableB b
INNER JOIN dbo.TableC c
ON b.Id = c.Id
WHERE b.Id = a.Id
);


/* ============================================================
   CASE 20 - JOIN INSIDE IN SUBQUERY
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
WHERE a.Id IN
(
SELECT
b.Id
FROM dbo.TableB b
INNER JOIN dbo.TableC c
ON b.Id = c.Id
);


/* ============================================================
   CASE 21 - JOIN INSIDE SCALAR SUBQUERY
   ============================================================ */

SELECT
    a.Id
    ,CustomerName =
    (
SELECT
TOP 1
b.Name
FROM dbo.TableB b
INNER JOIN dbo.TableC c
ON b.Id = c.Id
WHERE b.Id = a.Id
    )
FROM dbo.TableA a;


/* ============================================================
   CASE 22 - INSERT SELECT WITH JOINS
   ============================================================ */

INSERT INTO dbo.TargetTable
(
    Id
    ,Name
)
SELECT
a.Id
,b.Name
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id;


/* ============================================================
   CASE 23 - UPDATE WITH JOIN
   ============================================================ */

UPDATE a
SET
a.Name = b.Name
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id;


/* ============================================================
   CASE 24 - DELETE WITH JOIN
   ============================================================ */

DELETE a
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id;


/* ============================================================
   CASE 25 - STORED PROCEDURE WITH MULTIPLE JOINS
   ============================================================ */

CREATE OR ALTER PROCEDURE dbo.TestJoinFormatting
AS
BEGIN

SELECT
a.Id
,b.Name
,c.Description
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id
INNER JOIN dbo.TableD d
ON c.Id = d.Id;

END;


/* ============================================================
   CASE 26 - VIEW WITH MULTIPLE JOINS
   ============================================================ */

CREATE OR ALTER VIEW dbo.TestJoinView
AS
SELECT
a.Id
,b.Name
,c.Description
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id
INNER JOIN dbo.TableD d
ON c.Id = d.Id;


/* ============================================================
   CASE 27 - FUNCTION WITH JOINS
   ============================================================ */

CREATE OR ALTER FUNCTION dbo.TestJoinFunction
(
    @Id INT
)
RETURNS TABLE
AS
RETURN
(
SELECT
a.Id
,b.Name
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id
WHERE a.Id = @Id
);


/* ============================================================
   CASE 28 - MIXED JOIN TYPES
   ============================================================ */

SELECT
    a.Id
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT OUTER JOIN dbo.TableC c
ON b.Id = c.Id
RIGHT OUTER JOIN dbo.TableD d
ON c.Id = d.Id
FULL OUTER JOIN dbo.TableE e
ON d.Id = e.Id;


/* ============================================================
   CASE 29 - CROSS JOIN
   ============================================================ */

SELECT
    a.Id
    ,b.Id
FROM dbo.TableA a
CROSS JOIN dbo.TableB b;


/* ============================================================
   CASE 30 - CROSS APPLY
   ============================================================ */

SELECT
    a.Id
    ,x.Id
FROM dbo.TableA a
CROSS APPLY
(
SELECT
TOP 1
b.Id
FROM dbo.TableB b
WHERE b.Id = a.Id
) x;


/* ============================================================
   CASE 31 - OUTER APPLY
   ============================================================ */

SELECT
    a.Id
    ,x.Id
FROM dbo.TableA a
OUTER APPLY
(
SELECT
TOP 1
b.Id
FROM dbo.TableB b
WHERE b.Id = a.Id
) x;


/* ============================================================
   CASE 32 - MULTIPLE DERIVED TABLE JOINS
   ============================================================ */

SELECT
    x.Id
FROM
(
SELECT
a.Id
FROM dbo.TableA a
) x
INNER JOIN
(
SELECT
b.Id
FROM dbo.TableB b
INNER JOIN dbo.TableC c
ON b.Id = c.Id
) y
ON x.Id = y.Id
LEFT JOIN
(
SELECT
d.Id
FROM dbo.TableD d
) z
ON y.Id = z.Id;


/* ============================================================
   CASE 33 - JOIN WITH SCHEMA/DATABASE QUALIFIED TABLES
   ============================================================ */

SELECT
    a.Id
FROM DatabaseA.dbo.TableA a
INNER JOIN DatabaseB.dbo.TableB b
ON a.Id = b.Id
LEFT JOIN DatabaseC.dbo.TableC c
ON b.Id = c.Id;


/* ============================================================
   CASE 34 - BRACKETED IDENTIFIERS
   ============================================================ */

SELECT
    a.[Customer ID]
FROM [dbo].[Table A] a
INNER JOIN [dbo].[Table B] b
ON a.[Customer ID] = b.[Customer ID];


/* ============================================================
   CASE 35 - FORMAT TWICE / IDEMPOTENCY TEST
   ============================================================ */

SELECT
a.Id
,b.Name
,c.Description
FROM dbo.TableA a
INNER JOIN dbo.TableB b
ON a.Id = b.Id
LEFT JOIN dbo.TableC c
ON b.Id = c.Id
INNER JOIN dbo.TableD d
ON c.Id = d.Id;
