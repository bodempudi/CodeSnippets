SELECT
a.Id,
b.Name,
c.Status
FROM dbo.TableA a

-- Comment before INNER JOIN
INNER JOIN dbo.TableB b
ON a.Id=b.Id

/* Comment before LEFT JOIN */
LEFT JOIN dbo.TableC c
ON b.Id=c.Id

INNER JOIN dbo.TableD d -- Inline JOIN comment
ON c.Id=d.Id

INNER JOIN
(
SELECT
x.Id,
x.Code
FROM dbo.TableX x
-- Comment inside derived table
INNER JOIN dbo.TableY y
ON x.Id=y.Id
) dt
ON a.Id=dt.Id

-- Comment before derived-table JOIN
LEFT JOIN
(
SELECT
m.Id
FROM dbo.TableM m
WHERE m.IsActive=1
) m
ON a.Id=m.Id

WHERE
a.IsActive=1;
