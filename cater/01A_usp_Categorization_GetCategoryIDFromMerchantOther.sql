
SET NOCOUNT ON;
GO
/*==================================================================================================
SP: usp_Categorization_GetCategoryIDFromMerchantOther
Purpose:
- Resolve CategoryID for non-merchant style transactions using MerchantOtherType + MerchantOther
- Uses MerchantOtherType.IsCategoryApplicable to decide whether to apply CategoryID
- Supports self-heal: if code exists in input but MerchantOther row missing, insert shell row (CategoryID NULL)
==================================================================================================*/
CREATE OR ALTER PROCEDURE dbo.usp_Categorization_GetCategoryIDFromMerchantOther
(
      @I_TenantCode                         VARCHAR(50)
    , @I_TenantISOCountryCode               CHAR(2)
    , @I_LineOfBusinessName                 VARCHAR(128)

    , @I_TransactionISOCountryCode          CHAR(2)         = NULL

    -- Bank / EBILL / Custom inputs
    , @I_CounterPartyBankCode               VARCHAR(128)    = NULL
    , @I_CounterPartyBankName               VARCHAR(128)    = NULL
    , @I_EbillServiceID                     VARCHAR(20)     = NULL
    , @I_TransactionNarration               VARCHAR(256)    = NULL

    -- Control
    , @I_IsHealingMode                      CHAR(1)         = 'Y'
    , @I_UserID                             VARCHAR(20)
    , @I_IsBulkUpdate                       CHAR(1)         = 'N'

    -- Debug path accumulators (IN)
    , @I_CategorizationPathMerchant         NVARCHAR(MAX)   = NULL
    , @I_CategorizationPathCategory         NVARCHAR(MAX)   = NULL

    -- Outputs
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
        , @V_OtherISOCountryCode CHAR(2)
        , @V_OtherTypeCode VARCHAR(50)
        , @V_OtherTypeID BIGINT
        , @V_IsCategoryApplicable CHAR(1)
        , @V_OtherCode VARCHAR(128)
        , @V_OtherNameEN VARCHAR(128);

    SET @O_CategoryID = NULL;
    SET @O_MerchantOtherID = NULL;

    SET @O_CategorizationPathMerchant = @I_CategorizationPathMerchant;
    SET @O_CategorizationPathCategory = @I_CategorizationPathCategory;

    SET @V_OtherISOCountryCode = COALESCE(NULLIF(@I_TransactionISOCountryCode,''), NULLIF(@I_TenantISOCountryCode,''), 'KW');

    SELECT @V_TenantID = t.TenantID
    FROM InMem.Tenant t WITH (NOLOCK)
    WHERE t.TenantCode=@I_TenantCode
      AND t.TennantISOCountryCode=@I_TenantISOCountryCode
      AND t.IsActive='Y';

    /* Decide MerchantOtherTypeCode and MerchantOtherCode (based on available values) */
    IF NULLIF(LTRIM(RTRIM(@I_EbillServiceID)),'') IS NOT NULL
    BEGIN
        SET @V_OtherTypeCode = 'EBILL';
        SET @V_OtherCode = @I_EbillServiceID;
        SET @V_OtherNameEN = NULL;
    END
    ELSE IF NULLIF(LTRIM(RTRIM(@I_CounterPartyBankCode)),'') IS NOT NULL
    BEGIN
        SET @V_OtherTypeCode = 'BANK';
        SET @V_OtherCode = @I_CounterPartyBankCode;
        SET @V_OtherNameEN = @I_CounterPartyBankName;
    END
    ELSE
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendCategory
              @O_CategorizationPathCategory
            , N'SP01A|SkipMerchantOther'
            , NULL
            , 'N'
            , NULL
            , N'Reason=No EBILL/BankCode present'
            , 'N'
            , @O_CategorizationPathCategory OUTPUT;
        RETURN 0;
    END

    /* Resolve OtherTypeID + IsCategoryApplicable */
    SELECT TOP (1)
          @V_OtherTypeID = mot.MerchatOtherTypeID
        , @V_IsCategoryApplicable = mot.IsCategoryApplicable
    FROM InMem.MerchatOtherType mot WITH (NOLOCK)
    WHERE mot.MerchatOtherTypeCode = @V_OtherTypeCode
      AND mot.IsActive='Y';

    IF @V_OtherTypeID IS NULL
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendCategory
              @O_CategorizationPathCategory
            , N'SP01A|OtherTypeNotFound'
            , @V_OtherTypeCode
            , 'N'
            , NULL
            , N'Reason=MerchatOtherType not configured'
            , 'N'
            , @O_CategorizationPathCategory OUTPUT;
        RETURN 0;
    END

    IF COALESCE(@V_IsCategoryApplicable,'N') <> 'Y'
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendCategory
              @O_CategorizationPathCategory
            , N'SP01A|OtherTypeNoCategory'
            , CONCAT(@V_OtherTypeCode,'|',@V_OtherCode)
            , 'N'
            , NULL
            , N'Reason=IsCategoryApplicable=N'
            , 'N'
            , @O_CategorizationPathCategory OUTPUT;
        RETURN 0;
    END

    /* Lookup MerchantOther */
    SELECT TOP (1)
          @O_MerchantOtherID = mo.MerchatOtherID
        , @O_CategoryID = mo.CategoryID
    FROM InMem.MerchatOther mo WITH (NOLOCK)
    WHERE mo.TennantID = @V_TenantID
      AND mo.MerchatOtherISOCountryCode = @V_OtherISOCountryCode
      AND mo.MerchatOtherTypeID = @V_OtherTypeID
      AND mo.MerchatOtherCode = @V_OtherCode;

    IF @O_MerchantOtherID IS NULL AND @I_IsHealingMode='Y'
    BEGIN
        /* Self-heal: create shell row so Ops can later map CategoryID */
        INSERT INTO InMem.MerchatOther
        (
              TennantID
            , MerchatOtherISOCountryCode
            , MerchatOtherTypeID
            , MerchatOtherCode
            , MerchatOtherNameEN
            , MerchatOtherNameAR
            , SubMerchatOtherNameEN
            , SubMerchatOtherNameAR
            , BrandID
            , CategoryID
            , IsSelfHealed
            , IsActive
            , UserNote
            , CreateUserID
            , CreateDatetime
            , UpdateUserID
            , UpdateDatetime
        )
        SELECT
              @V_TenantID
            , @V_OtherISOCountryCode
            , @V_OtherTypeID
            , @V_OtherCode
            , @V_OtherNameEN
            , NULL
            , NULL
            , NULL
            , NULL
            , NULL
            , 'Y'
            , 'Y'
            , CONCAT('Self-healed by categorization for type ',@V_OtherTypeCode)
            , @I_UserID
            , GETDATE()
            , @I_UserID
            , GETDATE();

        SET @O_MerchantOtherID = SCOPE_IDENTITY();

        EXEC dbo.usp_Categorization_PathAppendCategory
              @O_CategorizationPathCategory
            , N'SP01A|HealMerchantOther'
            , CONCAT(@V_OtherTypeCode,'|',@V_OtherISOCountryCode,'|',@V_OtherCode)
            , 'N'
            , NULL
            , N'Reason=Inserted shell row (CategoryID NULL)'
            , 'Y'
            , @O_CategorizationPathCategory OUTPUT;

        RETURN 0;
    END


    /* Brand override when MerchantOther.CategoryID is NULL */
    IF @O_MerchantOtherID IS NOT NULL AND @O_CategoryID IS NULL
    BEGIN
        DECLARE @V_BrandID BIGINT, @V_BrandCategoryID BIGINT, @V_BrandTypeID BIGINT, @V_IsBrandTypeCategoryApplicable CHAR(1);

        SELECT TOP (1)
              @V_BrandID = mo.BrandID
        FROM InMem.MerchatOther mo WITH (NOLOCK)
        WHERE mo.MerchatOtherID = @O_MerchantOtherID;

        IF @V_BrandID IS NOT NULL
        BEGIN
            SELECT TOP (1)
                  @V_BrandCategoryID = b.CategoryID
                , @V_BrandTypeID = b.BrandTypeID
            FROM InMem.Brand b WITH (NOLOCK)
            WHERE b.TennantID=@V_TenantID
              AND b.BrandID=@V_BrandID
              AND b.IsActive='Y';

            /* Validate BrandType IsCategoryApplicable (optional gate) */
            SELECT TOP (1) @V_IsBrandTypeCategoryApplicable = bt.IsCategoryApplicable
            FROM InMem.BrandType bt WITH (NOLOCK)
            WHERE bt.BrandTypeID = @V_BrandTypeID
              AND bt.IsActive='Y';

            IF COALESCE(@V_IsBrandTypeCategoryApplicable,'Y') <> 'Y'
            BEGIN
                EXEC dbo.usp_Categorization_PathAppendCategory
                      @O_CategorizationPathCategory
                    , N'SP01A|BrandTypeNoCategory'
                    , CONCAT(N'BrandID=',@V_BrandID)
                    , 'N'
                    , NULL
                    , N'Reason=BrandType.IsCategoryApplicable=N'
                    , 'N'
                    , @O_CategorizationPathCategory OUTPUT;
            END
            ELSE IF @V_BrandCategoryID IS NOT NULL
            BEGIN
                SET @O_CategoryID = @V_BrandCategoryID;

                EXEC dbo.usp_Categorization_PathAppendCategory
                      @O_CategorizationPathCategory
                    , N'SP01A|HitBrand'
                    , CONCAT(N'BrandID=',@V_BrandID)
                    , 'Y'
                    , @O_CategoryID
                    , N'From=Brand.CategoryID (fallback)'
                    , 'N'
                    , @O_CategorizationPathCategory OUTPUT;

                RETURN 0;
            END
            ELSE
            BEGIN
                EXEC dbo.usp_Categorization_PathAppendCategory
                      @O_CategorizationPathCategory
                    , N'SP01A|BrandNoCategory'
                    , CONCAT(N'BrandID=',@V_BrandID)
                    , 'N'
                    , NULL
                    , N'Reason=Brand.CategoryID NULL'
                    , 'N'
                    , @O_CategorizationPathCategory OUTPUT;
            END
        END
    END

    IF @O_CategoryID IS NOT NULL
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendCategory
              @O_CategorizationPathCategory
            , N'SP01A|HitMerchantOther'
            , CONCAT(@V_OtherTypeCode,'|',@V_OtherISOCountryCode,'|',@V_OtherCode)
            , 'Y'
            , @O_CategoryID
            , N'From=MerchatOther.CategoryID'
            , 'N'
            , @O_CategorizationPathCategory OUTPUT;

        RETURN 0;
    END

    EXEC dbo.usp_Categorization_PathAppendCategory
          @O_CategorizationPathCategory
        , N'SP01A|MerchantOtherNoCategory'
        , CONCAT(@V_OtherTypeCode,'|',@V_OtherISOCountryCode,'|',@V_OtherCode)
        , 'N'
        , NULL
        , N'Reason=Row exists but CategoryID NULL'
        , 'N'
        , @O_CategorizationPathCategory OUTPUT;

    RETURN 0;
END
GO
