SET NOCOUNT ON;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Categorization_GetCategoryIDFromMerchant
(

      @I_TenantCode                         VARCHAR(50)
    , @I_TenantISOCountryCode               CHAR(2)
    , @I_LineOfBusinessName                 VARCHAR(128)

    -- Merchant Parameters
    , @I_IsLocalMerchant                    CHAR(1)         = NULL
    , @I_MerchantCode                       VARCHAR(20)     = NULL
    , @I_TransactionISOCountryCode          CHAR(2)         = NULL
    , @I_MerchantNameEN                     VARCHAR(128)    = NULL
    , @I_MerchantNameAR                     NVARCHAR(256)   = NULL
    , @I_SubMerchantNameEN                  VARCHAR(128)    = NULL
    , @I_SubMerchantNameAR                  NVARCHAR(256)   = NULL

    -- Merchant Category (MCC) Parameters
    , @I_MerchantCategoryCode               VARCHAR(128)    = NULL
    , @I_MerchantCategoryNameEN             VARCHAR(128)    = NULL

    -- Transaction Type Parameters
    , @I_TransactionTypeCode                VARCHAR(128)    = NULL
    , @I_TransactionTypeNameEN              VARCHAR(128)    = NULL
    , @I_TransactionTypeNameAR              NVARCHAR(256)   = NULL

    -- Counter Party Parameters
    , @I_CounterPartyAccountID              VARCHAR(128)    = NULL
    , @I_CounterPartyBankCode               VARCHAR(128)    = NULL
    , @I_CounterPartyBankName               VARCHAR(128)    = NULL
    , @I_TransactionCounterPartyISOCountryCode VARCHAR(128) = NULL

    -- Transaction Parameters
    , @I_IsMerchantTransaction              CHAR(1)         = NULL
    , @I_CreditDebitIndicator               CHAR(1)         = NULL  /* 'C'/'D' optional; derive if NULL */
    , @I_PromoCode                          CHAR(2)         = NULL
    , @I_FirmNumber                         VARCHAR(20)     = NULL
    , @I_TransactionNarration               VARCHAR(256)    = NULL
    , @I_TransactionNumber                  VARCHAR(16)     = NULL
    , @I_TxnProfile                         VARCHAR(128)    = NULL
    , @I_EbillServiceID                     VARCHAR(20)     = NULL
    , @I_TransactionAmount                  DECIMAL(21,3)   = NULL

    -- Control
    , @I_IsHealingMode                      CHAR(1)         = 'Y'

    -- Logging Parameters
    , @I_UserID                             VARCHAR(20)
    , @I_IsBulkUpdate                       CHAR(1)         = 'N'
    , @I_ThreadID                           TINYINT         = 1
    , @I_Batch                              INT             = 500

    -- Debug path accumulators (IN)
    , @I_CategorizationPathMerchant         NVARCHAR(MAX)   = NULL
    , @I_CategorizationPathCategory         NVARCHAR(MAX)   = NULL


    , @O_MerchantID                         BIGINT          OUTPUT
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
        , @V_MerchantISOCountry CHAR(2)
        , @V_MerchantCode VARCHAR(20)
        , @V_BrandID BIGINT
        , @V_BrandCategoryID BIGINT
        , @V_MccCategoryID BIGINT;

    SET @O_CategoryID = NULL;
    SET @O_MerchantID = NULL;
    SET @O_MerchantOtherID = NULL;
    SET @O_CategorizationPathMerchant = @I_CategorizationPathMerchant;
    SET @O_CategorizationPathCategory = @I_CategorizationPathCategory;

    SELECT @V_TenantID = t.TenantID
    FROM InMem.Tenant t WITH (NOLOCK)
    WHERE t.TenantCode=@I_TenantCode
      AND t.TennantISOCountryCode=@I_TenantISOCountryCode
      AND t.IsActive='Y';

    SET @V_MerchantISOCountry = COALESCE(NULLIF(@I_TransactionISOCountryCode,''), NULLIF(@I_TenantISOCountryCode,''), 'KW');
    SET @V_MerchantCode = NULLIF(LTRIM(RTRIM(@I_MerchantCode)),'');

    IF @V_MerchantCode IS NULL
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendMerchant @O_CategorizationPathMerchant, N'SP02|Skip', NULL, 'N', NULL, N'Reason=MerchantCode NULL', 'N', @O_CategorizationPathMerchant OUTPUT;
        RETURN 0;
    END

    SELECT TOP (1)
          @O_MerchantID = m.MerchantID
        , @O_CategoryID = m.CategoryID
        , @V_BrandID    = m.BrandID
    FROM InMem.Merchant m WITH (NOLOCK)
    WHERE m.TennantID=@V_TenantID
      AND m.MerchantISOCountryCode=@V_MerchantISOCountry
      AND m.MerchantCode=@V_MerchantCode;

    IF @O_CategoryID IS NOT NULL
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendMerchant @O_CategorizationPathMerchant, N'SP02|HitMerchant', CONCAT(@V_MerchantISOCountry,'|',@V_MerchantCode), 'Y', @O_CategoryID, N'From=Merchant.CategoryID', 'N', @O_CategorizationPathMerchant OUTPUT;
        RETURN 0;
    END

    EXEC dbo.usp_Categorization_PathAppendMerchant @O_CategorizationPathMerchant, N'SP02|MerchantNoCategory', CONCAT(@V_MerchantISOCountry,'|',@V_MerchantCode), 'N', NULL, N'Reason=Merchant exists but CategoryID NULL', 'N', @O_CategorizationPathMerchant OUTPUT;

    IF @V_BrandID IS NOT NULL
    BEGIN
        SELECT TOP (1)
              @V_BrandCategoryID = b.CategoryID
            , @V_BrandTypeID = b.BrandTypeID
        FROM InMem.Brand b WITH (NOLOCK)
        WHERE b.TennantID=@V_TenantID AND b.BrandID=@V_BrandID;

        DECLARE @V_IsBrandTypeCategoryApplicable CHAR(1);
        SELECT TOP (1) @V_IsBrandTypeCategoryApplicable = bt.IsCategoryApplicable
        FROM InMem.BrandType bt WITH (NOLOCK)
        WHERE bt.BrandTypeID=@V_BrandTypeID AND bt.IsActive='Y';

        IF COALESCE(@V_IsBrandTypeCategoryApplicable,'Y') <> 'Y'
        BEGIN
            EXEC dbo.usp_Categorization_PathAppendMerchant @O_CategorizationPathMerchant, N'SP02|BrandTypeNoCategory', CONCAT(N'BrandID=',@V_BrandID), 'N', NULL, N'Reason=BrandType.IsCategoryApplicable=N', 'N', @O_CategorizationPathMerchant OUTPUT;
            RETURN 0;
        END


        IF @V_BrandCategoryID IS NOT NULL
        BEGIN
            SET @O_CategoryID=@V_BrandCategoryID;
            EXEC dbo.usp_Categorization_PathAppendMerchant @O_CategorizationPathMerchant, N'SP02|HitBrand', CONCAT(N'BrandID=',@V_BrandID), 'Y', @O_CategoryID, N'From=Brand.CategoryID', 'N', @O_CategorizationPathMerchant OUTPUT;
            RETURN 0;
        END
        EXEC dbo.usp_Categorization_PathAppendMerchant @O_CategorizationPathMerchant, N'SP02|BrandNoCategory', CONCAT(N'BrandID=',@V_BrandID), 'N', NULL, N'Reason=Brand CategoryID NULL', 'N', @O_CategorizationPathMerchant OUTPUT;
    END

    IF NULLIF(LTRIM(RTRIM(@I_MerchantCategoryCode)),'') IS NOT NULL
    BEGIN
        SELECT TOP (1) @V_MccCategoryID = cmc.CategoryID
        FROM InMem.CategoryMerchantCategory cmc WITH (NOLOCK)
        WHERE cmc.TennantID=@V_TenantID AND cmc.MerchantCategoryCode=@I_MerchantCategoryCode;

        IF @V_MccCategoryID IS NOT NULL
        BEGIN
            SET @O_CategoryID=@V_MccCategoryID;
            EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP02|HitMCC', @I_MerchantCategoryCode, 'Y', @O_CategoryID, N'From=CategoryMerchantCategory.CategoryID', 'N', @O_CategorizationPathCategory OUTPUT;
            RETURN 0;
        END

        EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP02|MCCNoCategory', @I_MerchantCategoryCode, 'N', NULL, N'Reason=MCC CategoryID NULL / not found', 'N', @O_CategorizationPathCategory OUTPUT;
    END

    RETURN 0;
END
GO
