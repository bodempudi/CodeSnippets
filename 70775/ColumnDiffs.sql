;WITH ColumnDefinition AS
(
    SELECT
          c.name AS ColumnName
        , s.name AS SchemaName
        , t.name AS TableName
        , ty.name AS DataTypeName
        , c.max_length
        , c.precision
        , c.scale
        , c.is_nullable
        , DataTypeDefinition =
            ty.name
            + CASE
                WHEN ty.name IN ('varchar','char','varbinary','binary')
                    THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX'
                                    ELSE CONVERT(VARCHAR(10), c.max_length)
                               END + ')'

                WHEN ty.name IN ('nvarchar','nchar')
                    THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX'
                                    ELSE CONVERT(VARCHAR(10), c.max_length / 2)
                               END + ')'

                WHEN ty.name IN ('decimal','numeric')
                    THEN '(' + CONVERT(VARCHAR(10), c.precision)
                         + ',' + CONVERT(VARCHAR(10), c.scale) + ')'

                WHEN ty.name IN ('datetime2','datetimeoffset','time')
                    THEN '(' + CONVERT(VARCHAR(10), c.scale) + ')'

                ELSE ''
              END
            + CASE
                WHEN c.is_nullable = 1 THEN ' NULL'
                ELSE ' NOT NULL'
              END
    FROM sys.columns c
    INNER JOIN sys.tables t
        ON c.object_id = t.object_id
    INNER JOIN sys.schemas s
        ON t.schema_id = s.schema_id
    INNER JOIN sys.types ty
        ON c.user_type_id = ty.user_type_id
    WHERE t.is_ms_shipped = 0
)
SELECT
      ColumnName
    , DefinitionCount = COUNT(DISTINCT DataTypeDefinition)
    , TableCount = COUNT(*)
FROM ColumnDefinition
GROUP BY ColumnName
HAVING COUNT(DISTINCT DataTypeDefinition) > 1
ORDER BY ColumnName;

;WITH ColumnDefinition AS
(
    SELECT
          c.name AS ColumnName
        , s.name AS SchemaName
        , t.name AS TableName
        , DataTypeDefinition =
            ty.name
            + CASE
                WHEN ty.name IN ('varchar','char','varbinary','binary')
                    THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX'
                                    ELSE CONVERT(VARCHAR(10), c.max_length)
                               END + ')'
                WHEN ty.name IN ('nvarchar','nchar')
                    THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX'
                                    ELSE CONVERT(VARCHAR(10), c.max_length / 2)
                               END + ')'
                WHEN ty.name IN ('decimal','numeric')
                    THEN '(' + CONVERT(VARCHAR(10), c.precision)
                         + ',' + CONVERT(VARCHAR(10), c.scale) + ')'
                WHEN ty.name IN ('datetime2','datetimeoffset','time')
                    THEN '(' + CONVERT(VARCHAR(10), c.scale) + ')'
                ELSE ''
              END
            + CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    WHERE t.is_ms_shipped = 0
),
MismatchColumns AS
(
    SELECT ColumnName
    FROM ColumnDefinition
    GROUP BY ColumnName
    HAVING COUNT(DISTINCT DataTypeDefinition) > 1
)
SELECT
      cd.ColumnName
    , cd.SchemaName
    , cd.TableName
    , cd.DataTypeDefinition
FROM ColumnDefinition cd
INNER JOIN MismatchColumns mc
    ON mc.ColumnName = cd.ColumnName
ORDER BY
      cd.ColumnName
    , cd.DataTypeDefinition
    , cd.SchemaName
    , cd.TableName;
