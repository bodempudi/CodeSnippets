CREATE OR ALTER PROCEDURE dbo.TestCaseExpression
AS
BEGIN
    SELECT
        CustomerStatus =
            CASE
                WHEN IsActive = 1 AND CustomerType = 'VIP' THEN 'ACTIVE'
                WHEN IsActive = 0 AND CustomerType = 'VIP' THEN 'INACTIVE'
                ELSE 'OTHER'
            END
    FROM dbo.Customer;
END;
