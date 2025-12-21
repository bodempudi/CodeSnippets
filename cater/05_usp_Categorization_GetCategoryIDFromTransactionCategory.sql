SET NOCOUNT ON;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Categorization_GetCategoryIDFromTransactionCategory
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

    DECLARE @V_TenantID BIGINT, @V_LobID BIGINT, @V_TxnType VARCHAR(128);

    SET @O_CategoryID = NULL;
    SET @O_MerchantID = NULL;
    SET @O_MerchantOtherID = NULL;
    SET @O_CategorizationPathMerchant = @I_CategorizationPathMerchant;
    SET @O_CategorizationPathCategory = @I_CategorizationPathCategory;

    SET @V_TxnType = NULLIF(LTRIM(RTRIM(@I_TransactionTypeCode)),'');

    IF @V_TxnType IS NULL
    BEGIN
        EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP05|Skip', NULL, 'N', NULL, N'Reason=TxnType NULL', 'N', @O_CategorizationPathCategory OUTPUT;
        RETURN 0;
    END

    SELECT @V_TenantID = t.TenantID
    FROM InMem.Tenant t WITH (NOLOCK)
    WHERE t.TenantCode=@I_TenantCode
      AND t.TennantISOCountryCode=@I_TenantISOCountryCode
      AND t.IsActive='Y';

    SELECT @V_LobID = lob.LineOfBusinessID
    FROM InMem.LineOfBusiness lob WITH (NOLOCK)
    WHERE lob.TennantID=@V_TenantID
      AND lob.LineOfBusinessName=@I_LineOfBusinessName;

    SELECT TOP (1) @O_CategoryID = ctt.CategoryID
    FROM InMem.CategoryTransactionType ctt WITH (NOLOCK)
    WHERE ctt.TennantID=@V_TenantID AND ctt.LineOfBusinessID=@V_LobID AND ctt.TransactionTypeCode=@V_TxnType;

    IF @O_CategoryID IS NOT NULL
        EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP05|Hit', @V_TxnType, 'Y', @O_CategoryID, N'From=CategoryTransactionType.CategoryID', 'N', @O_CategorizationPathCategory OUTPUT;
    ELSE
        EXEC dbo.usp_Categorization_PathAppendCategory @O_CategorizationPathCategory, N'SP05|NoMatch', @V_TxnType, 'N', NULL, N'Reason=Not mapped', 'N', @O_CategorizationPathCategory OUTPUT;

    RETURN 0;
END
GO
