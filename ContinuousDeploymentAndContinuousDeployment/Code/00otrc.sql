CREATE OR ALTER PROCEDURE dbo.TestTryCatchElseIf
AS
BEGIN
    BEGIN TRY
        IF 1 = 1
        BEGIN
            SELECT 1;
        END
        ELSE IF 2 = 2
        BEGIN
            SELECT 2;
        END
        ELSE
        BEGIN
            SELECT 3;
        END
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 1205
        BEGIN
            SELECT 'Deadlock';
        END
        ELSE IF ERROR_NUMBER() = 2627
        BEGIN
            SELECT 'Duplicate';
        END
        ELSE
        BEGIN
            SELECT ERROR_MESSAGE();
        END
    END CATCH
END;
