/*==================================================================================================
    FILE:   ESaver_SampleData_Generator_15PerEventType.sql

    PURPOSE:
        Generate SAMPLE DATA for batch testing:
            - 15 records PER EventType/EventSubType (per configured notification event)
            - Inserts into dbo.CBG_ESaverAccountDetail for a given BusinessDate
            - Uses your status codes:
                * 0 = ACTIVE
                * 7 = CLOSED

    DESIGN:
        1) Reads configured events from dbo.CBG_ESaverNotificationEventType.
        2) For each (EventType, EventSubType), generates 15 accounts (deterministic AccountNumbers).
        3) For known EventSubTypes, it shapes account data so they should qualify for that event.
        4) For unknown/unmapped EventSubTypes, it still generates 15 rows but keeps them NEUTRAL and
           reports them so you can add mapping rules.

    HOW TO RUN:
        1) Execute this file (creates stored procedure).
        2) Generate data:
            EXEC dbo.usp_GenerateSample_CBG_ESaverAccountDetail_15PerEventType
                 @I_BusinessDate = '2025-12-12',
                 @I_StartAccountNumber = 960000,
                 @I_CleanupExisting = 1,
                 @I_OnlyActiveEventTypes = 1;

        3) Run your end-to-end batch load SP(s) for that BusinessDate.

==================================================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GenerateSample_CBG_ESaverAccountDetail_15PerEventType
(
      @I_BusinessDate           date
    , @I_StartAccountNumber     bigint       = 960000
    , @I_CleanupExisting        bit          = 1
    , @I_OnlyActiveEventTypes   bit          = 1   -- 1 = only active events, 0 = all events
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @BDDT datetime2(0) = CONVERT(datetime2(0), @I_BusinessDate);

    -- Your status codes
    DECLARE @StatusActive tinyint = 0;
    DECLARE @StatusClosed tinyint = 7;

    /*----------------------------------------------------------------------------------------------
        1) Pull configured events
           Adjust IsActive filter if your table differs.
    ----------------------------------------------------------------------------------------------*/
    IF OBJECT_ID('tempdb..#Evt') IS NOT NULL DROP TABLE #Evt;

    SELECT
          EventType
        , EventSubType
        , RowNum = ROW_NUMBER() OVER (ORDER BY EventType, EventSubType)
        , IsMapped = CAST(0 AS bit)
    INTO #Evt
    FROM dbo.CBG_ESaverNotificationEventType
    WHERE (@I_OnlyActiveEventTypes = 0)
       OR (ISNULL(IsActive,'Y') IN ('Y','1'));   -- adjust if IsActive is BIT or different

    DECLARE @EvtCnt int = (SELECT COUNT(*) FROM #Evt);
    IF @EvtCnt = 0
    BEGIN
        RAISERROR('No rows found in dbo.CBG_ESaverNotificationEventType (after active filter).', 16, 1);
        RETURN;
    END;

    /*----------------------------------------------------------------------------------------------
        2) Cleanup existing sample rows for this date and account range
    ----------------------------------------------------------------------------------------------*/
    DECLARE @MinAcc bigint = @I_StartAccountNumber;
    DECLARE @MaxAcc bigint = @I_StartAccountNumber + (CAST(@EvtCnt AS bigint) * 15) - 1;

    IF @I_CleanupExisting = 1
    BEGIN
        DELETE d
        FROM dbo.CBG_ESaverAccountDetail d
        WHERE d.BusinessDate = @BDDT
          AND d.AccountNumber BETWEEN @MinAcc AND @MaxAcc;
    END;

    /*----------------------------------------------------------------------------------------------
        3) Numbers 1..15
    ----------------------------------------------------------------------------------------------*/
    IF OBJECT_ID('tempdb..#N') IS NOT NULL DROP TABLE #N;

    ;WITH n AS
    (
        SELECT 1 AS n
        UNION ALL SELECT n + 1 FROM n WHERE n < 15
    )
    SELECT n INTO #N FROM n OPTION (MAXRECURSION 100);

    /*----------------------------------------------------------------------------------------------
        4) Insert rows
    ----------------------------------------------------------------------------------------------*/
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
          @BDDT                                                                 AS BusinessDate
        , AccountNumber = @I_StartAccountNumber + (CAST(e.RowNum - 1 AS bigint) * 15) + (n.n - 1)
        , CustomerID = 200000 + (e.RowNum * 100) + n.n
        , AccountNumberWithCheckDigit = (@I_StartAccountNumber + (CAST(e.RowNum - 1 AS bigint) * 15) + (n.n - 1)) * 10 + 9
        , MRSAccountNumber = CONCAT('MRS-', @I_StartAccountNumber + (CAST(e.RowNum - 1 AS bigint) * 15) + (n.n - 1))
        , ESaverName = CONCAT('EVT ', e.EventType, ' / ', e.EventSubType, ' / #', n.n)
        , ESaverAccountType =
            CASE
                WHEN e.EventSubType = 'ESaver100PercentGoalReachedBeforeGoalDateInterest' THEN 'InterestAccount'
                WHEN e.EventSubType = 'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'  THEN 'LoyaltyAccount'
                ELSE 'Generic'
            END
        , CurrentBalance =
            CASE
                WHEN e.EventSubType = 'ESaver50PercentGoalReached'
                    THEN 500.000 + (n.n * 1.000)
                WHEN e.EventSubType = 'ESaver90PercentGoalReached'
                    THEN 900.000 + (n.n * 1.000)
                WHEN e.EventSubType = 'ESaver100PercentGoalReachedBeforeGoalDateInterest'
                    THEN 1000.000 + (n.n * 10.000)
                WHEN e.EventSubType = 'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
                    THEN 1000.000 + (n.n * 10.000)

                WHEN e.EventSubType IN ('ESaverOneMonthBeforeDormant','ESaverNoActivityOverOneMonth','ESaverOneMonthLeftForGoalMaturity','ESaverNotOnTrackMonthlyReminder')
                    THEN 200.000 + (n.n * 5.000)

                ELSE 10.000
            END
        , CurrentBalanceAsOnMaturityDate =
            CASE
                WHEN e.EventSubType IN ('ESaver50PercentGoalReached','ESaver90PercentGoalReached','ESaver100PercentGoalReachedBeforeGoalDateInterest','ESaver100PercentGoalReachedBeforeGoalDateLoyalty')
                    THEN
                        CASE
                            WHEN e.EventSubType = 'ESaver50PercentGoalReached' THEN 500.000 + (n.n * 1.000)
                            WHEN e.EventSubType = 'ESaver90PercentGoalReached' THEN 900.000 + (n.n * 1.000)
                            ELSE 1000.000 + (n.n * 10.000)
                        END
                ELSE NULL
            END
        , MaturityDate =
            CASE
                WHEN e.EventSubType = 'ESaverOneMonthLeftForGoalMaturity' THEN DATEADD(DAY, 30, @BDDT)
                ELSE DATEADD(DAY, 120, @BDDT)
            END
        , MaturityAmount = 1000.000
        , MaturityAmountAsOnMaturityDate = 1000.000
        , LastCreditDate = DATEADD(DAY, -1, @BDDT)
        , LastDebitDate  =
            CASE WHEN e.EventSubType = 'ESaverNoActivityOverOneMonth' THEN DATEADD(DAY, -42, @BDDT)
                 ELSE DATEADD(DAY, -10, @BDDT) END
        , LastAccountActivityDate =
            CASE WHEN e.EventSubType = 'ESaverNoActivityOverOneMonth' THEN DATEADD(DAY, -40, @BDDT)
                 ELSE DATEADD(DAY, -2, @BDDT) END
        , LastAccountStatusChangeDate = DATEADD(DAY, -200, @BDDT)
        , AccountOpenDate =
            CASE WHEN e.EventSubType = 'ESaverNotOnTrackMonthlyReminder' THEN DATEADD(DAY, -60, @BDDT)
                 ELSE DATEADD(DAY, -61, @BDDT) END
        , AccountCloseDate = NULL
        , AccountStatusCode =
            CASE
                WHEN e.EventSubType NOT IN
                     (
                        'ESaver50PercentGoalReached',
                        'ESaver90PercentGoalReached',
                        'ESaver100PercentGoalReachedBeforeGoalDateInterest',
                        'ESaver100PercentGoalReachedBeforeGoalDateLoyalty',
                        'ESaverOneMonthBeforeDormant',
                        'ESaverNoActivityOverOneMonth',
                        'ESaverOneMonthLeftForGoalMaturity',
                        'ESaverNotOnTrackMonthlyReminder'
                     )
                     AND n.n = 15
                    THEN @StatusClosed
                ELSE @StatusActive
            END
        , NextDormancyDate =
            CASE WHEN e.EventSubType = 'ESaverOneMonthBeforeDormant' THEN DATEADD(DAY, 30, @BDDT)
                 ELSE DATEADD(DAY, 90, @BDDT) END
    FROM #Evt e
    CROSS JOIN #N n;

    /*----------------------------------------------------------------------------------------------
        5) Mark mapped events (for reporting)
    ----------------------------------------------------------------------------------------------*/
    UPDATE e
    SET e.IsMapped = 1
    FROM #Evt e
    WHERE e.EventSubType IN
    (
        'ESaver50PercentGoalReached',
        'ESaver90PercentGoalReached',
        'ESaver100PercentGoalReachedBeforeGoalDateInterest',
        'ESaver100PercentGoalReachedBeforeGoalDateLoyalty',
        'ESaverOneMonthBeforeDormant',
        'ESaverNoActivityOverOneMonth',
        'ESaverOneMonthLeftForGoalMaturity',
        'ESaverNotOnTrackMonthlyReminder'
    );

    /*----------------------------------------------------------------------------------------------
        6) Output summary + unmapped warnings
    ----------------------------------------------------------------------------------------------*/
    SELECT
          BusinessDate = @BDDT
        , GeneratedEventCount = @EvtCnt
        , RowsInserted = @EvtCnt * 15
        , AccountNumberRange = CONCAT(@MinAcc, ' .. ', @MaxAcc)
        , StatusCodes = CONCAT('Active=', @StatusActive, ', Closed=', @StatusClosed);

    SELECT
          EventType
        , EventSubType
        , IsMapped
        , Note = CASE WHEN IsMapped = 1 THEN 'MAPPED (data shaped to qualify)' ELSE 'UNMAPPED (NEUTRAL rows; add rules)' END
    FROM #Evt
    ORDER BY EventType, EventSubType;

END;
GO

/*==================================================================================================
    QUICK START
==================================================================================================

EXEC dbo.usp_GenerateSample_CBG_ESaverAccountDetail_15PerEventType
     @I_BusinessDate = '2025-12-12',
     @I_StartAccountNumber = 960000,
     @I_CleanupExisting = 1,
     @I_OnlyActiveEventTypes = 1;

==================================================================================================*/
