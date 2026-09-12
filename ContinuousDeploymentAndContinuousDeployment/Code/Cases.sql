CREATE OR ALTER PROCEDURE dbo.TestCaseLayout
AS
BEGIN
    SELECT
        CustomerId,
        CASE
            WHEN CustomerType = 'VIP' AND IsActive = 1 THEN 'Priority'
            WHEN CustomerType = 'VIP' AND IsActive = 0 THEN 'Inactive VIP'
            WHEN CustomerType = 'REGULAR' THEN
                CASE
                    WHEN Balance > 1000 THEN 'Regular High'
                    ELSE 'Regular'
                END
            ELSE 'Other'
        END AS CustomerCategory
    FROM dbo.Customer;
END;
