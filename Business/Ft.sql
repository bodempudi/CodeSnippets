CREATE OR ALTER PROCEDURE dbo.TestControlFlowIndent
AS
BEGIN

    DECLARE @A INT = 1;
    DECLARE @B INT = 2;
    DECLARE @C INT = 3;

    -- 1. IF containing WHILE
    IF (@A = 1)
    BEGIN
        SET @B = @B + 1;

        WHILE
        (
            @B < 10
            AND @C <> 0
        )
        BEGIN
            SET @B = @B + 1;
            BREAK;
        END

        SET @C = @C + 1;
    END

    -- 2. WHILE containing IF
    WHILE
    (
        @A < 10
        AND @B <> 0
    )
    BEGIN
        SET @A = @A + 1;

        IF
        (
            @B = 2
            AND @C = 3
        )
        BEGIN
            BREAK;
        END

        SET @A = @A - 1;
    END

    -- 3. Final statement
    SELECT
        @A AS A,
        @B AS B,
        @C AS C;

END;
