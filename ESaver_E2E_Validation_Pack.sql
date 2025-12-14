/*====================================================================================================================
  FILE:    ESaver_E2E_Validation_Pack.sql
  PURPOSE: End-to-end sample data + validation pack for eSaver notifications.
           This script inserts sample rows into dbo.CBG_ESaverAccountDetail for ONE business date,
           then guides you to run your existing ETL/SP flow, and finally validates the final MAIN table:
               dbo.CBG_ESaverNotification

  IMPORTANT:
  1) This script DOES NOT create/alter your procedures. It assumes your existing flow is already deployed.
  2) This script assumes dbo.CBG_ESaverAccountDetail has the columns used below.
     If your physical column names differ, adjust only the INSERT column list.
  3) This script assumes you update MAIN only for real notifications (IsDummyEntry='N').
     Dummy rows should remain in History only and must NOT update dbo.CBG_ESaverNotification.
  4) SequenceNumber expectation is based on yyyymmdd; it is not required for MAIN validation.

  HOW TO USE:
  Step A) Run SECTION 0 (variables)
  Step B) Run SECTION 1 (cleanup - optional)
  Step C) Run SECTION 2 (insert sample data into CBG_ESaverAccountDetail)
  Step D) Run SECTION 3 (execute your end-to-end flow - replace proc names if needed)
  Step E) Run SECTION 4 (validation queries - expected vs actual)
====================================================================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

------------------------------------------------------------
-- SECTION 0: Variables
------------------------------------------------------------
DECLARE @BusinessDate      date        = '2025-12-12';
DECLARE @BusinessDateTime  datetime2(0) = CONVERT(datetime2(0), @BusinessDate);

PRINT 'BusinessDate = ' + CONVERT(varchar(10), @BusinessDate, 120);

------------------------------------------------------------
-- SECTION 1: Cleanup (OPTIONAL) - safe rerun for sample accounts
------------------------------------------------------------
/*
    This deletes ONLY the rows for the sample BusinessDate and AccountNumber range used in this pack.
*/
DELETE d
FROM dbo.CBG_ESaverAccountDetail d
WHERE d.BusinessDate = @BusinessDateTime
  AND d.AccountNumber IN (900001,900002,900003,900004,900005,900006,900007);

-- Optional: If you want to reset MAIN for these accounts for this business date (ONLY if safe in your env), uncomment:
--DELETE n
--FROM dbo.CBG_ESaverNotification n
--WHERE CONVERT(date, n.BusinessDate) = @BusinessDate
--  AND n.AccountNumber IN (900001,900002,900003,900004,900005,900006,900007);

PRINT 'Cleanup completed (if rows existed).';

------------------------------------------------------------
-- SECTION 2: Insert sample data into dbo.CBG_ESaverAccountDetail
-- Covers scenarios:
--  A1  55%    -> ESaver50PercentGoalReached (REAL)
--  A2  92%    -> ESaver90PercentGoalReached (REAL)  (and 50% is dummy only, must not update MAIN)
--  A3  110%   -> ESaver100PercentGoalReachedBeforeGoalDateInterest (REAL)
--  A4  105%   -> ESaver100PercentGoalReachedBeforeGoalDateLoyalty (REAL)
--  A5  No activity 40 days -> ESaverNoActivityOverOneMonth (REAL)
--  A6  Maturity in 30 days and < maturity amount -> ESaverOneMonthLeftForGoalMaturity (REAL)
--  A7  Every 30 days monthly reminder and < maturity -> ESaverNotOnTrackMonthlyReminder (REAL)
------------------------------------------------------------

