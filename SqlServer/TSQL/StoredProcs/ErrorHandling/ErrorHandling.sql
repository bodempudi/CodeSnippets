CREATE TABLE dbo.SETExactAbortTest(
id int primary key,
name varchar(50),
sal int
);

SET XACT_ABORT ON;
SET XACT_ABORT OFF;

BEGIN TRY
    BEGIN TRAN 
        INSERT INTO dbo.SETExactAbortTest values(2,'venkat',1000);
        INSERT INTO dbo.SETExactAbortTest values(1,'venkat',1000);
    COMMIT TRAN
END TRY
BEGIN CATCH
    ROLLBACK TRAN
END CATCH

SELECT * FROM dbo.SETExactAbortTest;
