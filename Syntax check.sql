SELECT
    @V_ExpressionEscaped = REPLACE(@V_Expression, '''', '''''');

SELECT
    @V_SQL =
N'
DECLARE @V_InnerSQL NVARCHAR(MAX);

BEGIN TRY

    SELECT
        @V_InnerSQL =
        N''SELECT TOP 1 1
          FROM
          (
              SELECT
                   ' + @V_DummyColumnList + N'
          ) AS A
          WHERE ' + @V_ExpressionEscaped + N''';

    EXEC sp_executesql @V_InnerSQL;

    SELECT
         @P_IsSyntaxValid = ''Y''
        ,@P_ErrorMessage = NULL;

END TRY
BEGIN CATCH

    SELECT
         @P_IsSyntaxValid = ''N''
        ,@P_ErrorMessage = ERROR_MESSAGE();

END CATCH;
';