INSERT INTO dbo.CBG_ESaverAccountDetail
(
    BusinessDate
   ,AccountNumber
   ,CustomerID
   ,AccountNumberWithCheckDigit
   ,MRSAccountNumber
   ,ESaverName
   ,ESaverAccountType
   ,CurrentBalance
   ,CurrentBalanceAsOnMaturityDate
   ,MaturityDate
   ,MaturityAmount
   ,MaturityAmountAsOnMaturityDate
   ,LastCreditDate
   ,LastDebitDate
   ,LastAccountActivityDate
   ,LastAccountStatusChangeDate
   ,AccountOpenDate
   ,AccountCloseDate
   ,AccountStatusCode
   ,NextDormancyDate
)
SELECT
    @BusinessDateTime                      AS BusinessDate
   ,x.AccountNumber
   ,x.CustomerID
   ,x.AccountNumberWithCheckDigit
   ,x.MRSAccountNumber
   ,x.ESaverName
   ,x.ESaverAccountType
   ,x.CurrentBalance
   ,x.CurrentBalanceAsOnMaturityDate
   ,x.MaturityDate
   ,x.MaturityAmount
   ,x.MaturityAmountAsOnMaturityDate
   ,x.LastCreditDate
   ,x.LastDebitDate
   ,x.LastAccountActivityDate
   ,x.LastAccountStatusChangeDate
   ,x.AccountOpenDate
   ,x.AccountCloseDate
   ,x.AccountStatusCode
   ,x.NextDormancyDate
