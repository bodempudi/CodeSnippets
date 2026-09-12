SELECT
a.Id
FROM dbo.TableA a;

-- Next work starts here
WITH CustomerCTE AS
(
SELECT
b.Id,
b.Name
FROM dbo.TableB b
)
SELECT
c.Id,
c.Name
FROM CustomerCTE c;
