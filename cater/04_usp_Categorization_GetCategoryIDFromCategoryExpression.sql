
SET NOCOUNT ON;
GO
/*==================================================================================================
SP: usp_Categorization_GetCategoryIDFromCategoryExpression
Point-2 mode:
- Expression column stores ONLY a raw SQL LIKE pattern OR a raw REGEX pattern.
- Expression does not specify the field. Engine tests the pattern against a prioritized list of fields.

Field priority (category):
1) TransactionNarration

(You can expand later to BankCode/EbillServiceID/etc once you decide inputs for category expressions.)

TxnType association:
- If TransactionTypeCode is provided and association rows exist, evaluate only associated expressions for that txn type.
- Otherwise evaluate all active expressions for the phase.

ExecutionTypeCodePhase:
- PRE / POST / OVERRIDE
==================================================================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Categorization_GetCategoryIDFromCategoryExpression
(
      @I_ExecutionTypeCodePhase            VARCHAR(10)     = 'POST'

    , @I_TenantCode                         VARCHAR(50)
    , @I_TenantISOCountryCode               CHAR(2)
    , @I_LineOfBusinessName                 VARCHAR(128)

    , @I_TransactionTypeCode                VARCHAR(128)    = NULL
    , @I_TransactionTypeNameEN              VARCHAR(128)    = NULL
    , @I_TransactionTypeNameAR              VARCHAR(128)    = NULL
    , @I_TransactionNarration               VARCHAR(256)    = NULL

    , @I_IsHealingMode                      CHAR(1)         = 'Y'
    , @I_UserID                             VARCHAR(20)

    , @I_CategorizationPathMerchant         NVARCHAR(MAX)   = NULL
    , @I_CategorizationPathCategory         NVARCHAR(MAX)   = NULL

    , @O_CategoryID                         BIGINT          OUTPUT
    , @O_CategorizationPathMerchant         NVARCHAR(MAX)   OUTPUT
    , @O_CategorizationPathCategory         NVARCHAR(MAX)   OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
          @V_TenantID BIGINT
        , @V_LobID BIGINT
        , @V_Phase VARCHAR(10)
        , @V_TxnType VARCHAR(128)
        , @V_CTTID BIGINT
        , @V_ExprID BIGINT
        , @V_Order INT
        , @V_Type CHAR(1)
        , @V_FieldName SYSNAME
        , @V_HasAssoc BIT = 0;

    SET @O_CategoryID = NULL;
    SET @O_CategorizationPathMerchant = @I_CategorizationPathMerchant;
    SET @O_CategorizationPathCategory = @I_CategorizationPathCategory;

    SET @V_Phase = UPPER(COALESCE(NULLIF(@I_ExecutionTypeCodePhase,''),'POST'));
    SET @V_TxnType = NULLIF(LTRIM(RTRIM(@I_TransactionTypeCode)),'');

    SELECT @V_TenantID = t.TenantID
    FROM InMem.Tenant t WITH (NOLOCK)
    WHERE t.TenantCode=@I_TenantCode
      AND t.TennantISOCountryCode=@I_TenantISOCountryCode
      AND t.IsActive='Y';

    SELECT TOP (1) @V_LobID = lob.LineOfBusinessID
    FROM InMem.LineOfBusiness lob WITH (NOLOCK)
    WHERE lob.TennantID=@V_TenantID
      AND lob.LineOfBusinessName=@I_LineOfBusinessName;

    /* Resolve CategoryTransactionTypeID for association shortlist (optional) */
    IF @V_TxnType IS NOT NULL
    BEGIN
        SELECT TOP (1) @V_CTTID = ctt.CategoryTransactionTypeID
        FROM InMem.CategoryTransactionType ctt WITH (NOLOCK)
        WHERE ctt.TennantID=@V_TenantID
          AND ctt.LineOfBusinessID=@V_LobID
          AND ctt.TransactionTypeCode=@V_TxnType
          AND ctt.IsActive='Y';

        IF @V_CTTID IS NOT NULL AND EXISTS
        (
            SELECT 1
            FROM InMem.CategoryTransactionTypeExpressionAssociation a WITH (NOLOCK)
            WHERE a.CategoryTransactionTypeID=@V_CTTID
              AND a.IsActive='Y'
        )
        BEGIN
            SET @V_HasAssoc = 1;
        END
    END

    ;WITH Expr AS
    (
        SELECT TOP (2000)
              ce.CategoryExpressionID
            , ce.Expression
            , ce.IsSQLORRegEx
            , ce.IsExpressionCaseSensitive
            , ce.ExecutionOrder
            , ce.ExecutionTypeCode
            , ce.CategoryID
        FROM InMem.CategoryExpression ce WITH (NOLOCK)
        WHERE ce.TennantID=@V_TenantID
          AND ce.IsActive='Y'
          AND UPPER(COALESCE(NULLIF(ce.ExecutionTypeCode,''),'POST')) = @V_Phase
          AND
          (
              @V_HasAssoc = 0
              OR EXISTS
              (
                  SELECT 1
                  FROM InMem.CategoryTransactionTypeExpressionAssociation a WITH (NOLOCK)
                  WHERE a.CategoryTransactionTypeID=@V_CTTID
                    AND a.CategoryExpressionID=ce.CategoryExpressionID
                    AND a.IsActive='Y'
              )
          )
        ORDER BY ce.ExecutionOrder, ce.CategoryExpressionID
    ),
    Fields AS
    (
        SELECT 1 AS FieldOrder, CAST(N'TransactionNarration' AS SYSNAME) AS FieldName, CAST(@I_TransactionNarration AS NVARCHAR(4000)) AS FieldValue
    ),
    MatchCandidates AS
    (
        SELECT
              e.CategoryExpressionID
            , e.ExecutionOrder
            , e.IsSQLORRegEx
            , e.IsExpressionCaseSensitive
            , e.CategoryID
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
          @V_ExprID = mc.CategoryExpressionID
        , @V_Order  = mc.ExecutionOrder
        , @V_Type   = mc.IsSQLORRegEx
        , @V_FieldName = mc.FieldName
        , @O_CategoryID = mc.CategoryID
    FROM MatchCandidates mc
    WHERE mc.IsMatch = 1
    ORDER BY mc.ExecutionOrder, mc.CategoryExpressionID, mc.FieldOrder;

    IF @O_CategoryID IS NOT NULL
        EXEC dbo.usp_Categorization_PathAppendCategory
              @O_CategorizationPathCategory
            , CONCAT(N'SP04|',@V_Phase,N'|Hit')
            , CONCAT(N'ExprID=',@V_ExprID,N'|Ord=',@V_Order,N'|Type=',@V_Type,N'|Field=',@V_FieldName,N'|Assoc=',@V_HasAssoc)
            , 'Y'
            , @O_CategoryID
            , N'From=CategoryExpression.CategoryID'
            , 'N'
            , @O_CategorizationPathCategory OUTPUT;
    ELSE
        EXEC dbo.usp_Categorization_PathAppendCategory
              @O_CategorizationPathCategory
            , CONCAT(N'SP04|',@V_Phase,N'|NoMatch')
            , CONCAT(N'Assoc=',@V_HasAssoc)
            , 'N'
            , NULL
            , N'Reason=No match'
            , 'N'
            , @O_CategorizationPathCategory OUTPUT;

    RETURN 0;
END
GO
