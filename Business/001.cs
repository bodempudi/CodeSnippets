CREATE OR ALTER PROCEDURE dbo.TestBooleanFormatting
AS
BEGIN

    -- 1. IF single condition with parentheses
    IF
    (
        @A
        =
        1
    )
    BEGIN
        SELECT 1;
    END

    -- 2. IF single condition without parentheses
    IF
        @A
        =
        1
    BEGIN
        SELECT 1;
    END

    -- 3. IF two conditions
    IF
    (
        @A = 1
        AND
        @B = 2
    )
    BEGIN
        SELECT 1;
    END

    -- 4. IF nested Boolean
    IF
    (
        @A = 1
        AND
        (
            @B = 2
            OR @C = 3
        )
    )
    BEGIN
        SELECT 1;
    END

    -- 5. IF OR only
    IF
    (
        @A = 1
        OR
        @B = 2
    )
    BEGIN
        SELECT 1;
    END

    -- 6. IF mixed AND / OR
    IF
    (
        @A = 1
        AND
        @B = 2
        OR
        @C = 3
    )
    BEGIN
        SELECT 1;
    END

    -- 7. IF comment protection
    IF
    (
        @A = 1 -- important condition
    )
    BEGIN
        SELECT 1;
    END

    -- 8. WHILE single condition
    WHILE
    (
        @A
        =
        1
    )
    BEGIN
        BREAK;
    END

    -- 9. WHILE two conditions
    WHILE
    (
        @A = 1
        AND
        @B = 2
    )
    BEGIN
        BREAK;
    END

    -- 10. WHILE nested Boolean
    WHILE
    (
        @A = 1
        AND
        (
            @B = 2
            OR @C = 3
        )
    )
    BEGIN
        BREAK;
    END

END;
