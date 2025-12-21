
SET NOCOUNT ON;
GO
/*==================================================================================================
SP: usp_Categorization_GetCategoryIDFromMerchantExpression
Point-2 mode:
- Expression column stores ONLY a raw SQL LIKE pattern OR a raw REGEX pattern.
- Since expression doesn't specify the field, engine tests the pattern against a prioritized list of fields.

Field priority (merchant):
1) SubMerchatNameEN
2) MerchatNameEN
3) TransactionNarration

On match:
- returns MerchatOtherID (from MerchatExpression.MerchatOtherID)
- derives CategoryID from MerchatOther.CategoryID (may be NULL if not mapped yet)
==================================================================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Categorization_GetCategoryIDFromMerchantExpression
(
      @I_TenantCode                         VARCHAR(50)
    , @I_TenantISOCountryCode               CHAR(2)
    , @I_LineOfBusinessName                 VARCHAR(128)

    , @I_TransactionNarration               VARCHAR(256)    = NULL
    , @I_MerchantNameEN                     VARCHAR(128)    = NULL
    , @I_SubMerchantNameEN                  VARCHAR(128)    = NULL

    , @I_IsHealingMode                      CHAR(1)         = 'Y'
    , @I_UserID                             VARCHAR(20)

    , @I_CategorizationPathMerchant         NVARCHAR(MAX)   = NULL
    , @I_CategorizationPathCategory         NVARCHAR(MAX)   = NULL

    , @O_MerchantOtherID                    BIGINT          OUTPUT
    , @O_CategoryID                         BIGINT          OUTPUT
    , @O_CategorizationPathMerchant         NVARCHAR(MAX)   OUTPUT
    , @O_CategorizationPathCategory         NVARCHAR(MAX)   OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
          @V_TenantID BIGINT
        , @V_ExprID BIGINT
        , @V_Order INT
        , @V_Type CHAR(1)
        , @V_FieldName SYSNAME;

    SET @O_CategoryID = NULL;
    SET @O_MerchantOtherID = NULL;

    SET @O_CategorizationPathMerchant = @I_CategorizationPathMerchant;
    SET @O_CategorizationPathCategory = @I_CategorizationPathCategory;

    SELECT @V_TenantID = t.TenantID
    FROM InMem.Tenant t WITH (NOLOCK)
    WHERE t.TenantCode=@I_TenantCode
      AND t.TennantISOCountryCode=@I_TenantISOCountryCode
      AND t.IsActive='Y';

    ;WITH Expr AS
    (
        SELECT TOP (2000)
              me.MerchantExpressionID
            , me.Expression
            , me.IsSQLORRegEx
            , me.IsExpressionCaseSensitive
            , me.ExecutionOrder
            , me.MerchatOtherID
        FROM InMem.MerchatExpression me WITH (NOLOCK)
        WHERE me.TennantID=@V_TenantID
          AND me.IsActive='Y'
        ORDER BY me.ExecutionOrder, me.MerchantExpressionID
    ),
    Fields AS
    (
        SELECT 1 AS FieldOrder, CAST(N'SubMerchatNameEN' AS SYSNAME) AS FieldName, CAST(@I_SubMerchantNameEN AS NVARCHAR(4000)) AS FieldValue
        UNION ALL
        SELECT 2, N'MerchatNameEN', CAST(@I_MerchantNameEN AS NVARCHAR(4000))
        UNION ALL
        SELECT 3, N'TransactionNarration', CAST(@I_TransactionNarration AS NVARCHAR(4000))
    ),
    MatchCandidates AS
    (
        SELECT
              e.MerchantExpressionID
            , e.ExecutionOrder
            , e.IsSQLORRegEx
            , e.IsExpressionCaseSensitive
            , e.MerchatOtherID
            , f.FieldName
            , f.FieldOrder
            , CASE
                WHEN NULLIF(LTRIM(RTRIM(f.FieldValue)),N'') IS NULL THEN 0
                WHEN e.IsSQLORRegEx='S' THEN
                    CASE WHEN COALESCE(e.IsExpressionCaseSensitive,'N')='Y'
                         THEN IIF(f.FieldValue LIKE e.Expression COLLATE Latin1_General_BIN2, 1, 0)
                         ELSE IIF(f.FieldValue LIKE e.Expression, 1, 0) END
                WHEN e.IsSQLORRegEx='R' THEN dbo.fn_Categorization_RegexIsMatch(e.Expression, f.FieldValue, COALESCE(e.IsExpressionCaseSensitive,'N'))
                ELSE 0
              END AS IsMatch
        FROM Expr e
        CROSS JOIN Fields f
    )
    SELECT TOP (1)
          @V_ExprID = mc.MerchantExpressionID
        , @V_Order  = mc.ExecutionOrder
        , @V_Type   = mc.IsSQLORRegEx
        , @O_MerchantOtherID = mc.MerchatOtherID
        , @V_FieldName = mc.FieldName
    FROM MatchCandidates mc
    WHERE mc.IsMatch = 1
    ORDER BY mc.ExecutionOrder, mc.MerchantExpressionID, mc.FieldOrder;

    IF @O_MerchantOtherID IS NOT NULL
    BEGIN
        SELECT TOP (1) @O_CategoryID = mo.CategoryID
        FROM InMem.MerchatOther mo WITH (NOLOCK)
        WHERE mo.MerchatOtherID=@O_MerchantOtherID
          AND mo.IsActive='Y';

        EXEC dbo.usp_Categorization_PathAppendMerchant
              @O_CategorizationPathMerchant
            , N'SP03|Hit'
            , CONCAT(N'ExprID=',@V_ExprID,N'|Ord=',@V_Order,N'|Type=',@V_Type,N'|Field=',@V_FieldName,N'|MOID=',@O_MerchantOtherID)
            , 'Y'
            , @O_CategoryID
            , N'From=MerchatExpression (pattern) -> MerchatOther.CategoryID'
            , 'N'
            , @O_CategorizationPathMerchant OUTPUT;

        EXEC dbo.usp_Categorization_PathAppendCategory
              @O_CategorizationPathCategory
            , N'SP03|CatFromMerchantExpr'
            , CONCAT(N'MOID=',@O_MerchantOtherID,N'|Field=',@V_FieldName)
            , CASE WHEN @O_CategoryID IS NULL THEN 'N' ELSE 'Y' END
            , @O_CategoryID
            , N'Reason=MerchantExpression matched (Category may be NULL if not mapped)'
            , 'N'
            , @O_CategorizationPathCategory OUTPUT;
    END
    ELSE
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendMerchant
              @O_CategorizationPathMerchant
            , N'SP03|NoMatch'
            , NULL
            , 'N'
            , NULL
            , N'Reason=No match'
            , 'N'
            , @O_CategorizationPathMerchant OUTPUT;
    END

    RETURN 0;
END
GO
