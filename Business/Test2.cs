CREATE OR ALTER PROCEDURE dbo.TestBooleanRegression
    @A INT,
    @B INT,
    @C INT,
    @D INT
AS
BEGIN

-- 1. Equality split badly
IF(
@A
=
1
)
BEGIN
SELECT 1;
END

-- 2. Different operators
IF(
@A
<>
1
AND
@B
>=
2
AND
@C
<=
3
)
BEGIN
SELECT 1;
END

-- 3. Mixed AND / OR
IF(
@A=1
AND
@B
=
2
OR
@C
=
3
)
BEGIN
SELECT 1;
END

-- 4. Deep nested groups
IF(
@A=1
AND(
@B=2
OR(
@C
=
3
AND
@D
=
4
)
)
)
BEGIN
SELECT 1;
END

-- 5. Function inside comparison
IF(
ISNULL(
@A,
0
)
=
1
)
BEGIN
SELECT 1;
END

-- 6. NULL predicate
IF(
@A
IS
NULL
)
BEGIN
SELECT 1;
END

-- 7. NOT NULL predicate
IF(
@A
IS
NOT
NULL
)
BEGIN
SELECT 1;
END

-- 8. Comment inside multi-condition
IF(
@A=1
AND
@B
=
2 -- important
)
BEGIN
SELECT 1;
END

-- 9. WHILE comparison operators
WHILE(
@A
<
10
AND
@B
<>
0
)
BEGIN
SET @A=@A+1;
END

-- 10. Nested IF inside WHILE
WHILE(@A<10)
BEGIN
IF(
@B
=
2
AND
@C
=
3
)
BEGIN
BREAK;
END
SET @A=@A+1;
END

END;
