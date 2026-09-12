CREATE OR ALTER PROCEDURE dbo.TestNestedIf
AS
BEGIN
    IF 1 = 1
    BEGIN
        IF 2 = 2
        BEGIN
            SELECT 1;
        END
        ELSE
        BEGIN
            SELECT 2;
        END
    END
    ELSE IF 3 = 3
    BEGIN
        SELECT 3;
    END
    ELSE
    BEGIN
        SELECT 4;
    END
END;
