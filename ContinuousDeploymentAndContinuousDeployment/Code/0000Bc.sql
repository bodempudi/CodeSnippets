CREATE OR ALTER PROCEDURE dbo.TestBreakContinue
AS
BEGIN
    WHILE 1 = 1
    BEGIN
        SELECT 1;

        IF 1 = 1
        BEGIN
            BREAK;
        END

        SELECT 2;
    END

    WHILE 1 = 1
    BEGIN
        SELECT 3;

        CONTINUE;

        SELECT 4;
    END
END;
