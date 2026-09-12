CREATE OR ALTER PROCEDURE dbo.TestEndAlignment
AS
BEGIN
    IF 1 = 1
    BEGIN
        SELECT 1;
    END
    ELSE
    BEGIN
        SELECT 2;
    END

    WHILE 1 = 0
    BEGIN
        SELECT 3;
    END

    BEGIN TRY
        SELECT 4;
    END TRY
    BEGIN CATCH
        SELECT 5;
    END CATCH
END;
