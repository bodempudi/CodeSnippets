DECLARE
      @I_DataCategory NVARCHAR(50) = N'Merchant'
    , @I_Expression   NVARCHAR(MAX) = N'MerchantName = ''Lulu'' AND MerchantId = 1001'
    , @I_UserJson     NVARCHAR(MAX)
    , @SQL            NVARCHAR(MAX)
    , @ColumnDDL      NVARCHAR(MAX)
    , @ColumnList     NVARCHAR(MAX)
    , @OpenJsonWith   NVARCHAR(MAX)
    , @ResultJson     NVARCHAR(MAX);

SET @I_UserJson = N'
{
  "User": [
    {"RowNo":1,"MerchantId":1001,"MerchantName":"Lulu"},
    {"RowNo":2,"MerchantId":1002,"MerchantName":"Carrefour"}
  ]
}';

DROP TABLE IF EXISTS #Metadata;

CREATE TABLE #Metadata
(
      DataCategory NVARCHAR(50)
    , ColumnName   SYSNAME
    , DataType     NVARCHAR(50)
    , SampleData   NVARCHAR(MAX)
);

INSERT INTO #Metadata
VALUES
('Merchant','MerchantId',   'INT',           '1001||1002'),
('Merchant','MerchantName', 'NVARCHAR(100)', 'Lulu||Carrefour'),

('Category','CategoryId',   'INT',           '10||20||30'),
('Category','CategoryName', 'NVARCHAR(100)', 'Grocery||Fuel||Dining'),
('Category','MCC',          'VARCHAR(10)',   '5411||5541||5812');

SELECT
      @ColumnDDL =
          STRING_AGG(QUOTENAME(ColumnName) + N' ' + DataType, N',' + CHAR(13))
    , @ColumnList =
          STRING_AGG(QUOTENAME(ColumnName), N',')
    , @OpenJsonWith =
          STRING_AGG(
              QUOTENAME(ColumnName) + N' ' + DataType
              + N' ''$."' + ColumnName + N'"''',
              N',' + CHAR(13)
          )
FROM #Metadata
WHERE DataCategory = @I_DataCategory;

SET @SQL = N'
CREATE TABLE #EvaluationData
(
      SourceType NVARCHAR(20)
    , RowNo INT
    , ' + @ColumnDDL + N'
);

INSERT INTO #EvaluationData
(
      SourceType
    , RowNo
    , ' + @ColumnList + N'
)
SELECT
      ''User''
    , RowNo
    , ' + @ColumnList + N'
FROM OPENJSON(@I_UserJson, ''$.User'')
WITH
(
      RowNo INT ''$.RowNo''
    , ' + @OpenJsonWith + N'
);

;WITH SplitData AS
(
    SELECT
          m.ColumnName
        , s.ID AS RowNo
        , s.Data AS DataValue
    FROM #Metadata m
    CROSS APPLY dbo.udf_GetSplitText(m.SampleData, ''||'') s
    WHERE m.DataCategory = @I_DataCategory
),
SystemData AS
(
    SELECT
          RowNo
        , ' + @ColumnList + N'
    FROM SplitData
    PIVOT
    (
        MAX(DataValue)
        FOR ColumnName IN (' + @ColumnList + N')
    ) p
)
INSERT INTO #EvaluationData
(
      SourceType
    , RowNo
    , ' + @ColumnList + N'
)
SELECT
      ''System''
    , RowNo
    , ' + @ColumnList + N'
FROM SystemData;

;WITH Evaluated AS
(
    SELECT
          *
        , Result =
            CASE
                WHEN ' + @I_Expression + N'
                THEN ''Passed''
                ELSE ''Failed''
            END
    FROM #EvaluationData
)
SELECT @ResultJson =
(
    SELECT
          UserData =
          JSON_QUERY
          (
              (
                  SELECT
                        RowNo
                      , ' + @ColumnList + N'
                      , Result
                  FROM Evaluated
                  WHERE SourceType = ''User''
                  ORDER BY RowNo
                  FOR JSON PATH
              )
          )
        , SystemData =
          JSON_QUERY
          (
              (
                  SELECT
                        RowNo
                      , ' + @ColumnList + N'
                      , Result
                  FROM Evaluated
                  WHERE SourceType = ''System''
                  ORDER BY RowNo
                  FOR JSON PATH
              )
          )
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
);';

EXEC sys.sp_executesql
      @SQL
    , N'@I_DataCategory NVARCHAR(50), @I_UserJson NVARCHAR(MAX), @ResultJson NVARCHAR(MAX) OUTPUT'
    , @I_DataCategory = @I_DataCategory
    , @I_UserJson = @I_UserJson
    , @ResultJson = @ResultJson OUTPUT;

SELECT @ResultJson AS ResultJson;
