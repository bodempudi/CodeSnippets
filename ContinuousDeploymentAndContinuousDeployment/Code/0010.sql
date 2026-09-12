CREATE OR ALTER PROCEDURE dbo.TestWhileIf
AS
BEGIN
    WHILE 1 = 1
    BEGIN
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

        BREAK;
    END
END;
