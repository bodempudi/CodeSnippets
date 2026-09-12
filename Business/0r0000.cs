CREATE OR ALTER PROCEDURE dbo.TestBooleanFormatting
    @A INT,
    @B INT,
    @C INT
AS
BEGIN

-- 1. Simple IF - completely broken
IF
(
@A
=
1
)
BEGIN
SELECT 1;
END


-- 2. Multiple IF - random layout
IF(@A=1 AND
@B
=
2)
BEGIN
SELECT 1;
END


-- 3. Nested Boolean - deliberately ugly
IF( @A=1
AND(@B
=
2 OR
@C=3))
BEGIN
SELECT 1;
END


-- 4. Different nesting
IF
((
@A=1
OR @B=2
)
AND
@C=3)
BEGIN
SELECT 1;
END


-- 5. Comment inside simple condition
IF(
@A=1 -- important condition
)
BEGIN
SELECT 1;
END


-- 6. Comment inside multiple condition
IF(@A=1
AND
@B=2 -- second condition
)
BEGIN
SELECT 1;
END


-- 7. WHILE simple - badly broken
WHILE
(
@A
<
10
)
BEGIN
SET @A=@A+1;
END


-- 8. WHILE multiple - mixed same/new lines
WHILE(@A<10 AND
@B
=
2)
BEGIN
SET @A=@A+1;
END


-- 9. WHILE nested - ugly parentheses
WHILE(
@A<10
AND(@B=2
OR
@C=3))
BEGIN
SET @A=@A+1;
END


-- 10. IF without BEGIN END
IF(@A=1 AND @B=2)
SELECT 1;


-- 11. Nested IF
IF(@A=1)
BEGIN
IF(
@B=2
AND
@C=3)
BEGIN
SELECT 1;
END
END

END;
