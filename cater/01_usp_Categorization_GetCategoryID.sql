SET NOCOUNT ON;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Categorization_GetCategoryID
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

    , @O_CategorizationStartTime            DATETIME        OUTPUT
    , @O_MerchantID                         BIGINT          OUTPUT
    , @O_MerchantOtherID                    BIGINT          OUTPUT
    , @O_CategoryID                         BIGINT          OUTPUT
    , @O_CategorizationPathMerchant         NVARCHAR(MAX)   OUTPUT
    , @O_CategorizationPathCategory         NVARCHAR(MAX)   OUTPUT
    , @O_IsDefaultCategory                  CHAR(1)         OUTPUT
    , @O_CategorizationEndTime              DATETIME        OUTPUT
    , @O_ResultJson                         NVARCHAR(MAX)   OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
          @V_TenantID BIGINT
        , @V_LineOfBusinessID BIGINT
        , @V_DefaultCategoryID BIGINT
        , @V_IsMerchantTx CHAR(1)
        , @V_MerchantISOCountry CHAR(2)
        , @V_PathM NVARCHAR(MAX)
        , @V_PathC NVARCHAR(MAX)
        , @V_TempCat BIGINT
        , @V_CDI CHAR(1);

    SET @O_CategorizationStartTime = GETDATE();
    SET @O_CategorizationEndTime = NULL;

    SET @O_CategoryID = NULL;
    SET @O_MerchantID = NULL;
    SET @O_MerchantOtherID = NULL;
    SET @O_IsDefaultCategory = 'N';

    SET @V_PathM = @I_CategorizationPathMerchant;
    SET @V_PathC = @I_CategorizationPathCategory;

    SET @V_MerchantISOCountry = COALESCE(NULLIF(@I_TransactionISOCountryCode,''), NULLIF(@I_TenantISOCountryCode,''), 'KW');
    SET @V_IsMerchantTx = COALESCE(NULLIF(@I_IsMerchantTransaction,''), CASE WHEN NULLIF(LTRIM(RTRIM(@I_MerchantCode)),'') IS NOT NULL THEN 'Y' ELSE 'N' END);

    SET @V_CDI = NULLIF(@I_CreditDebitIndicator,'');
    IF @V_CDI IS NULL AND @I_TransactionAmount IS NOT NULL
        SET @V_CDI = CASE WHEN @I_TransactionAmount < 0 THEN 'D' ELSE 'C' END;

    SELECT @V_TenantID = t.TenantID
    FROM InMem.Tenant t WITH (NOLOCK)
    WHERE t.TenantCode = @I_TenantCode
      AND t.TennantISOCountryCode = @I_TenantISOCountryCode
      AND t.IsActive = 'Y';

    SELECT @V_LineOfBusinessID = lob.LineOfBusinessID
    FROM InMem.LineOfBusiness lob WITH (NOLOCK)
    WHERE lob.TennantID = @V_TenantID
      AND lob.LineOfBusinessName = @I_LineOfBusinessName;

    SELECT TOP (1) @V_DefaultCategoryID = dcp.CategoryID
    FROM InMem.DefaultCategoryParameter dcp WITH (NOLOCK)
    WHERE dcp.TennantID = @V_TenantID
      AND dcp.LineOfBusinessID = @V_LineOfBusinessID
      AND (dcp.CreditDebitIndicator = @V_CDI OR dcp.CreditDebitIndicator IS NULL)
    ORDER BY dcp.DefaultCategoryParameterID DESC;

    BEGIN TRY
        EXEC dbo.usp_Categorization_PathAppendMerchant
              @V_PathM
            , N'SP01|Start'
            , CONCAT(@I_TenantCode,'|',@I_TenantISOCountryCode,'|',@I_LineOfBusinessName)
            , 'N', NULL
            , CONCAT(N'Reason=Begin|CDI=',COALESCE(@V_CDI,'NULL'),N'|IsMerchantTx=',@V_IsMerchantTx)
            , 'N'
            , @V_PathM OUTPUT;

        EXEC dbo.usp_Categorization_SelfHeal_Entities
              @I_TenantCode=@I_TenantCode
            , @I_TenantISOCountryCode=@I_TenantISOCountryCode
            , @I_LineOfBusinessName=@I_LineOfBusinessName
            , @I_IsLocalMerchant=@I_IsLocalMerchant
            , @I_MerchantCode=@I_MerchantCode
            , @I_TransactionISOCountryCode=@I_TransactionISOCountryCode
            , @I_MerchantNameEN=@I_MerchantNameEN
            , @I_MerchantNameAR=@I_MerchantNameAR
            , @I_SubMerchantNameEN=@I_SubMerchantNameEN
            , @I_SubMerchantNameAR=@I_SubMerchantNameAR
            , @I_MerchantCategoryCode=@I_MerchantCategoryCode
            , @I_MerchantCategoryNameEN=@I_MerchantCategoryNameEN
            , @I_TransactionTypeCode=@I_TransactionTypeCode
            , @I_TransactionTypeNameEN=@I_TransactionTypeNameEN
            , @I_TransactionTypeNameAR=@I_TransactionTypeNameAR
            , @I_CounterPartyAccountID=@I_CounterPartyAccountID
            , @I_CounterPartyBankCode=@I_CounterPartyBankCode
            , @I_CounterPartyBankName=@I_CounterPartyBankName
            , @I_TransactionCounterPartyISOCountryCode=@I_TransactionCounterPartyISOCountryCode
            , @I_IsMerchantTransaction=@I_IsMerchantTransaction
            , @I_CreditDebitIndicator=@I_CreditDebitIndicator
            , @I_PromoCode=@I_PromoCode
            , @I_FirmNumber=@I_FirmNumber
            , @I_TransactionNarration=@I_TransactionNarration
            , @I_TransactionNumber=@I_TransactionNumber
            , @I_TxnProfile=@I_TxnProfile
            , @I_EbillServiceID=@I_EbillServiceID
            , @I_TransactionAmount=@I_TransactionAmount
            , @I_IsHealingMode=@I_IsHealingMode
            , @I_UserID=@I_UserID
            , @I_IsBulkUpdate=@I_IsBulkUpdate
            , @I_ThreadID=@I_ThreadID
            , @I_Batch=@I_Batch
            , @I_CategorizationPathMerchant=@V_PathM
            , @I_CategorizationPathCategory=@V_PathC
            , @O_MerchantID=@O_MerchantID OUTPUT
            , @O_MerchantOtherID=@O_MerchantOtherID OUTPUT
            , @O_CategoryID=@V_TempCat OUTPUT
            , @O_CategorizationPathMerchant=@V_PathM OUTPUT
            , @O_CategorizationPathCategory=@V_PathC OUTPUT;


        
        /* SP04 PRE CategoryExpression */
        EXEC dbo.usp_Categorization_GetCategoryIDFromCategoryExpression
              @I_ExecutionTypeCodePhase='PRE'
            , @I_TenantCode=@I_TenantCode
            , @I_TenantISOCountryCode=@I_TenantISOCountryCode
            , @I_LineOfBusinessName=@I_LineOfBusinessName
            , @I_TransactionTypeCode=@I_TransactionTypeCode
            , @I_TransactionTypeNameEN=@I_TransactionTypeNameEN
            , @I_TransactionTypeNameAR=@I_TransactionTypeNameAR
            , @I_TransactionNarration=@I_TransactionNarration
            , @I_IsHealingMode=@I_IsHealingMode
            , @I_UserID=@I_UserID
            , @I_CategorizationPathMerchant=@V_PathM
            , @I_CategorizationPathCategory=@V_PathC
            , @O_CategoryID=@V_TempCat OUTPUT
            , @O_CategorizationPathMerchant=@V_PathM OUTPUT
            , @O_CategorizationPathCategory=@V_PathC OUTPUT;

        IF @V_TempCat IS NOT NULL
        BEGIN
            SET @O_CategoryID=@V_TempCat;
        END

