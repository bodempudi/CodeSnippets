CREATE OR ALTER PROCEDURE dbo.TestElseNull
AS
BEGIN
    IF 1 = 1
        SELECT 1;
    ELSE
        NULL;

    IF 1 = 0
    BEGIN
        SELECT 2;
    END
    ELSE
        NULL;
END;
