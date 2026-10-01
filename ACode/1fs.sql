DECLARE @Table1 SYSNAME = '##PWCTRANSACTION_20260930';
DECLARE @Table2 SYSNAME = '##PWCTRANSACTION_20261001';

DECLARE @Table1ObjectID INT = OBJECT_ID('tempdb..' + @Table1);
DECLARE @Table2ObjectID INT = OBJECT_ID('tempdb..' + @Table2);

DECLARE @Table1Columns NVARCHAR(MAX);
DECLARE @Table2Columns NVARCHAR(MAX);
DECLARE @SQL           NVARCHAR(MAX);

------------------------------------------------------------
-- Build all comparable columns except the two join columns
------------------------------------------------------------
SELECT
    @Table1Columns =
        STRING_AGG
        (
            CONVERT(NVARCHAR(MAX), 'T1.' + QUOTENAME(C1.name)),
            ','
        ) WITHIN GROUP (ORDER BY C1.column_id),

    @Table2Columns =
        STRING_AGG
        (
            CONVERT(NVARCHAR(MAX), 'T2.' + QUOTENAME(C1.name)),
            ','
        ) WITHIN GROUP (ORDER BY C1.column_id)
FROM tempdb.sys.columns AS C1
INNER JOIN tempdb.sys.columns AS C2
    ON  C2.object_id = @Table2ObjectID
    AND C2.name      = C1.name
WHERE C1.object_id = @Table1ObjectID
  AND C1.name NOT IN
      (
          'MICROFILM_REF_NUMBER',
          'MICROFILM_REF_SEQ'
      );

------------------------------------------------------------
-- Return only missing or different records
------------------------------------------------------------
SET @SQL = N'
SELECT
    CASE
        WHEN T1.RowExists IS NULL THEN ''Missing from 20260930''
        WHEN T2.RowExists IS NULL THEN ''Missing from 20261001''
        ELSE ''Column value differs''
    END AS DifferenceType,

    COALESCE
    (
        T1.MICROFILM_REF_NUMBER,
        T2.MICROFILM_REF_NUMBER
    ) AS MICROFILM_REF_NUMBER,

    COALESCE
    (
        T1.MICROFILM_REF_SEQ,
        T2.MICROFILM_REF_SEQ
    ) AS MICROFILM_REF_SEQ,

    T1.*,
    T2.*
FROM
(
    SELECT
        1 AS RowExists,
        *
    FROM ' + QUOTENAME(@Table1) + N'
) AS T1
FULL OUTER JOIN
(
    SELECT
        1 AS RowExists,
        *
    FROM ' + QUOTENAME(@Table2) + N'
) AS T2
    ON  T2.MICROFILM_REF_NUMBER = T1.MICROFILM_REF_NUMBER
    AND T2.MICROFILM_REF_SEQ    = T1.MICROFILM_REF_SEQ
WHERE
       T1.RowExists IS NULL
    OR T2.RowExists IS NULL
    OR EXISTS
       (
           SELECT ' + @Table1Columns + N'
           EXCEPT
           SELECT ' + @Table2Columns + N'
       );';

EXEC sys.sp_executesql @SQL;