/* SP01A MerchantOther (EBILL/BANK/CUSTOM style) */
        EXEC dbo.usp_Categorization_GetCategoryIDFromMerchantOther
              @I_TenantCode=@I_TenantCode
            , @I_TenantISOCountryCode=@I_TenantISOCountryCode
            , @I_LineOfBusinessName=@I_LineOfBusinessName
            , @I_TransactionISOCountryCode=@I_TransactionISOCountryCode
            , @I_CounterPartyBankCode=@I_CounterPartyBankCode
            , @I_CounterPartyBankName=@I_CounterPartyBankName
            , @I_EbillServiceID=@I_EbillServiceID
            , @I_TransactionTypeCode=@I_TransactionTypeCode
            , @I_TransactionTypeNameEN=@I_TransactionTypeNameEN
            , @I_TransactionTypeNameAR=@I_TransactionTypeNameAR
            , @I_TransactionNarration=@I_TransactionNarration
            , @I_IsHealingMode=@I_IsHealingMode
            , @I_UserID=@I_UserID
            , @I_IsBulkUpdate=@I_IsBulkUpdate
            , @I_CategorizationPathMerchant=@V_PathM
            , @I_CategorizationPathCategory=@V_PathC
            , @O_MerchantOtherID=@O_MerchantOtherID OUTPUT
            , @O_CategoryID=@V_TempCat OUTPUT
            , @O_CategorizationPathMerchant=@V_PathM OUTPUT
            , @O_CategorizationPathCategory=@V_PathC OUTPUT;

        IF @V_TempCat IS NOT NULL
        BEGIN
            SET @O_CategoryID=@V_TempCat;
            GOTO Finalize;
        END

        EXEC dbo.usp_Categorization_GetCategoryIDFromMerchant
              @I_TenantCode=@I_TenantCode
            , @I_TenantISOCountryCode=@I_TenantISOCountryCode
            , @I_LineOfBusinessName=@I_LineOfBusinessName
            , @I_IsLocalMerchant=@I_IsLocalMerchant
            , @I_MerchantCode=@I_MerchantCode
            , @I_TransactionISOCountryCode=@I_TransactionISOCountryCode
            , @I_MerchantNameEN=@I_MerchantNameEN
            , @I_MerchantNameAR=@I_MerchantNameAR
            , @I_SubMerchantNameEN=@I_SubMerchantNameEN
            , @I_SubMerchantNameAR=@I_SubMerchantNameAR
            , @I_MerchantCategoryCode=@I_MerchantCategoryCode
            , @I_MerchantCategoryNameEN=@I_MerchantCategoryNameEN
            , @I_TransactionTypeCode=@I_TransactionTypeCode
            , @I_TransactionTypeNameEN=@I_TransactionTypeNameEN
            , @I_TransactionTypeNameAR=@I_TransactionTypeNameAR
            , @I_CounterPartyAccountID=@I_CounterPartyAccountID
            , @I_CounterPartyBankCode=@I_CounterPartyBankCode
            , @I_CounterPartyBankName=@I_CounterPartyBankName
            , @I_TransactionCounterPartyISOCountryCode=@I_TransactionCounterPartyISOCountryCode
            , @I_IsMerchantTransaction=@I_IsMerchantTransaction
            , @I_CreditDebitIndicator=@I_CreditDebitIndicator
            , @I_PromoCode=@I_PromoCode
            , @I_FirmNumber=@I_FirmNumber
            , @I_TransactionNarration=@I_TransactionNarration
            , @I_TransactionNumber=@I_TransactionNumber
            , @I_TxnProfile=@I_TxnProfile
            , @I_EbillServiceID=@I_EbillServiceID
            , @I_TransactionAmount=@I_TransactionAmount
            , @I_IsHealingMode=@I_IsHealingMode
            , @I_UserID=@I_UserID
            , @I_IsBulkUpdate=@I_IsBulkUpdate
            , @I_ThreadID=@I_ThreadID
            , @I_Batch=@I_Batch
            , @I_CategorizationPathMerchant=@V_PathM
            , @I_CategorizationPathCategory=@V_PathC
            , @O_MerchantID=@O_MerchantID OUTPUT
            , @O_MerchantOtherID=@O_MerchantOtherID OUTPUT
            , @O_CategoryID=@V_TempCat OUTPUT
            , @O_CategorizationPathMerchant=@V_PathM OUTPUT
            , @O_CategorizationPathCategory=@V_PathC OUTPUT;

        IF @V_TempCat IS NOT NULL
        BEGIN
            SET @O_CategoryID=@V_TempCat;
            GOTO Finalize;
        END

        IF @V_IsMerchantTx='Y'
        BEGIN
    
        /* SP01A MerchantOther (EBILL/BANK/CUSTOM style) */
        EXEC dbo.usp_Categorization_GetCategoryIDFromMerchantOther
              @I_TenantCode=@I_TenantCode
            , @I_TenantISOCountryCode=@I_TenantISOCountryCode
            , @I_LineOfBusinessName=@I_LineOfBusinessName
            , @I_TransactionISOCountryCode=@I_TransactionISOCountryCode
            , @I_CounterPartyBankCode=@I_CounterPartyBankCode
            , @I_CounterPartyBankName=@I_CounterPartyBankName
            , @I_EbillServiceID=@I_EbillServiceID
            , @I_TransactionTypeCode=@I_TransactionTypeCode
            , @I_TransactionTypeNameEN=@I_TransactionTypeNameEN
            , @I_TransactionTypeNameAR=@I_TransactionTypeNameAR
            , @I_TransactionNarration=@I_TransactionNarration
            , @I_IsHealingMode=@I_IsHealingMode
            , @I_UserID=@I_UserID
            , @I_IsBulkUpdate=@I_IsBulkUpdate
            , @I_CategorizationPathMerchant=@V_PathM
            , @I_CategorizationPathCategory=@V_PathC
            , @O_MerchantOtherID=@O_MerchantOtherID OUTPUT
            , @O_CategoryID=@V_TempCat OUTPUT
            , @O_CategorizationPathMerchant=@V_PathM OUTPUT
            , @O_CategorizationPathCategory=@V_PathC OUTPUT;

        IF @V_TempCat IS NOT NULL
        BEGIN
            SET @O_CategoryID=@V_TempCat;
            GOTO Finalize;
        END

        EXEC dbo.usp_Categorization_GetCategoryIDFromMerchantExpression
              @I_TenantCode=@I_TenantCode
            , @I_TenantISOCountryCode=@I_TenantISOCountryCode
            , @I_LineOfBusinessName=@I_LineOfBusinessName
            , @I_TransactionNarration=@I_TransactionNarration
            , @I_MerchantNameEN=@I_MerchantNameEN
            , @I_SubMerchantNameEN=@I_SubMerchantNameEN
            , @I_IsHealingMode=@I_IsHealingMode
            , @I_UserID=@I_UserID
            , @I_CategorizationPathMerchant=@V_PathM
            , @I_CategorizationPathCategory=@V_PathC
            , @O_MerchantOtherID=@O_MerchantOtherID OUTPUT
            , @O_CategoryID=@V_TempCat OUTPUT
            , @O_CategorizationPathMerchant=@V_PathM OUTPUT
            , @O_CategorizationPathCategory=@V_PathC OUTPUT;

        IF @V_TempCat IS NOT NULL
        BEGIN
            SET @O_CategoryID=@V_TempCat;
            GOTO Finalize;
        END
        END
        ELSE
        BEGIN
            EXEC dbo.usp_Categorization_PathAppendMerchant @V_PathM, N'SP01|SkipSP03', NULL, 'N', NULL, N'Reason=Non-merchant', 'N', @V_PathM OUTPUT;
        END

        EXEC dbo.usp_Categorization_GetCategoryIDFromCategoryExpression
              @I_TenantCode=@I_TenantCode
            , @I_TenantISOCountryCode=@I_TenantISOCountryCode
            , @I_LineOfBusinessName=@I_LineOfBusinessName
            , @I_IsLocalMerchant=@I_IsLocalMerchant
            , @I_MerchantCode=@I_MerchantCode
            , @I_TransactionISOCountryCode=@I_TransactionISOCountryCode
            , @I_MerchantNameEN=@I_MerchantNameEN
            , @I_MerchantNameAR=@I_MerchantNameAR
            , @I_SubMerchantNameEN=@I_SubMerchantNameEN
            , @I_SubMerchantNameAR=@I_SubMerchantNameAR
            , @I_MerchantCategoryCode=@I_MerchantCategoryCode
            , @I_MerchantCategoryNameEN=@I_MerchantCategoryNameEN
            , @I_TransactionTypeCode=@I_TransactionTypeCode
            , @I_TransactionTypeNameEN=@I_TransactionTypeNameEN
            , @I_TransactionTypeNameAR=@I_TransactionTypeNameAR
            , @I_CounterPartyAccountID=@I_CounterPartyAccountID
            , @I_CounterPartyBankCode=@I_CounterPartyBankCode
            , @I_CounterPartyBankName=@I_CounterPartyBankName
            , @I_TransactionCounterPartyISOCountryCode=@I_TransactionCounterPartyISOCountryCode
            , @I_IsMerchantTransaction=@I_IsMerchantTransaction
            , @I_CreditDebitIndicator=@I_CreditDebitIndicator
            , @I_PromoCode=@I_PromoCode
            , @I_FirmNumber=@I_FirmNumber
            , @I_TransactionNarration=@I_TransactionNarration
            , @I_TransactionNumber=@I_TransactionNumber
            , @I_TxnProfile=@I_TxnProfile
            , @I_EbillServiceID=@I_EbillServiceID
            , @I_TransactionAmount=@I_TransactionAmount
            , @I_IsHealingMode=@I_IsHealingMode
            , @I_UserID=@I_UserID
            , @I_IsBulkUpdate=@I_IsBulkUpdate
            , @I_ThreadID=@I_ThreadID
            , @I_Batch=@I_Batch
            , @I_CategorizationPathMerchant=@V_PathM
            , @I_CategorizationPathCategory=@V_PathC
            , @O_MerchantID=@O_MerchantID OUTPUT
            , @O_MerchantOtherID=@O_MerchantOtherID OUTPUT
            , @O_CategoryID=@V_TempCat OUTPUT
            , @O_CategorizationPathMerchant=@V_PathM OUTPUT
            , @O_CategorizationPathCategory=@V_PathC OUTPUT;

        IF @V_TempCat IS NOT NULL
        BEGIN
            SET @O_CategoryID=@V_TempCat;
            GOTO Finalize;
        END

        IF @V_IsMerchantTx='N'
        BEGIN
            EXEC dbo.usp_Categorization_GetCategoryIDFromTransactionCategory
                  @I_TenantCode=@I_TenantCode
                , @I_TenantISOCountryCode=@I_TenantISOCountryCode
                , @I_LineOfBusinessName=@I_LineOfBusinessName
                , @I_IsLocalMerchant=@I_IsLocalMerchant
                , @I_MerchantCode=@I_MerchantCode
                , @I_TransactionISOCountryCode=@I_TransactionISOCountryCode
                , @I_MerchantNameEN=@I_MerchantNameEN
                , @I_MerchantNameAR=@I_MerchantNameAR
                , @I_SubMerchantNameEN=@I_SubMerchantNameEN
                , @I_SubMerchantNameAR=@I_SubMerchantNameAR
                , @I_MerchantCategoryCode=@I_MerchantCategoryCode
                , @I_MerchantCategoryNameEN=@I_MerchantCategoryNameEN
                , @I_TransactionTypeCode=@I_TransactionTypeCode
                , @I_TransactionTypeNameEN=@I_TransactionTypeNameEN
                , @I_TransactionTypeNameAR=@I_TransactionTypeNameAR
                , @I_CounterPartyAccountID=@I_CounterPartyAccountID
                , @I_CounterPartyBankCode=@I_CounterPartyBankCode
                , @I_CounterPartyBankName=@I_CounterPartyBankName
                , @I_TransactionCounterPartyISOCountryCode=@I_TransactionCounterPartyISOCountryCode
                , @I_IsMerchantTransaction=@I_IsMerchantTransaction
                , @I_CreditDebitIndicator=@I_CreditDebitIndicator
                , @I_PromoCode=@I_PromoCode
                , @I_FirmNumber=@I_FirmNumber
                , @I_TransactionNarration=@I_TransactionNarration
                , @I_TransactionNumber=@I_TransactionNumber
                , @I_TxnProfile=@I_TxnProfile
                , @I_EbillServiceID=@I_EbillServiceID
                , @I_TransactionAmount=@I_TransactionAmount
                , @I_IsHealingMode=@I_IsHealingMode
                , @I_UserID=@I_UserID
                , @I_IsBulkUpdate=@I_IsBulkUpdate
                , @I_ThreadID=@I_ThreadID
                , @I_Batch=@I_Batch
                , @I_CategorizationPathMerchant=@V_PathM
                , @I_CategorizationPathCategory=@V_PathC
                , @O_MerchantID=@O_MerchantID OUTPUT
                , @O_MerchantOtherID=@O_MerchantOtherID OUTPUT
                , @O_CategoryID=@V_TempCat OUTPUT
                , @O_CategorizationPathMerchant=@V_PathM OUTPUT
                , @O_CategorizationPathCategory=@V_PathC OUTPUT;

            IF @V_TempCat IS NOT NULL
            BEGIN
                SET @O_CategoryID=@V_TempCat;
                GOTO Finalize;
            END
        END
        ELSE
        BEGIN
            EXEC dbo.usp_Categorization_PathAppendCategory @V_PathC, N'SP01|SkipSP05', NULL, 'N', NULL, N'Reason=Merchant tx (TxnType weak)', 'N', @V_PathC OUTPUT;
        END

        SET @O_CategoryID = @V_DefaultCategoryID;
        SET @O_IsDefaultCategory = 'Y';
        EXEC dbo.usp_Categorization_PathAppendCategory @V_PathC, N'SP01|Default', CONCAT(N'CDI=',COALESCE(@V_CDI,'NULL')), 'Y', @O_CategoryID, N'From=DefaultCategoryParameter.CategoryID', 'N', @V_PathC OUTPUT;

