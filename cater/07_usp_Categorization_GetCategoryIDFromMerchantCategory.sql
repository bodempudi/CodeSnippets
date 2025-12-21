
SET NOCOUNT ON;
GO
/*==================================================================================================
SP: usp_Categorization_GetCategoryIDFromMerchantCategory (MCC)
Priority:
- VERY LAST for merchant transactions (right before DefaultCategoryParameter) as per team guidance.
- MCC is heuristic; used only when Merchant/Brand/Expressions fail.

Self-heal:
- If MerchatCategoryCode is present but no row exists, insert shell row with CategoryID NULL and IsSelfHealed='Y'.
==================================================================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Categorization_GetCategoryIDFromMerchantCategory
(
      @I_TenantCode                         VARCHAR(50)
    , @I_TenantISOCountryCode               CHAR(2)
    , @I_LineOfBusinessName                 VARCHAR(128)

    , @I_MerchatCategoryCode                VARCHAR(128)    = NULL
    , @I_MerchatCategoryNameEN              VARCHAR(128)    = NULL
    , @I_IsMerchantTransaction              CHAR(1)         = NULL
    , @I_TransactionAmount                  DECIMAL(21,3)   = NULL

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
        , @V_MCC VARCHAR(128)
        , @V_IsMerchantTx CHAR(1);

    SET @O_CategoryID = NULL;
    SET @O_CategorizationPathMerchant = @I_CategorizationPathMerchant;
    SET @O_CategorizationPathCategory = @I_CategorizationPathCategory;

    SET @V_MCC = NULLIF(LTRIM(RTRIM(@I_MerchatCategoryCode)),'');
    SET @V_IsMerchantTx = COALESCE(NULLIF(@I_IsMerchantTransaction,''), CASE WHEN @V_MCC IS NOT NULL THEN 'Y' ELSE 'N' END);

    IF @V_MCC IS NULL
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP07|Skip', NULL, 'N', NULL, N'Reason=MCC NULL', 'N', @O_CategorizationPathCategory OUTPUT;
        RETURN 0;
    END

    IF @V_IsMerchantTx <> 'Y'
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP07|Skip', @V_MCC, 'N', NULL, N'Reason=Non-merchant tx', 'N', @O_CategorizationPathCategory OUTPUT;
        RETURN 0;
    END

    SELECT @V_TenantID = t.TenantID
    FROM InMem.Tenant t WITH (NOLOCK)
    WHERE t.TenantCode=@I_TenantCode
      AND t.TennantISOCountryCode=@I_TenantISOCountryCode
      AND t.IsActive='Y';

    SELECT TOP (1) @O_CategoryID = cmc.CategoryID
    FROM InMem.CategoryMerchantCategory cmc WITH (NOLOCK)
    WHERE cmc.TennantID=@V_TenantID
      AND cmc.MerchatCategoryCode=@V_MCC
      AND cmc.IsActive='Y';

    IF @O_CategoryID IS NOT NULL
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP07|HitMCC', @V_MCC, 'Y', @O_CategoryID, N'From=CategoryMerchantCategory.CategoryID', 'N', @O_CategorizationPathCategory OUTPUT;
        RETURN 0;
    END

    IF @I_IsHealingMode='Y'
    BEGIN
        INSERT INTO InMem.CategoryMerchantCategory
        (
              TennantID
            , MerchatCategoryCode
            , MerchatCategoryNameEN
            , CategoryID
            , IsActive
            , IsSelfHealed
            , IsFinancialInstitution
            , UserNote
            , CreateUserID
            , CreateDatetime
            , UpdateUserID
            , UpdateDatetime
        )
        SELECT
              @V_TenantID
            , @V_MCC
            , NULLIF(@I_MerchatCategoryNameEN,'')
            , NULL
            , 'Y'
            , 'Y'
            , 'N'
            , N'Self-healed by categorization (MCC shell)'
            , @I_UserID
            , GETDATE()
            , @I_UserID
            , GETDATE();

        EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP07|HealMCC', @V_MCC, 'N', NULL, N'Reason=Inserted shell row (CategoryID NULL)', 'Y', @O_CategorizationPathCategory OUTPUT;
        RETURN 0;
    END

    EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP07|NoMatch', @V_MCC, 'N', NULL, N'Reason=Not mapped', 'N', @O_CategorizationPathCategory OUTPUT;
    RETURN 0;
END
GO
