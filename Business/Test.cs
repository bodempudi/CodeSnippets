-- Multiple IF
IF
(
    @A = 1
    AND @B = 2
)
BEGIN
    SELECT 1;
END

-- Nested Boolean
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

-- Comment protection
IF
(
    @A = 1 -- important condition
)
BEGIN
    SELECT 1;
END