FROM
(
    -- A1: 55% => 50% goal reached
    SELECT
        AccountNumber              = 900001
       ,CustomerID                 = 501
       ,AccountNumberWithCheckDigit= 9000019
       ,MRSAccountNumber           = 'MRS-900001'
       ,ESaverName                 = N'Goal - Bike'
       ,ESaverAccountType          = 'Generic'
       ,CurrentBalance             = 550.000
       ,CurrentBalanceAsOnMaturityDate = 550.000
       ,MaturityAmount             = 1000.000
       ,MaturityAmountAsOnMaturityDate = 1000.000
       ,MaturityDate               = DATEADD(DAY, 120, @BusinessDateTime)
       ,LastCreditDate             = DATEADD(DAY, -3,  @BusinessDateTime)
       ,LastDebitDate              = DATEADD(DAY, -10, @BusinessDateTime)
       ,LastAccountActivityDate    = DATEADD(DAY, -3,  @BusinessDateTime)
       ,LastAccountStatusChangeDate= DATEADD(DAY, -200,@BusinessDateTime)
       ,AccountOpenDate            = DATEADD(DAY, -61, @BusinessDateTime)
       ,AccountCloseDate           = NULL
       ,AccountStatusCode          = 1
       ,NextDormancyDate           = DATEADD(DAY, 25, @BusinessDateTime)

    UNION ALL

    -- A2: 92% => 90% goal reached (and <100 ensures it stays in 90 block)
    SELECT
        AccountNumber              = 900002
       ,CustomerID                 = 502
       ,AccountNumberWithCheckDigit= 9000028
       ,MRSAccountNumber           = 'MRS-900002'
       ,ESaverName                 = N'Goal - Vacation'
       ,ESaverAccountType          = 'Generic'
       ,CurrentBalance             = 920.000
       ,CurrentBalanceAsOnMaturityDate = 920.000
       ,MaturityAmount             = 1000.000
       ,MaturityAmountAsOnMaturityDate = 1000.000
       ,MaturityDate               = DATEADD(DAY, 90, @BusinessDateTime)
       ,LastCreditDate             = DATEADD(DAY, -1,  @BusinessDateTime)
       ,LastDebitDate              = DATEADD(DAY, -15, @BusinessDateTime)
       ,LastAccountActivityDate    = DATEADD(DAY, -1,  @BusinessDateTime)
       ,LastAccountStatusChangeDate= DATEADD(DAY, -300,@BusinessDateTime)
       ,AccountOpenDate            = DATEADD(DAY, -95, @BusinessDateTime)
       ,AccountCloseDate           = NULL
       ,AccountStatusCode          = 1
       ,NextDormancyDate           = DATEADD(DAY, 10, @BusinessDateTime)

    UNION ALL

    -- A3: 110% InterestAccount => Interest 100% block
    SELECT
        AccountNumber              = 900003
       ,CustomerID                 = 503
       ,AccountNumberWithCheckDigit= 9000037
       ,MRSAccountNumber           = 'MRS-900003'
       ,ESaverName                 = N'Interest Goal'
       ,ESaverAccountType          = 'InterestAccount'
       ,CurrentBalance             = 1100.000
       ,CurrentBalanceAsOnMaturityDate = 1100.000
       ,MaturityAmount             = 1000.000
       ,MaturityAmountAsOnMaturityDate = 1000.000
       ,MaturityDate               = DATEADD(DAY, 30, @BusinessDateTime)
       ,LastCreditDate             = DATEADD(DAY, -2,  @BusinessDateTime)
       ,LastDebitDate              = DATEADD(DAY, -20, @BusinessDateTime)
       ,LastAccountActivityDate    = DATEADD(DAY, -2,  @BusinessDateTime)
       ,LastAccountStatusChangeDate= DATEADD(DAY, -500,@BusinessDateTime)
       ,AccountOpenDate            = DATEADD(DAY, -200,@BusinessDateTime)
       ,AccountCloseDate           = NULL
       ,AccountStatusCode          = 1
       ,NextDormancyDate           = DATEADD(DAY, 5,  @BusinessDateTime)

    UNION ALL

    -- A4: 105% LoyaltyAccount => Loyalty 100% block
    SELECT
        AccountNumber              = 900004
       ,CustomerID                 = 504
       ,AccountNumberWithCheckDigit= 9000046
       ,MRSAccountNumber           = 'MRS-900004'
       ,ESaverName                 = N'Loyalty Goal'
       ,ESaverAccountType          = 'LoyaltyAccount'
       ,CurrentBalance             = 1050.000
       ,CurrentBalanceAsOnMaturityDate = 1050.000
       ,MaturityAmount             = 1000.000
       ,MaturityAmountAsOnMaturityDate = 1000.000
       ,MaturityDate               = DATEADD(DAY, 60, @BusinessDateTime)
       ,LastCreditDate             = DATEADD(DAY, -4,  @BusinessDateTime)
       ,LastDebitDate              = DATEADD(DAY, -25, @BusinessDateTime)
       ,LastAccountActivityDate    = DATEADD(DAY, -4,  @BusinessDateTime)
       ,LastAccountStatusChangeDate= DATEADD(DAY, -700,@BusinessDateTime)
       ,AccountOpenDate            = DATEADD(DAY, -400,@BusinessDateTime)
       ,AccountCloseDate           = NULL
       ,AccountStatusCode          = 1
       ,NextDormancyDate           = DATEADD(DAY, 12, @BusinessDateTime)

    UNION ALL

    -- A5: No activity 40 days => NoActivityOverOneMonth
    SELECT
        AccountNumber              = 900005
       ,CustomerID                 = 505
       ,AccountNumberWithCheckDigit= 9000055
       ,MRSAccountNumber           = 'MRS-900005'
       ,ESaverName                 = N'Inactive Goal'
       ,ESaverAccountType          = 'Generic'
       ,CurrentBalance             = 200.000
       ,CurrentBalanceAsOnMaturityDate = 200.000
       ,MaturityAmount             = 1000.000
       ,MaturityAmountAsOnMaturityDate = 1000.000
       ,MaturityDate               = DATEADD(DAY, 180, @BusinessDateTime)
       ,LastCreditDate             = DATEADD(DAY, -41, @BusinessDateTime)
       ,LastDebitDate              = DATEADD(DAY, -42, @BusinessDateTime)
       ,LastAccountActivityDate    = DATEADD(DAY, -40, @BusinessDateTime)
       ,LastAccountStatusChangeDate= DATEADD(DAY, -300,@BusinessDateTime)
       ,AccountOpenDate            = DATEADD(DAY, -200,@BusinessDateTime)
       ,AccountCloseDate           = NULL
       ,AccountStatusCode          = 1
       ,NextDormancyDate           = DATEADD(DAY, 1,  @BusinessDateTime)

    UNION ALL

    -- A6: Maturity in 30 days and not reached => OneMonthLeftForGoalMaturity
    SELECT
        AccountNumber              = 900006
       ,CustomerID                 = 506
       ,AccountNumberWithCheckDigit= 9000064
       ,MRSAccountNumber           = 'MRS-900006'
       ,ESaverName                 = N'Goal - One Month Left'
       ,ESaverAccountType          = 'Generic'
       ,CurrentBalance             = 700.000
       ,CurrentBalanceAsOnMaturityDate = 700.000
       ,MaturityAmount             = 1000.000
       ,MaturityAmountAsOnMaturityDate = 1000.000
       ,MaturityDate               = DATEADD(DAY, 30, @BusinessDateTime)
       ,LastCreditDate             = DATEADD(DAY, -7,  @BusinessDateTime)
       ,LastDebitDate              = DATEADD(DAY, -11, @BusinessDateTime)
       ,LastAccountActivityDate    = DATEADD(DAY, -7,  @BusinessDateTime)
       ,LastAccountStatusChangeDate= DATEADD(DAY, -100,@BusinessDateTime)
       ,AccountOpenDate            = DATEADD(DAY, -75, @BusinessDateTime)
       ,AccountCloseDate           = NULL
       ,AccountStatusCode          = 1
       ,NextDormancyDate           = DATEADD(DAY, 20, @BusinessDateTime)

    UNION ALL

    -- A7: Monthly reminder every 30 days (open date diff % 30 = 0) and not reached
    SELECT
        AccountNumber              = 900007
       ,CustomerID                 = 507
       ,AccountNumberWithCheckDigit= 9000073
       ,MRSAccountNumber           = 'MRS-900007'
       ,ESaverName                 = N'Goal - Monthly Reminder'
       ,ESaverAccountType          = 'Generic'
       ,CurrentBalance             = 300.000
       ,CurrentBalanceAsOnMaturityDate = 300.000
       ,MaturityAmount             = 1000.000
       ,MaturityAmountAsOnMaturityDate = 1000.000
       ,MaturityDate               = DATEADD(DAY, 200, @BusinessDateTime)
       ,LastCreditDate             = DATEADD(DAY, -5,  @BusinessDateTime)
       ,LastDebitDate              = DATEADD(DAY, -50, @BusinessDateTime)
       ,LastAccountActivityDate    = DATEADD(DAY, -5,  @BusinessDateTime)
       ,LastAccountStatusChangeDate= DATEADD(DAY, -250,@BusinessDateTime)
       ,AccountOpenDate            = DATEADD(DAY, -60, @BusinessDateTime) -- 60 % 30 = 0
       ,AccountCloseDate           = NULL
       ,AccountStatusCode          = 1
       ,NextDormancyDate           = DATEADD(DAY, 40, @BusinessDateTime)
) x;

