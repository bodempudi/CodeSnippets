CREATE OR ALTER PROCEDURE dbo.TestCteAfterStatement
    @CustomerId INT
AS
BEGIN

SELECT
@CustomerId AS InputCustomerId;

-- Start customer processing
;WITH CustomerCTE AS
(
SELECT
c.CustomerId,
c.CustomerName
FROM dbo.Customer c
WHERE c.CustomerId=@CustomerId
),
OrderCTE AS
(
SELECT
o.CustomerId,
COUNT(*) AS OrderCount
FROM dbo.Orders o
GROUP BY
o.CustomerId
)
SELECT
c.CustomerId,
c.CustomerName,
o.OrderCount
FROM CustomerCTE c
LEFT JOIN OrderCTE o
ON c.CustomerId=o.CustomerId;

END;