Finalize:
        /* Validate CategoryID exists and active; if not, force default */
        IF @O_CategoryID IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM InMem.Category c WITH (NOLOCK) WHERE c.CategoryID=@O_CategoryID AND c.IsActive='Y')
            BEGIN
                EXEC dbo.usp_Categorization_PathAppendCategory
                      @V_PathC
                    , N'SP01|CategoryInvalid'
                    , CONCAT(N'CategoryID=',@O_CategoryID)
                    , 'N'
                    , NULL
                    , N'Reason=Category not found/Inactive; forcing default'
                    , 'N'
                    , @V_PathC OUTPUT;

                SET @O_CategoryID = NULL;
            END
        END


        IF @O_CategoryID = @V_DefaultCategoryID
            SET @O_IsDefaultCategory='Y';

        SET @O_CategorizationPathMerchant = @V_PathM;
        SET @O_CategorizationPathCategory = @V_PathC;
        SET @O_CategorizationEndTime = GETDATE();

        SET @O_ResultJson =
        (
            SELECT
                  @I_TenantCode AS TenantCode
                , @I_TenantISOCountryCode AS TenantISOCountryCode
                , @I_LineOfBusinessName AS LineOfBusinessName
                , @V_IsMerchantTx AS IsMerchantTransaction
                , @V_CDI AS CreditDebitIndicator
                , @O_CategoryID AS CategoryID
                , @O_IsDefaultCategory AS IsDefaultCategory
                , @O_CategorizationPathMerchant AS CategorizationPathMerchant
                , @O_CategorizationPathCategory AS CategorizationPathCategory
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        RETURN 0;
    END TRY
    BEGIN CATCH
        SET @O_CategoryID = COALESCE(@O_CategoryID, @V_DefaultCategoryID);
        SET @O_IsDefaultCategory='Y';

        EXEC dbo.usp_Categorization_PathAppendCategory @V_PathC, N'SP01|CATCH', NULL, 'N', @O_CategoryID, CONCAT(N'Error=',ERROR_MESSAGE()), 'N', @V_PathC OUTPUT;
        EXEC dbo.usp_Categorization_PathAppendCategory @V_PathC, N'SP01|DefaultInCatch', NULL, 'Y', @O_CategoryID, N'From=DefaultCategoryParameter', 'N', @V_PathC OUTPUT;

        SET @O_CategorizationPathMerchant=@V_PathM;
        SET @O_CategorizationPathCategory=@V_PathC;
        SET @O_CategorizationEndTime=GETDATE();

        SET @O_ResultJson =
        (
            SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage, @O_CategoryID AS CategoryID, @O_IsDefaultCategory AS IsDefaultCategory
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        RETURN 1;
    END CATCH
END
GO
