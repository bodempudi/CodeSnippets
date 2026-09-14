IF EXISTS(SELECT 1 FROM dbo.Customer C WHERE C.CustomerId = @CustomerId)
BEGIN
PRINT 'Customer Exists'
END

IF NOT EXISTS(SELECT 1 FROM dbo.Account A WHERE A.CustomerId = @CustomerId AND A.IsActive = 1)
BEGIN
PRINT 'Active Account Not Found'
END
