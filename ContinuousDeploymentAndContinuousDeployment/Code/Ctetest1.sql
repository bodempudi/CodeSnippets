/* ============================================================
   TEST 1 - CTE + SELECT
   ============================================================ */

SELECT 1;

;WITH CTE AS
(
    SELECT 1 AS A
)
SELECT *
FROM CTE;


/* ============================================================
   TEST 2 - CTE + INSERT
   ============================================================ */

SELECT 1;

;WITH CTE AS
(
    SELECT 1 AS A
)
INSERT INTO dbo.T1
(
    A
)
SELECT A
FROM CTE;


/* ============================================================
   TEST 3 - CTE + UPDATE
   ============================================================ */

SELECT 1;

;WITH CTE AS
(
    SELECT Id
    FROM dbo.T1
)
UPDATE T
SET T.Col1 = 1
FROM dbo.T1 AS T
INNER JOIN CTE AS C
    ON C.Id = T.Id;


/* ============================================================
   TEST 4 - CTE + DELETE
   ============================================================ */

SELECT 1;

;WITH CTE AS
(
    SELECT Id
    FROM dbo.T1
)
DELETE T
FROM dbo.T1 AS T
INNER JOIN CTE AS C
    ON C.Id = T.Id;


/* ============================================================
   TEST 5 - CTE + MERGE
   ============================================================ */

SELECT 1;

;WITH CTE AS
(
    SELECT Id
    FROM dbo.Source
)
MERGE dbo.Target AS T
USING CTE AS S
    ON T.Id = S.Id
WHEN MATCHED THEN
    UPDATE
    SET T.Id = S.Id;


/* ============================================================
   TEST 6 - PREVIOUS STATEMENT OWNS SEMICOLON
   IMPORTANT NEGATIVE TEST
   ============================================================ */

SELECT 1;
WITH CTE AS
(
    SELECT 1 AS A
)
SELECT *
FROM CTE;


/* ============================================================
   TEST 7 - COMMENT BEFORE ;WITH
   ============================================================ */

SELECT 1;

-- Customer processing
;WITH CTE AS
(
    SELECT 1 AS A
)
SELECT *
FROM CTE;


/* ============================================================
   TEST 8 - MULTIPLE CTEs
   ============================================================ */

SELECT 1;

;WITH CTE1 AS
(
    SELECT 1 AS A
),
CTE2 AS
(
    SELECT A
    FROM CTE1
)
SELECT *
FROM CTE2;


/* ============================================================
   TEST 9 - CTE AS FIRST STATEMENT
   ============================================================ */

;WITH CTE AS
(
    SELECT 1 AS A
)
SELECT *
FROM CTE;


/* ============================================================
   TEST 10 - NORMAL STATEMENTS / SEMICOLON REGRESSION
   ============================================================ */

SELECT 1;
SELECT 2;

UPDATE dbo.T1
SET Col1 = 1;

DELETE FROM dbo.T1
WHERE Id = -1;


/* ============================================================
   FINAL TEST
   ============================================================ */

-- Run formatter once.
-- Copy/save the result.
-- Run formatter a SECOND time.
-- Output after second format must be identical to first format.
