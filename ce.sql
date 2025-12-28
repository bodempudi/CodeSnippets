CREATE OR ALTER PROCEDURE dbo.usp_Categorization_GetCategoryIDFromCategoryExpression
(
      @I_TennantID                  INT
    , @I_TransactionTypeCode         NVARCHAR(50) = NULL     -- REQUIRED when ExecutionTypeCode='Override'
    , @I_ExecutionTypeCode           NVARCHAR(20)            -- 'Pre' | 'Override' | 'Post'

    , @I_Narration                   NVARCHAR(2000) = NULL
    , @I_MerchantNameEN              NVARCHAR(512)  = NULL
    , @I_SubMerchantNameEN           NVARCHAR(512)  = NULL
    , @I_MerchantCode                NVARCHAR(128)  = NULL
    , @I_MerchantCategoryCode        NVARCHAR(32)   = NULL   -- MCC

    , @I_Debug                       CHAR(1) = 'N'          -- Y/N

    , @O_CategoryID                  INT OUTPUT
    , @O_IsDefaultCategory           CHAR(1) OUTPUT         -- caller sets default, SP keeps 'N'
    , @O_CategorizationPathCategory  NVARCHAR(4000) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @O_CategoryID = NULL;
    SET @O_IsDefaultCategory = 'N';
    SET @O_CategorizationPathCategory = ISNULL(@O_CategorizationPathCategory, '');

    BEGIN TRY
        /*-----------------------------------------------------------------------------------------
            Guardrails for your team theory
            - Override requires TransactionTypeCode because association filter must be applied
        -----------------------------------------------------------------------------------------*/
        IF @I_ExecutionTypeCode = 'Override' AND (NULLIF(LTRIM(RTRIM(ISNULL(@I_TransactionTypeCode,''))), '') IS NULL)
        BEGIN
            SET @O_CategorizationPathCategory =
                CONCAT(@O_CategorizationPathCategory, '|CategoryExpression|Type=Override|ERROR=TransactionTypeCodeRequired');
            RETURN;
        END

        /*-----------------------------------------------------------------------------------------
            Normalize transaction elements (transaction-only engine)
        -----------------------------------------------------------------------------------------*/
        DECLARE
              @V_NARRATION         NVARCHAR(2000) = ISNULL(@I_Narration,'')
            , @V_MERCHANT_NAME     NVARCHAR(512)  = ISNULL(@I_MerchantNameEN,'')
            , @V_SUB_MERCHANT_NAME NVARCHAR(512)  = ISNULL(@I_SubMerchantNameEN,'')
            , @V_MERCHANT_CODE     NVARCHAR(128)  = ISNULL(@I_MerchantCode,'')
            , @V_MCC               NVARCHAR(32)   = ISNULL(@I_MerchantCategoryCode,'');

        /*-----------------------------------------------------------------------------------------
            Build one set-based dynamic statement to evaluate ALL eligible expressions
            - Expressions are stored as boolean predicates using placeholders:
                {NARRATION} {MERCHANT_NAME} {SUB_MERCHANT_NAME} {MERCHANT_CODE} {MCC}
            - First match wins by (ExecutionOrder, CategoryExpressionID)
        -----------------------------------------------------------------------------------------*/
        DECLARE
              @V_SQLBody  NVARCHAR(MAX) = NULL
            , @V_Dyn      NVARCHAR(MAX) = NULL
            , @V_ParamDef NVARCHAR(MAX) =
                N'@V_NARRATION nvarchar(2000),
                  @V_MERCHANT_NAME nvarchar(512),
                  @V_SUB_MERCHANT_NAME nvarchar(512),
                  @V_MERCHANT_CODE nvarchar(128),
                  @V_MCC nvarchar(32),
                  @O_WinExprID int OUTPUT,
                  @O_WinOrd int OUTPUT,
                  @O_WinCategoryID int OUTPUT,
                  @O_WinPredicate nvarchar(max) OUTPUT';

        DECLARE
              @O_WinExprID INT = NULL
            , @O_WinOrd INT = NULL
            , @O_WinCategoryID INT = NULL
            , @O_WinPredicate NVARCHAR(MAX) = NULL;

        ;WITH BaseRules AS
        (
            SELECT
                  ce.CategoryExpressionID
                , ce.ExecutionOrder
                , ce.CategoryID
                , ce.Expression
                , ce.IsExpressionCaseSensitive
                , ce.IsSQLORRegEx
                , ce.ExecutionTypeCode
            FROM dbo.CategoryExpression ce WITH (NOLOCK)
            WHERE ce.TennantID = @I_TennantID
              AND ce.IsActive  = 'Y'
              AND ce.ExecutionTypeCode = @I_ExecutionTypeCode

              -- Hard safety gate (same as your merchant-expression approach)
              AND ce.Expression NOT LIKE '%;%'  AND ce.Expression NOT LIKE '%--%'
              AND ce.Expression NOT LIKE '%/*%' AND ce.Expression NOT LIKE '%*/%'
              AND UPPER(ce.Expression) NOT LIKE '%EXEC%'
              AND UPPER(ce.Expression) NOT LIKE '%INSERT%'
              AND UPPER(ce.Expression) NOT LIKE '%UPDATE%'
              AND UPPER(ce.Expression) NOT LIKE '%DELETE%'
              AND UPPER(ce.Expression) NOT LIKE '%DROP%'
              AND UPPER(ce.Expression) NOT LIKE '%SELECT%'
        ),
        AssocFiltered AS
        (
            /* Your team theory:
               - Pre / Post : do NOT use association filter
               - Override   : MUST use association filter using TransactionTypeCode */
            SELECT br.*
            FROM BaseRules br
            WHERE
                (@I_ExecutionTypeCode <> 'Override')
                OR
                (
                    @I_ExecutionTypeCode = 'Override'
                    AND EXISTS
                    (
                        SELECT 1
                        FROM dbo.CategoryTransactionType ctt WITH (NOLOCK)
                        JOIN dbo.CategoryTransactionTypeExpressionAssociation a WITH (NOLOCK)
                          ON a.CategoryTransactionTypeID = ctt.CategoryTransactionTypeID
                         AND a.IsActive = 'Y'
                        WHERE ctt.TennantID = @I_TennantID
                          AND ctt.IsActive  = 'Y'
                          AND ctt.TransactionTypeCode = @I_TransactionTypeCode
                          AND a.CategoryExpressionID = br.CategoryExpressionID
                    )
                )
        ),
        Replaced AS
        (
            SELECT
                  CategoryExpressionID
                , ExecutionOrder
                , CategoryID
                , IsSQLORRegEx
                , IsCaseSensitive = ISNULL(IsExpressionCaseSensitive,'N')

                /* Replace placeholders -> variable references.
                   For SQL predicates (IsSQLORRegEx='S'):
                     - If case-insensitive, convert expression and fields to UPPER to make LIKE comparisons stable.
                   For REGEX predicates (IsSQLORRegEx='R'):
                     - Do NOT UPPER the regex expression text. Regex flags should be used by rule author (e.g. 'i').
                     - Still replace placeholders with variables (or UPPER(vars) if you really want; but recommend flags). */
                , PredicateSQL =
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        CASE
                            WHEN IsSQLORRegEx = 'S' AND ISNULL(IsExpressionCaseSensitive,'N')='N' THEN UPPER(Expression)
                            ELSE Expression
                        END
                    , '{NARRATION}',         CASE WHEN IsSQLORRegEx='S' AND ISNULL(IsExpressionCaseSensitive,'N')='N' THEN 'UPPER(@V_NARRATION)'          ELSE '@V_NARRATION' END)
                    , '{MERCHANT_NAME}',     CASE WHEN IsSQLORRegEx='S' AND ISNULL(IsExpressionCaseSensitive,'N')='N' THEN 'UPPER(@V_MERCHANT_NAME)'     ELSE '@V_MERCHANT_NAME' END)
                    , '{SUB_MERCHANT_NAME}', CASE WHEN IsSQLORRegEx='S' AND ISNULL(IsExpressionCaseSensitive,'N')='N' THEN 'UPPER(@V_SUB_MERCHANT_NAME)' ELSE '@V_SUB_MERCHANT_NAME' END)
                    , '{MERCHANT_CODE}',     CASE WHEN IsSQLORRegEx='S' AND ISNULL(IsExpressionCaseSensitive,'N')='N' THEN 'UPPER(@V_MERCHANT_CODE)'     ELSE '@V_MERCHANT_CODE' END)
                    , '{MCC}',               CASE WHEN IsSQLORRegEx='S' AND ISNULL(IsExpressionCaseSensitive,'N')='N' THEN 'UPPER(@V_MCC)'               ELSE '@V_MCC' END)
            FROM AssocFiltered
        ),
        Guarded AS
        (
            /* Must reference at least one placeholder/variable after replacement */
            SELECT *
            FROM Replaced
            WHERE PredicateSQL LIKE '%@V_%' OR PredicateSQL LIKE '%UPPER(@V_%'
        )
        SELECT
            @V_SQLBody =
                STRING_AGG(
                    CONCAT(
                        'SELECT ExprID=', CategoryExpressionID,
                        ', Ord=', ExecutionOrder,
                        ', CategoryID=', CategoryID,
                        ', Predicate=N''', REPLACE(REPLACE(PredicateSQL,'''',''''''), CHAR(10), ' '), '''',
                        ', IsMatch=CASE WHEN (', PredicateSQL, ') THEN 1 ELSE 0 END'
                    ),
                    CHAR(10) + 'UNION ALL' + CHAR(10)
                )
        FROM Guarded;

        IF @V_SQLBody IS NULL
        BEGIN
            SET @O_CategorizationPathCategory =
                CONCAT(@O_CategorizationPathCategory, '|CategoryExpression|Type=',@I_ExecutionTypeCode,'|NoValidRules');
            RETURN;
        END

        SET @V_Dyn = N'
;WITH X AS
(
' + @V_SQLBody + N'
)
SELECT TOP (1)
      @O_WinExprID = X.ExprID
    , @O_WinOrd = X.Ord
    , @O_WinCategoryID = X.CategoryID
    , @O_WinPredicate = X.Predicate
FROM X
WHERE X.IsMatch = 1
ORDER BY X.Ord, X.ExprID;
';

        IF @I_Debug='Y'
        BEGIN
            SELECT Debug_ExecutedDynamicSQL = @V_Dyn;
        END

        EXEC sp_executesql
              @V_Dyn
            , @V_ParamDef
            , @V_NARRATION = @V_NARRATION
            , @V_MERCHANT_NAME = @V_MERCHANT_NAME
            , @V_SUB_MERCHANT_NAME = @V_SUB_MERCHANT_NAME
            , @V_MERCHANT_CODE = @V_MERCHANT_CODE
            , @V_MCC = @V_MCC
            , @O_WinExprID = @O_WinExprID OUTPUT
            , @O_WinOrd = @O_WinOrd OUTPUT
            , @O_WinCategoryID = @O_WinCategoryID OUTPUT
            , @O_WinPredicate = @O_WinPredicate OUTPUT;

        IF @O_WinCategoryID IS NOT NULL
        BEGIN
            SET @O_CategoryID = @O_WinCategoryID;

            IF @I_Debug='Y'
            BEGIN
                /* Printable predicate (values substituted) */
                DECLARE @V_Printable NVARCHAR(MAX) = @O_WinPredicate;

                SET @V_Printable = REPLACE(@V_Printable, 'UPPER(@V_NARRATION)',         QUOTENAME(UPPER(@V_NARRATION),''''));
                SET @V_Printable = REPLACE(@V_Printable, 'UPPER(@V_MERCHANT_NAME)',     QUOTENAME(UPPER(@V_MERCHANT_NAME),''''));
                SET @V_Printable = REPLACE(@V_Printable, 'UPPER(@V_SUB_MERCHANT_NAME)', QUOTENAME(UPPER(@V_SUB_MERCHANT_NAME),''''));
                SET @V_Printable = REPLACE(@V_Printable, 'UPPER(@V_MERCHANT_CODE)',     QUOTENAME(UPPER(@V_MERCHANT_CODE),''''));
                SET @V_Printable = REPLACE(@V_Printable, 'UPPER(@V_MCC)',               QUOTENAME(UPPER(@V_MCC),''''));

                SET @V_Printable = REPLACE(@V_Printable, '@V_NARRATION',         QUOTENAME(@V_NARRATION,''''));
                SET @V_Printable = REPLACE(@V_Printable, '@V_MERCHANT_NAME',     QUOTENAME(@V_MERCHANT_NAME,''''));
                SET @V_Printable = REPLACE(@V_Printable, '@V_SUB_MERCHANT_NAME', QUOTENAME(@V_SUB_MERCHANT_NAME,''''));
                SET @V_Printable = REPLACE(@V_Printable, '@V_MERCHANT_CODE',     QUOTENAME(@V_MERCHANT_CODE,''''));
                SET @V_Printable = REPLACE(@V_Printable, '@V_MCC',               QUOTENAME(@V_MCC,''''));

                SET @O_CategorizationPathCategory =
                    CONCAT(@O_CategorizationPathCategory,
                           '|CategoryExpression|Type=',@I_ExecutionTypeCode,
                           CASE WHEN @I_ExecutionTypeCode='Override' THEN CONCAT('|TxnType=',@I_TransactionTypeCode) ELSE '' END,
                           '|ExprID=',@O_WinExprID,'|Order=',@O_WinOrd,'|Match=Y',
                           '|CategoryID=',@O_CategoryID,
                           '|Predicate=',@V_Printable);
            END
            ELSE
            BEGIN
                SET @O_CategorizationPathCategory =
                    CONCAT(@O_CategorizationPathCategory,
                           '|CategoryExpression|Type=',@I_ExecutionTypeCode,
                           CASE WHEN @I_ExecutionTypeCode='Override' THEN CONCAT('|TxnType=',@I_TransactionTypeCode) ELSE '' END,
                           '|ExprID=',@O_WinExprID,'|Order=',@O_WinOrd,'|Match=Y',
                           '|CategoryID=',@O_CategoryID);
            END

            RETURN;
        END

        SET @O_CategorizationPathCategory =
            CONCAT(@O_CategorizationPathCategory,
                   '|CategoryExpression|Type=',@I_ExecutionTypeCode,
                   CASE WHEN @I_ExecutionTypeCode='Override' THEN CONCAT('|TxnType=',@I_TransactionTypeCode) ELSE '' END,
                   '|Match=N');

    END TRY
    BEGIN CATCH
        SET @O_CategorizationPathCategory =
            CONCAT(@O_CategorizationPathCategory,
                   '|CategoryExpression|CATCH|ErrNo=',ERROR_NUMBER(),
                   '|Line=',ERROR_LINE(),
                   '|Msg=',ERROR_MESSAGE());
        RETURN;
    END CATCH
END;
GO
