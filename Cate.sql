CREATE OR ALTER PROCEDURE dbo.usp_Categorize_Transaction_Realtime
(
      @TenantID                 BIGINT
    , @LineOfBusinessID          BIGINT
    , @TransactionTypeCode       VARCHAR(100)
    , @TransactionISOCountryCode CHAR(2)
    , @MerchantCode              VARCHAR(200) = NULL
    , @MerchantName              NVARCHAR(300) = NULL
    , @Narration                 NVARCHAR(2000) = NULL
    , @MerchantCategoryCode      VARCHAR(10) = NULL  -- MCC
    , @CreditDebitIndicator      CHAR(1)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE
          @IsMerchantTransaction CHAR(1)
        , @FinalCategoryID       BIGINT
        , @CategorySource        VARCHAR(30)
        , @SearchText            NVARCHAR(MAX);

    ----------------------------------------------------
    -- Transaction type gate
    ----------------------------------------------------
    SELECT
        @IsMerchantTransaction = IsMerchantTransaction,
        @FinalCategoryID = CategoryID
    FROM InMem.CategoryTransactionType
    WHERE TenantID = @TenantID
      AND LineOfBusinessID = @LineOfBusinessID
      AND TransactionTypeCode = @TransactionTypeCode
      AND IsActive = 'Y';

    IF (ISNULL(@IsMerchantTransaction,'N') <> 'Y')
    BEGIN
        SELECT @FinalCategoryID AS CategoryID, 'TRANSACTION_TYPE' AS CategorySource;
        RETURN;
    END

    ----------------------------------------------------
    -- Merchant lookup (Local & International)
    ----------------------------------------------------
    SELECT TOP 1
        @FinalCategoryID = CategoryID
    FROM InMem.Merchant
    WHERE TenantID = @TenantID
      AND MerchantISOCountryCode = @TransactionISOCountryCode
      AND MerchantCode = @MerchantCode
      AND IsActive = 'Y'
      AND CategoryID IS NOT NULL;

    IF (@FinalCategoryID IS NOT NULL)
    BEGIN
        SELECT @FinalCategoryID AS CategoryID, 'MERCHANT' AS CategorySource;
        RETURN;
    END

    ----------------------------------------------------
    -- MerchantExpression -> MerchantOther
    ----------------------------------------------------
    SET @SearchText = UPPER(CONCAT(ISNULL(@MerchantName,''),' ',ISNULL(@Narration,'')));

    SELECT TOP 1
        @FinalCategoryID = MO.CategoryID
    FROM InMem.MerchantExpression ME
    JOIN InMem.MerchantOther MO
        ON MO.MerchantOtherID = ME.MerchantOtherID
       AND MO.IsActive = 'Y'
    WHERE ME.TenantID = @TenantID
      AND ME.IsActive = 'Y'
      AND ME.IsSqlOrRegex = 'S'
      AND UPPER(@SearchText) LIKE UPPER(ME.Expression)
    ORDER BY ME.ExecutionOrder;

    IF (@FinalCategoryID IS NOT NULL)
    BEGIN
        SELECT @FinalCategoryID AS CategoryID, 'MERCHANT_OTHER' AS CategorySource;
        RETURN;
    END

    ----------------------------------------------------
    -- MCC fallback
    ----------------------------------------------------
    SELECT
        @FinalCategoryID = CategoryID
    FROM InMem.CategoryMerchantCategory
    WHERE TenantID = @TenantID
      AND MerchantCategoryCode = @MerchantCategoryCode
      AND IsActive = 'Y';

    IF (@FinalCategoryID IS NOT NULL)
    BEGIN
        SELECT @FinalCategoryID AS CategoryID, 'MCC' AS CategorySource;
        RETURN;
    END

    ----------------------------------------------------
    -- TransactionType default
    ----------------------------------------------------
    SELECT
        @FinalCategoryID = CategoryID
    FROM InMem.CategoryTransactionType
    WHERE TenantID = @TenantID
      AND LineOfBusinessID = @LineOfBusinessID
      AND TransactionTypeCode = @TransactionTypeCode
      AND IsActive = 'Y';

    IF (@FinalCategoryID IS NOT NULL)
    BEGIN
        SELECT @FinalCategoryID AS CategoryID, 'TRANSACTION_TYPE_DEFAULT' AS CategorySource;
        RETURN;
    END

    ----------------------------------------------------
    -- Default category
    ----------------------------------------------------
    SELECT
        @FinalCategoryID = CategoryID
    FROM InMem.DefaultCategoryParameter
    WHERE TenantID = @TenantID
      AND LineOfBusinessID = @LineOfBusinessID
      AND CreditDebitIndicator = @CreditDebitIndicator;

    SELECT @FinalCategoryID AS CategoryID, 'DEFAULT' AS CategorySource;
END
GO
