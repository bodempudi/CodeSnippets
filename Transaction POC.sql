-----------------------------------------------------------
-- POC: Parent → Child → GrandChild Transaction Demo
-- StatusCode: '0' = Success, '1' = Failure
-- Assignments done via SELECT
-----------------------------------------------------------

-----------------------------------------------------------
-- 1️⃣ Test Table
-----------------------------------------------------------
DROP TABLE IF EXISTS dbo.POC_Transaction_Test;
GO

CREATE TABLE dbo.POC_Transaction_Test
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    SourceProc VARCHAR(50),
    CreatedOn DATETIME2 DEFAULT SYSDATETIME()
);
GO

-----------------------------------------------------------
-- 2️⃣ GrandChild Stored Procedure
-----------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.GrandChild_SP
    @StatusCode    VARCHAR(30) OUTPUT,
    @StatusMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartedTran BIT;
    SELECT @StartedTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRAN;
            SELECT @StartedTran = 1;
        END

        INSERT INTO dbo.POC_Transaction_Test (SourceProc)
        VALUES ('GrandChild');

        -- Simulate failure
        RAISERROR ('Failure in GrandChild_SP', 16, 1);

        IF @StartedTran = 1
            COMMIT;

        SELECT 
            @StatusCode = '0',
            @StatusMessage = 'GrandChild success';
    END TRY
    BEGIN CATCH
        IF @StartedTran = 1 AND @@TRANCOUNT > 0
            ROLLBACK;

        SELECT 
            @StatusCode = '1',
            @StatusMessage = ERROR_MESSAGE();

        RAISERROR (
            @StatusMessage,
            ERROR_SEVERITY(),
            ERROR_STATE()
        );
    END CATCH
END;
GO

-----------------------------------------------------------
-- 3️⃣ Child Stored Procedure
-----------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.Child_SP
    @StatusCode    VARCHAR(30) OUTPUT,
    @StatusMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartedTran BIT;
    SELECT @StartedTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRAN;
            SELECT @StartedTran = 1;
        END

        INSERT INTO dbo.POC_Transaction_Test (SourceProc)
        VALUES ('Child');

        DECLARE 
            @GC_StatusCode VARCHAR(30),
            @GC_StatusMessage NVARCHAR(4000);

        EXEC dbo.GrandChild_SP
            @GC_StatusCode OUTPUT,
            @GC_StatusMessage OUTPUT;

        IF @StartedTran = 1
            COMMIT;

        SELECT 
            @StatusCode = '0',
            @StatusMessage = 'Child success';
    END TRY
    BEGIN CATCH
        IF @StartedTran = 1 AND @@TRANCOUNT > 0
            ROLLBACK;

        SELECT 
            @StatusCode = '1',
            @StatusMessage = ERROR_MESSAGE();

        RAISERROR (
            @StatusMessage,
            ERROR_SEVERITY(),
            ERROR_STATE()
        );
    END CATCH
END;
GO

-----------------------------------------------------------
-- 4️⃣ Parent Stored Procedure
-----------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.Parent_SP
    @StatusCode    VARCHAR(30) OUTPUT,
    @StatusMessage NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StartedTran BIT;
    SELECT @StartedTran = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRAN;
            SELECT @StartedTran = 1;
        END

        INSERT INTO dbo.POC_Transaction_Test (SourceProc)
        VALUES ('Parent');

        DECLARE 
            @C_StatusCode VARCHAR(30),
            @C_StatusMessage NVARCHAR(4000);

        EXEC dbo.Child_SP
            @C_StatusCode OUTPUT,
            @C_StatusMessage OUTPUT;

        IF @StartedTran = 1
            COMMIT;

        SELECT 
            @StatusCode = '0',
            @StatusMessage = 'Parent success';
    END TRY
    BEGIN CATCH
        IF @StartedTran = 1 AND @@TRANCOUNT > 0
            ROLLBACK;

        SELECT 
            @StatusCode = '1',
            @StatusMessage = ERROR_MESSAGE();
    END CATCH
END;
GO

-----------------------------------------------------------
-- 5️⃣ TEST CASE: Standalone GrandChild
-----------------------------------------------------------
TRUNCATE TABLE dbo.POC_Transaction_Test;

DECLARE @C1 VARCHAR(30), @M1 NVARCHAR(4000);

BEGIN TRY
    EXEC dbo.GrandChild_SP @C1 OUTPUT, @M1 OUTPUT;
END TRY
BEGIN CATCH
    PRINT 'Caught error (GrandChild standalone)';
END CATCH;

SELECT @C1 AS StatusCode, @M1 AS StatusMessage;
SELECT * FROM dbo.POC_Transaction_Test;

-----------------------------------------------------------
-- 6️⃣ TEST CASE: Parent → Child → GrandChild
-----------------------------------------------------------
TRUNCATE TABLE dbo.POC_Transaction_Test;

DECLARE @C2 VARCHAR(30), @M2 NVARCHAR(4000);

BEGIN TRY
    EXEC dbo.Parent_SP @C2 OUTPUT, @M2 OUTPUT;
END TRY
BEGIN CATCH
    PRINT 'Caught error (Parent execution)';
END CATCH;

SELECT @C2 AS StatusCode, @M2 AS StatusMessage;
SELECT * FROM dbo.POC_Transaction_Test;