PRINT 'Inserted sample rows into dbo.CBG_ESaverAccountDetail.';

------------------------------------------------------------
-- SECTION 2.1: Show input snapshot (sanity)
------------------------------------------------------------
SELECT
    d.BusinessDate,
    d.AccountNumber,
    d.CustomerID,
    d.ESaverAccountType,
    d.CurrentBalance,
    d.MaturityAmount,
    CurrentBalancePercentage =
        (d.CurrentBalance * 100.0 / NULLIF(d.MaturityAmount, 0)),
    d.MaturityDate,
    d.LastAccountActivityDate,
    d.AccountOpenDate,
    d.AccountStatusCode,
    d.NextDormancyDate
FROM dbo.CBG_ESaverAccountDetail d
WHERE d.BusinessDate = @BusinessDateTime
  AND d.AccountNumber BETWEEN 900001 AND 900007
ORDER BY d.AccountNumber;

------------------------------------------------------------
-- SECTION 3: Run your end-to-end flow (EDIT proc names if needed)
------------------------------------------------------------
/*
    Replace these EXEC calls with your actual procedure names.

    Typical flow you described:
      AccountDetail -> Stage (truncate+load) -> History (NOT EXISTS) -> MAIN (increment counts)

    Examples (adjust):
      EXEC dbo.usp_StageLoad_CBG_ESaverNotification      @I_BusinessDate = @BusinessDate;
      EXEC dbo.usp_LoadHistory_CBG_ESaverNotification    @I_BusinessDate = @BusinessDate;
      EXEC dbo.usp_LoadMain_CBG_ESaverNotification       @I_BusinessDate = @BusinessDate;

    If you have ONE orchestrator proc, call only that.
*/
--EXEC dbo.usp_StageLoad_CBG_ESaverNotification   @I_BusinessDate = @BusinessDate;
--EXEC dbo.usp_LoadHistory_CBG_ESaverNotification @I_BusinessDate = @BusinessDate;
--EXEC dbo.usp_LoadMain_CBG_ESaverNotification    @I_BusinessDate = @BusinessDate;

PRINT 'SECTION 3: Execute your stored procedures now (uncomment and adjust proc names).';

