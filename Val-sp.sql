CREATE OR ALTER PROCEDURE dbo.usp_Validate_CategorizationExpression
(
     @I_TennantID BIGINT = NULL
    ,@I_Expression VARCHAR(8000)
    ,@I_ExpressionTypeCode VARCHAR(128)
    ,@I_SampleData NVARCHAR(MAX) = NULL
    ,@I_PlaceHolder VARCHAR(128) = '@expr_'

    ,@O_Result INT OUTPUT
    ,@O_StatusCode VARCHAR(32) OUTPUT
    ,@O_StatusMessage VARCHAR(4000) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
         @V_Expression NVARCHAR(MAX) = N''
        ,@V_SQL NVARCHAR(MAX) = N''
        ,@V_ErrorMessage VARCHAR(4000) = ''
        ,@V_MatchedRowCount INT = 0
        ,@V_TotalRowCount INT = 0
        ,@V_Pos INT = 1
        ,@V_Start INT
        ,@V_End INT
        ,@V_FieldName VARCHAR(256);

    BEGIN TRY

        ------------------------------------------------------------
        -- Input normalization
        ------------------------------------------------------------
        SELECT
             @I_Expression = NULLIF(LTRIM(RTRIM(@I_Expression)), '')
            ,@I_ExpressionTypeCode = NULLIF(LTRIM(RTRIM(@I_ExpressionTypeCode)), '')
            ,@I_PlaceHolder = ISNULL(NULLIF(LTRIM(RTRIM(@I_PlaceHolder)), ''), '@expr_');

        ------------------------------------------------------------
        -- Mandatory validations
        ------------------------------------------------------------
        IF @I_Expression IS NULL
        BEGIN
            RAISERROR('@I_Expression is mandatory.', 16, 1);
        END;

        IF @I_ExpressionTypeCode NOT IN ('CATEGORY', 'MERCHANT')
        BEGIN
            RAISERROR('Invalid @I_ExpressionTypeCode. Only CATEGORY / MERCHANT is allowed.', 16, 1);
        END;

        IF ISJSON(@I_SampleData) <> 1
        BEGIN
            RAISERROR('@I_SampleData must be valid JSON.', 16, 1);
        END;

        ------------------------------------------------------------
        -- Basic unsafe token validation
        ------------------------------------------------------------
        IF
        (
               @I_Expression LIKE '%;%'
            OR UPPER(@I_Expression) LIKE '% DROP %'
            OR UPPER(@I_Expression) LIKE '% DELETE %'
            OR UPPER(@I_Expression) LIKE '% INSERT %'
            OR UPPER(@I_Expression) LIKE '% UPDATE %'
            OR UPPER(@I_Expression) LIKE '% ALTER %'
            OR UPPER(@I_Expression) LIKE '% EXEC %'
            OR @I_Expression LIKE '%--%'
            OR @I_Expression LIKE '%/*%'
            OR @I_Expression LIKE '%*/%'
        )
        BEGIN
            RAISERROR('Unsafe expression detected.', 16, 1);
        END;

        ------------------------------------------------------------
        -- Replace placeholder
        ------------------------------------------------------------
        SELECT
            @V_Expression = REPLACE(@I_Expression, @I_PlaceHolder, '');

        ------------------------------------------------------------
        -- Extract fields used in expression
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#ExpressionFieldUsed') IS NOT NULL
            DROP TABLE #ExpressionFieldUsed;

        CREATE TABLE #ExpressionFieldUsed
        (
            ExpressionFieldName VARCHAR(256) NOT NULL PRIMARY KEY
        );

        WHILE 1 = 1
        BEGIN
            SET @V_Start = CHARINDEX(@I_PlaceHolder, @I_Expression, @V_Pos);

            IF @V_Start = 0
                BREAK;

            SET @V_Start = @V_Start + LEN(@I_PlaceHolder);
            SET @V_End = @V_Start;

            WHILE
            (
                   @V_End <= LEN(@I_Expression)
               AND SUBSTRING(@I_Expression, @V_End, 1) LIKE '[A-Za-z0-9_]'
            )
            BEGIN
                SET @V_End = @V_End + 1;
            END;

            SELECT
                @V_FieldName = SUBSTRING(@I_Expression, @V_Start, @V_End - @V_Start);

            IF NOT EXISTS
            (
                SELECT 1
                FROM #ExpressionFieldUsed efu
                WHERE efu.ExpressionFieldName = @V_FieldName
            )
            BEGIN
                INSERT INTO #ExpressionFieldUsed
                (
                    ExpressionFieldName
                )
                VALUES
                (
                    @V_FieldName
                );
            END;

            SET @V_Pos = @V_End;
        END;

        ------------------------------------------------------------
        -- Validate extracted fields against metadata
        ------------------------------------------------------------
        IF EXISTS
        (
            SELECT 1
            FROM #ExpressionFieldUsed efu
            WHERE NOT EXISTS
            (
                SELECT 1
                FROM InMem.ExpressionField ef WITH (NOLOCK)
                WHERE ef.ExpressionFieldName = efu.ExpressionFieldName
                  AND ef.TennantID = @I_TennantID
                  AND ef.IsActive = 'Y'
                  AND
                  (
                         (@I_ExpressionTypeCode = 'CATEGORY' AND ef.IsApplicableForCategoryExpression = 'Y')
                      OR (@I_ExpressionTypeCode = 'MERCHANT' AND ef.IsApplicableForMerchantExpression = 'Y')
                  )
            )
        )
        BEGIN
            RAISERROR('Expression contains invalid field(s) for selected ExpressionTypeCode.', 16, 1);
        END;

        ------------------------------------------------------------
        -- Build sample data temp table dynamically from metadata
        ------------------------------------------------------------
        IF OBJECT_ID('tempdb..#SampleData') IS NOT NULL
            DROP TABLE #SampleData;

        DECLARE @V_OpenJsonWith NVARCHAR(MAX) = N'';
        DECLARE @V_CreateTableSql NVARCHAR(MAX) = N'';
        DECLARE @V_FieldList NVARCHAR(MAX) = N'';

        SELECT
            @V_OpenJsonWith =
                STRING_AGG
                (
                    CONVERT
                    (
                        NVARCHAR(MAX)
                        ,QUOTENAME(ef.ExpressionFieldName)
                        + N' '
                        + ef.ExpressionDataType
                        + N' ''$.'
                        + ef.ExpressionFieldName
                        + N''''
                    )
                    ,N','
                )
            ,@V_FieldList =
                STRING_AGG
                (
                    CONVERT(NVARCHAR(MAX), QUOTENAME(ef.ExpressionFieldName))
                    ,N','
                )
        FROM InMem.ExpressionField ef WITH (NOLOCK)
        WHERE ef.TennantID = @I_TennantID
          AND ef.IsActive = 'Y'
          AND
          (
                 (@I_ExpressionTypeCode = 'CATEGORY' AND ef.IsApplicableForCategoryExpression = 'Y')
              OR (@I_ExpressionTypeCode = 'MERCHANT' AND ef.IsApplicableForMerchantExpression = 'Y')
          );

        SELECT
            @V_CreateTableSql =
            N'
            SELECT
                ' + @V_FieldList + N'
            INTO #SampleData
            FROM OPENJSON(@P_SampleData)
            WITH
            (
                ' + @V_OpenJsonWith + N'
            );
            ';

        EXEC sp_executesql
             @V_CreateTableSql
            ,N'@P_SampleData NVARCHAR(MAX)'
            ,@P_SampleData = @I_SampleData;

        ------------------------------------------------------------
        -- Syntax check + actual execution against sample rows
        -- Result rule: 1 if ANY row matches
        ------------------------------------------------------------
        SELECT
            @V_SQL =
            N'
            SELECT
                 @P_TotalRowCount = COUNT(1)
                ,@P_MatchedRowCount =
                    SUM
                    (
                        CASE
                            WHEN ' + @V_Expression + N'
                                THEN 1
                            ELSE 0
                        END
                    )
            FROM #SampleData;

            SELECT
                @P_Result =
                    CASE
                        WHEN ISNULL(@P_MatchedRowCount, 0) > 0
                            THEN 1
                        ELSE 0
                    END;
            ';

        EXEC sp_executesql
             @V_SQL
            ,N'@P_Result INT OUTPUT
              ,@P_MatchedRowCount INT OUTPUT
              ,@P_TotalRowCount INT OUTPUT'
            ,@P_Result = @O_Result OUTPUT
            ,@P_MatchedRowCount = @V_MatchedRowCount OUTPUT
            ,@P_TotalRowCount = @V_TotalRowCount OUTPUT;

        ------------------------------------------------------------
        -- Success
        ------------------------------------------------------------
        SELECT
             @O_StatusCode = '0'
            ,@O_StatusMessage =
                'SUCCESS. MatchedRowCount = '
                + CONVERT(VARCHAR(20), ISNULL(@V_MatchedRowCount, 0))
                + ', TotalRowCount = '
                + CONVERT(VARCHAR(20), ISNULL(@V_TotalRowCount, 0));

    END TRY
    BEGIN CATCH

        SELECT
             @V_ErrorMessage = ISNULL(ERROR_MESSAGE(), '');

        SELECT
             @O_Result = 0
            ,@O_StatusCode = '1'
            ,@O_StatusMessage = @V_ErrorMessage;

        RETURN;
    END CATCH;
END;
GO
