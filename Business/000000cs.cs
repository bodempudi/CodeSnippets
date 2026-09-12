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
)
SELECT
c.CustomerId,
c.CustomerName
FROM CustomerCTE c;

END;
