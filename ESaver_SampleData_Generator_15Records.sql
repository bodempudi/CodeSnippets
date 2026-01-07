/*==================================================================================================
    FILE:   ESaver_SampleData_Generator_15Records.sql

    PURPOSE:
        Generate 15 deterministic sample rows in dbo.CBG_ESaverAccountDetail for a given BusinessDate.

        This helps you test your end-to-end batch load SP(s):
            CBG_ESaverAccountDetail  -> Stage -> History -> dbo.CBG_ESaverNotification (Main)

    WHAT YOU GET:
        - Exactly 15 accounts inserted for the passed @I_BusinessDate
        - Each account is designed to hit common ESaver notification scenarios:
            * 50% / 90% / 100% (Interest) / 100% (Loyalty)
            * OneMonthBeforeDormant (NextDormancyDate = BusinessDate + 30)
            * NoActivityOverOneMonth (LastAccountActivityDate <= BusinessDate - 40)
            * OneMonthLeftForGoalMaturity (MaturityDate = BusinessDate + 30, CurrentBalance < MaturityAmount)
            * NotOnTrackMonthlyReminder (DATEDIFF(day, AccountOpenDate, BusinessDate) % 30 = 0, CurrentBalance < MaturityAmount)
            * Boundary values + bad-data rows (robustness)

    IMPORTANT:
        - This generator only inserts into dbo.CBG_ESaverAccountDetail.
        - Your notification SP(s) decide what becomes eligible and gets staged.
        - If your "open" AccountStatusCode differs from 1, update @OpenStatusCode below.

    HOW TO RUN:
        1) Execute this file once (creates the stored procedure).
        2) Generate data for any date:
             EXEC dbo.usp_GenerateSample_CBG_ESaverAccountDetail_15 @I_BusinessDate = '2025-12-12';

==================================================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GenerateSample_CBG_ESaverAccountDetail_15
(
      @I_BusinessDate         date
    , @I_StartAccountNumber   bigint       = 940001
    , @I_CleanupExisting      bit          = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @BDDT datetime2(0) = CONVERT(datetime2(0), @I_BusinessDate);
    DECLARE @OpenStatusCode tinyint = 1;  -- <<<<< CHANGE IF NEEDED IN YOUR SYSTEM

    DECLARE @A01 bigint = @I_StartAccountNumber + 0;   -- 55% => 50% band
    DECLARE @A02 bigint = @I_StartAccountNumber + 1;   -- 92% => 90% band
    DECLARE @A03 bigint = @I_StartAccountNumber + 2;   -- 110% Interest => 100% Interest
    DECLARE @A04 bigint = @I_StartAccountNumber + 3;   -- 105% Loyalty  => 100% Loyalty
    DECLARE @A05 bigint = @I_StartAccountNumber + 4;   -- Dormant in 30 days
    DECLARE @A06 bigint = @I_StartAccountNumber + 5;   -- No activity > 30 days
    DECLARE @A07 bigint = @I_StartAccountNumber + 6;   -- Maturity in 30 days (not reached)
    DECLARE @A08 bigint = @I_StartAccountNumber + 7;   -- Not-on-track monthly reminder (every 30 days)
    DECLARE @A09 bigint = @I_StartAccountNumber + 8;   -- 89.999% boundary (should be 50 band)
    DECLARE @A10 bigint = @I_StartAccountNumber + 9;   -- 99.999% boundary (should be 90 band)
    DECLARE @A11 bigint = @I_StartAccountNumber + 10;  -- 90.000% exact (should be 90 band)
    DECLARE @A12 bigint = @I_StartAccountNumber + 11;  -- Non-open ignored
    DECLARE @A13 bigint = @I_StartAccountNumber + 12;  -- Bad data: MaturityAmount = 0
    DECLARE @A14 bigint = @I_StartAccountNumber + 13;  -- Bad data: CurrentBalance = NULL
    DECLARE @A15 bigint = @I_StartAccountNumber + 14;  -- Multi-family: 95% + no activity > 30

    IF @I_CleanupExisting = 1
    BEGIN
        DELETE d
        FROM dbo.CBG_ESaverAccountDetail d
        WHERE d.BusinessDate = @BDDT
          AND d.AccountNumber BETWEEN @I_StartAccountNumber AND (@I_StartAccountNumber + 14);
    END;

    INSERT INTO dbo.CBG_ESaverAccountDetail
    (
          BusinessDate
        , AccountNumber
        , CustomerID
        , AccountNumberWithCheckDigit
        , MRSAccountNumber
        , ESaverName
        , ESaverAccountType
        , CurrentBalance
        , CurrentBalanceAsOnMaturityDate
        , MaturityDate
        , MaturityAmount
        , MaturityAmountAsOnMaturityDate
        , LastCreditDate
        , LastDebitDate
        , LastAccountActivityDate
        , LastAccountStatusChangeDate
        , AccountOpenDate
        , AccountCloseDate
        , AccountStatusCode
        , NextDormancyDate
    )
    SELECT
          x.BusinessDate
        , x.AccountNumber
        , x.CustomerID
        , x.AccountNumberWithCheckDigit
        , x.MRSAccountNumber
        , x.ESaverName
        , x.ESaverAccountType
        , x.CurrentBalance
        , x.CurrentBalanceAsOnMaturityDate
        , x.MaturityDate
        , x.MaturityAmount
        , x.MaturityAmountAsOnMaturityDate
        , x.LastCreditDate
        , x.LastDebitDate
        , x.LastAccountActivityDate
        , x.LastAccountStatusChangeDate
        , x.AccountOpenDate
        , x.AccountCloseDate
        , x.AccountStatusCode
        , x.NextDormancyDate
    FROM
    (
        SELECT
              BusinessDate = @BDDT
            , AccountNumber = @A01
            , CustomerID = 10001
            , AccountNumberWithCheckDigit = @A01 * 10 + 9
            , MRSAccountNumber = CONCAT('MRS-', @A01)
            , ESaverName = N'S1 - 55% (50 band)'
            , ESaverAccountType = 'Generic'
            , CurrentBalance = 550.000
            , CurrentBalanceAsOnMaturityDate = 550.000
            , MaturityDate = DATEADD(DAY, 120, @BDDT)
            , MaturityAmount = 1000.000
            , MaturityAmountAsOnMaturityDate = 1000.000
            , LastCreditDate = DATEADD(DAY, -3, @BDDT)
            , LastDebitDate = DATEADD(DAY, -10, @BDDT)
            , LastAccountActivityDate = DATEADD(DAY, -3, @BDDT)
            , LastAccountStatusChangeDate = DATEADD(DAY, -200, @BDDT)
            , AccountOpenDate = DATEADD(DAY, -61, @BDDT)
            , AccountCloseDate = NULL
            , AccountStatusCode = @OpenStatusCode
            , NextDormancyDate = DATEADD(DAY, 25, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A02, 10002, @A02 * 10 + 8, CONCAT('MRS-', @A02)
            , N'S2 - 92% (90 band)'
            , 'Generic'
            , 920.000, 920.000
            , DATEADD(DAY, 90, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -15, @BDDT), DATEADD(DAY, -1, @BDDT)
            , DATEADD(DAY, -300, @BDDT)
            , DATEADD(DAY, -95, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 10, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A03, 10003, @A03 * 10 + 7, CONCAT('MRS-', @A03)
            , N'S3 - 110% (100 Interest)'
            , 'InterestAccount'
            , 1100.000, 1100.000
            , DATEADD(DAY, 30, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -2, @BDDT), DATEADD(DAY, -20, @BDDT), DATEADD(DAY, -2, @BDDT)
            , DATEADD(DAY, -500, @BDDT)
            , DATEADD(DAY, -200, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 5, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A04, 10004, @A04 * 10 + 6, CONCAT('MRS-', @A04)
            , N'S4 - 105% (100 Loyalty)'
            , 'LoyaltyAccount'
            , 1050.000, 1050.000
            , DATEADD(DAY, 60, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -4, @BDDT), DATEADD(DAY, -25, @BDDT), DATEADD(DAY, -4, @BDDT)
            , DATEADD(DAY, -700, @BDDT)
            , DATEADD(DAY, -400, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 12, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A05, 10005, @A05 * 10 + 5, CONCAT('MRS-', @A05)
            , N'S5 - Dormant in 30 days'
            , 'Generic'
            , 100.000, 100.000
            , DATEADD(DAY, 200, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -9, @BDDT), DATEADD(DAY, -1, @BDDT)
            , DATEADD(DAY, -60, @BDDT)
            , DATEADD(DAY, -120, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 30, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A06, 10006, @A06 * 10 + 4, CONCAT('MRS-', @A06)
            , N'S6 - No activity > 30 days'
            , 'Generic'
            , 200.000, 200.000
            , DATEADD(DAY, 180, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -41, @BDDT), DATEADD(DAY, -42, @BDDT), DATEADD(DAY, -40, @BDDT)
            , DATEADD(DAY, -300, @BDDT)
            , DATEADD(DAY, -200, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 1, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A07, 10007, @A07 * 10 + 3, CONCAT('MRS-', @A07)
            , N'S7 - Maturity in 30 days'
            , 'Generic'
            , 700.000, 700.000
            , DATEADD(DAY, 30, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -7, @BDDT), DATEADD(DAY, -11, @BDDT), DATEADD(DAY, -7, @BDDT)
            , DATEADD(DAY, -100, @BDDT)
            , DATEADD(DAY, -75, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 20, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A08, 10008, @A08 * 10 + 2, CONCAT('MRS-', @A08)
            , N'S8 - NotOnTrack (30-day reminder)'
            , 'Generic'
            , 300.000, 300.000
            , DATEADD(DAY, 200, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -5, @BDDT), DATEADD(DAY, -50, @BDDT), DATEADD(DAY, -5, @BDDT)
            , DATEADD(DAY, -250, @BDDT)
            , DATEADD(DAY, -60, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 40, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A09, 10009, @A09 * 10 + 1, CONCAT('MRS-', @A09)
            , N'S9 - 89.999% (boundary)'
            , 'Generic'
            , 899.990, 899.990
            , DATEADD(DAY, 180, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -8, @BDDT), DATEADD(DAY, -1, @BDDT)
            , DATEADD(DAY, -100, @BDDT)
            , DATEADD(DAY, -120, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 20, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A10, 10010, @A10 * 10 + 0, CONCAT('MRS-', @A10)
            , N'S10 - 99.999% (boundary)'
            , 'Generic'
            , 999.990, 999.990
            , DATEADD(DAY, 180, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -8, @BDDT), DATEADD(DAY, -1, @BDDT)
            , DATEADD(DAY, -100, @BDDT)
            , DATEADD(DAY, -120, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 20, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A11, 10011, @A11 * 10 + 9, CONCAT('MRS-', @A11)
            , N'S11 - 90.000% exact'
            , 'Generic'
            , 900.000, 900.000
            , DATEADD(DAY, 180, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -8, @BDDT), DATEADD(DAY, -1, @BDDT)
            , DATEADD(DAY, -100, @BDDT)
            , DATEADD(DAY, -120, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 20, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A12, 10012, @A12 * 10 + 8, CONCAT('MRS-', @A12)
            , N'S12 - Non-open (ignore)'
            , 'Generic'
            , 950.000, 950.000
            , DATEADD(DAY, 180, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -8, @BDDT), DATEADD(DAY, -1, @BDDT)
            , DATEADD(DAY, -100, @BDDT)
            , DATEADD(DAY, -120, @BDDT)
            , NULL, 9, DATEADD(DAY, 20, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A13, 10013, @A13 * 10 + 7, CONCAT('MRS-', @A13)
            , N'S13 - BadData MA=0'
            , 'Generic'
            , 100.000, 100.000
            , DATEADD(DAY, 180, @BDDT)
            , 0.000, 0.000
            , DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -8, @BDDT), DATEADD(DAY, -1, @BDDT)
            , DATEADD(DAY, -100, @BDDT)
            , DATEADD(DAY, -120, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 20, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A14, 10014, @A14 * 10 + 6, CONCAT('MRS-', @A14)
            , N'S14 - BadData CB=NULL'
            , 'Generic'
            , NULL, NULL
            , DATEADD(DAY, 180, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -8, @BDDT), DATEADD(DAY, -1, @BDDT)
            , DATEADD(DAY, -100, @BDDT)
            , DATEADD(DAY, -120, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 20, @BDDT)

        UNION ALL
        SELECT
              @BDDT, @A15, 10015, @A15 * 10 + 5, CONCAT('MRS-', @A15)
            , N'S15 - Multi family (95% + NoActivity)'
            , 'Generic'
            , 950.000, 950.000
            , DATEADD(DAY, 180, @BDDT)
            , 1000.000, 1000.000
            , DATEADD(DAY, -45, @BDDT), DATEADD(DAY, -46, @BDDT), DATEADD(DAY, -40, @BDDT)
            , DATEADD(DAY, -100, @BDDT)
            , DATEADD(DAY, -200, @BDDT)
            , NULL, @OpenStatusCode, DATEADD(DAY, 20, @BDDT)

    ) x;

    SELECT
          d.BusinessDate
        , d.AccountNumber
        , d.CustomerID
        , d.ESaverAccountType
        , d.CurrentBalance
        , d.MaturityAmount
        , CurrentBalancePercentage =
            CASE
                WHEN d.MaturityAmount IS NULL OR d.MaturityAmount = 0 OR d.CurrentBalance IS NULL THEN NULL
                ELSE (d.CurrentBalance * 100.0 / d.MaturityAmount)
            END
        , d.MaturityDate
        , d.NextDormancyDate
        , d.LastAccountActivityDate
        , d.AccountOpenDate
        , d.AccountStatusCode
    FROM dbo.CBG_ESaverAccountDetail d
    WHERE d.BusinessDate = @BDDT
      AND d.AccountNumber BETWEEN @I_StartAccountNumber AND (@I_StartAccountNumber + 14)
    ORDER BY d.AccountNumber;
END;
GO

/*==================================================================================================
    QUICK START
==================================================================================================

EXEC dbo.usp_GenerateSample_CBG_ESaverAccountDetail_15
     @I_BusinessDate = '2025-12-12',
     @I_StartAccountNumber = 940001,
     @I_CleanupExisting = 1;

==================================================================================================*/