------------------------------------------------------------
-- SECTION 4: Expected results in MAIN table dbo.CBG_ESaverNotification
-- EXPECTED (first run, real-only in MAIN):
--  900001 -> ESaver50PercentGoalReached
--  900002 -> ESaver90PercentGoalReached
--  900003 -> ESaver100PercentGoalReachedBeforeGoalDateInterest
--  900004 -> ESaver100PercentGoalReachedBeforeGoalDateLoyalty
--  900005 -> ESaverNoActivityOverOneMonth
--  900006 -> ESaverOneMonthLeftForGoalMaturity
--  900007 -> ESaverNotOnTrackMonthlyReminder
------------------------------------------------------------

;WITH Expected AS
(
    SELECT 'BatchGeneric' AS EventType, 'ESaver50PercentGoalReached' AS EventSubType, 900001 AS AccountNumber
    UNION ALL SELECT 'BatchGeneric','ESaver90PercentGoalReached',900002
    UNION ALL SELECT 'BatchGeneric','ESaver100PercentGoalReachedBeforeGoalDateInterest',900003
    UNION ALL SELECT 'BatchGeneric','ESaver100PercentGoalReachedBeforeGoalDateLoyalty',900004
    UNION ALL SELECT 'BatchGeneric','ESaverNoActivityOverOneMonth',900005
    UNION ALL SELECT 'BatchGeneric','ESaverOneMonthLeftForGoalMaturity',900006
    UNION ALL SELECT 'BatchGeneric','ESaverNotOnTrackMonthlyReminder',900007
),
Actual AS
(
    SELECT n.EventType, n.EventSubType, n.AccountNumber
    FROM dbo.CBG_ESaverNotification n
    WHERE n.AccountNumber BETWEEN 900001 AND 900007
      AND CONVERT(date, n.BusinessDate) = @BusinessDate
)
SELECT 'MissingInActual' AS DiffType, e.*
FROM Expected e
LEFT JOIN Actual a
  ON a.EventType = e.EventType
 AND a.EventSubType = e.EventSubType
 AND a.AccountNumber = e.AccountNumber
WHERE a.EventType IS NULL

UNION ALL

SELECT 'UnexpectedInActual' AS DiffType, a.*
FROM Actual a
LEFT JOIN Expected e
  ON e.EventType = a.EventType
 AND e.EventSubType = a.EventSubType
 AND e.AccountNumber = a.AccountNumber
WHERE e.EventType IS NULL
ORDER BY DiffType, AccountNumber, EventSubType;

------------------------------------------------------------
-- SECTION 4.1: Inspect MAIN rows (counts/dates)
------------------------------------------------------------
SELECT
    n.EventType,
    n.EventSubType,
    n.AccountNumber,
    n.CustomerID,
    n.LastNotificationCount,
    n.LastNotificationSentDate,
    n.BusinessDate
FROM dbo.CBG_ESaverNotification n
WHERE n.AccountNumber BETWEEN 900001 AND 900007
  AND CONVERT(date, n.BusinessDate) = @BusinessDate
ORDER BY n.AccountNumber, n.EventSubType;

------------------------------------------------------------
-- SECTION 4.2: Assertions (should return 0 rows)
------------------------------------------------------------

-- (A) No more than 1 goal event per account per business day in MAIN (by design)
SELECT
    n.AccountNumber,
    GoalCnt = COUNT(*)
FROM dbo.CBG_ESaverNotification n
WHERE n.AccountNumber BETWEEN 900001 AND 900007
  AND CONVERT(date, n.BusinessDate) = @BusinessDate
  AND n.EventSubType IN
  (
    'ESaver50PercentGoalReached',
    'ESaver90PercentGoalReached',
    'ESaver100PercentGoalReachedBeforeGoalDateInterest',
    'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
  )
GROUP BY n.AccountNumber
HAVING COUNT(*) > 1;

-- (B) No account should have both 100% interest and loyalty in MAIN for same business date
SELECT
    n.AccountNumber
FROM dbo.CBG_ESaverNotification n
WHERE n.AccountNumber BETWEEN 900001 AND 900007
  AND CONVERT(date, n.BusinessDate) = @BusinessDate
  AND n.EventSubType IN
  (
    'ESaver100PercentGoalReachedBeforeGoalDateInterest',
    'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
  )
GROUP BY n.AccountNumber
HAVING COUNT(DISTINCT n.EventSubType) > 1;

PRINT 'Validation section completed. Review the Diff output above (it should be empty).';
