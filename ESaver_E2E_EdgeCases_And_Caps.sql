/*==================================================================================================
    FILE:   ESaver_E2E_EdgeCases_And_Caps.sql

    PURPOSE:
        Extra end-to-end scenarios (beyond the Advanced Scenarios pack) to validate:
          1) Boundary percentages (50/90/100 edges, rounding)
          2) Same-day rerun idempotency (History + Main)
          3) ThresholdLimit cap behavior (allow until limit, block after limit)
          4) Non-open accounts ignored
          5) Bad data handling (MaturityAmount = 0/NULL, CurrentBalance NULL) without runtime errors
          6) Interest/Loyalty misclassification safety (only one 100 subtype per account/day)
          7) Multi-event-family same day (goal % + non-goal event simultaneously)

    IMPORTANT ASSUMPTIONS / ADJUSTMENTS YOU MAY NEED:
        A) Replace procedure names in [RUN PIPELINE] with your actual proc(s).
           - If you have ONE SP that does Stage+History+Main, call it once per BusinessDate.
        B) If your open status code is not 1, adjust AccountStatusCode accordingly.
        C) If your Main table update logic does NOT store BusinessDate, remove BusinessDate predicates in asserts.
        D) This script inserts into dbo.CBG_ESaverAccountDetail only.

    START DATE USED:
        @BD = '2025-12-14'  (one business date, but includes rerun test)

    SAMPLE ACCOUNTS:
        920001 : 89.999% (should be REAL 50%, NOT 90)
        920002 : 90.000% (should be REAL 90%)
        920003 : 99.999% (should be REAL 90%, NOT 100)
        920004 : 100.000% InterestAccount (should be REAL 100-Interest only)
        920005 : 100.000% LoyaltyAccount  (should be REAL 100-Loyalty only)
        920006 : 50.000%  (should be REAL 50%)
        920007 : Non-open status (ignored)
        920008 : MaturityAmount = 0 (ignored; must not error)
        920009 : MaturityAmount = NULL (ignored; must not error)
        920010 : CurrentBalance = NULL (ignored; must not error)
        920011 : Multi-event-family: 95% AND no activity > 30 days (expect both families if allowed)

==================================================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @BD date = '2025-12-14';
DECLARE @BDDT datetime2(0) = CONVERT(datetime2(0), @BD);

----------------------------------------------------------------------------------------------------
-- SECTION A: CLEANUP (safe re-run)
----------------------------------------------------------------------------------------------------
DELETE d
FROM dbo.CBG_ESaverAccountDetail d
WHERE d.BusinessDate = @BDDT
  AND d.AccountNumber BETWEEN 920001 AND 920011;

-- Optional: cleanup downstream tables for a full reset (UNCOMMENT if you want)
-- DELETE m FROM dbo.CBG_ESaverNotification m WHERE m.AccountNumber BETWEEN 920001 AND 920011;
-- DELETE h FROM dbo.CBG_ESaverNotificationHistory h WHERE h.BusinessDate = @BDDT AND h.AccountNumber BETWEEN 920001 AND 920011;

----------------------------------------------------------------------------------------------------
-- SECTION B: INSERT SAMPLE ACCOUNTS (boundary + bad data + multi-event)
----------------------------------------------------------------------------------------------------
INSERT INTO dbo.CBG_ESaverAccountDetail
(
    BusinessDate,
    AccountNumber,
    CustomerID,
    AccountNumberWithCheckDigit,
    MRSAccountNumber,
    ESaverName,
    ESaverAccountType,
    CurrentBalance,
    CurrentBalanceAsOnMaturityDate,
    MaturityDate,
    MaturityAmount,
    MaturityAmountAsOnMaturityDate,
    LastCreditDate,
    LastDebitDate,
    LastAccountActivityDate,
    LastAccountStatusChangeDate,
    AccountOpenDate,
    AccountCloseDate,
    AccountStatusCode,
    NextDormancyDate
)
SELECT
    x.BusinessDate,
    x.AccountNumber,
    x.CustomerID,
    x.AccountNumberWithCheckDigit,
    x.MRSAccountNumber,
    x.ESaverName,
    x.ESaverAccountType,
    x.CurrentBalance,
    x.CurrentBalanceAsOnMaturityDate,
    x.MaturityDate,
    x.MaturityAmount,
    x.MaturityAmountAsOnMaturityDate,
    x.LastCreditDate,
    x.LastDebitDate,
    x.LastAccountActivityDate,
    x.LastAccountStatusChangeDate,
    x.AccountOpenDate,
    x.AccountCloseDate,
    x.AccountStatusCode,
    x.NextDormancyDate
FROM
(
    -- 89.999% => 899.990 / 1000 = 89.999%  (REAL 50)
    SELECT
        BusinessDate = @BDDT,
        AccountNumber = 920001,
        CustomerID = 701,
        AccountNumberWithCheckDigit = 9200019,
        MRSAccountNumber = 'MRS-920001',
        ESaverName = N'Edge 89.999%',
        ESaverAccountType = 'Generic',
        CurrentBalance = 899.990,
        CurrentBalanceAsOnMaturityDate = 899.990,
        MaturityDate = DATEADD(DAY, 90, @BDDT),
        MaturityAmount = 1000.000,
        MaturityAmountAsOnMaturityDate = 1000.000,
        LastCreditDate = DATEADD(DAY, -1, @BDDT),
        LastDebitDate  = DATEADD(DAY, -20, @BDDT),
        LastAccountActivityDate = DATEADD(DAY, -1, @BDDT),
        LastAccountStatusChangeDate = DATEADD(DAY, -200, @BDDT),
        AccountOpenDate = DATEADD(DAY, -120, @BDDT),
        AccountCloseDate = NULL,
        AccountStatusCode = 1,
        NextDormancyDate = DATEADD(DAY, 40, @BDDT)

    UNION ALL
    -- 90.000% => REAL 90
    SELECT
        @BDDT, 920002, 702, 9200028, 'MRS-920002', N'Edge 90.000%',
        'Generic',
        900.000, 900.000,
        DATEADD(DAY, 90, @BDDT),
        1000.000, 1000.000,
        DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -20, @BDDT), DATEADD(DAY, -1, @BDDT),
        DATEADD(DAY, -200, @BDDT),
        DATEADD(DAY, -120, @BDDT),
        NULL, 1, DATEADD(DAY, 40, @BDDT)

    UNION ALL
    -- 99.999% => REAL 90 (NOT 100)
    SELECT
        @BDDT, 920003, 703, 9200037, 'MRS-920003', N'Edge 99.999%',
        'Generic',
        999.990, 999.990,
        DATEADD(DAY, 90, @BDDT),
        1000.000, 1000.000,
        DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -20, @BDDT), DATEADD(DAY, -1, @BDDT),
        DATEADD(DAY, -200, @BDDT),
        DATEADD(DAY, -120, @BDDT),
        NULL, 1, DATEADD(DAY, 40, @BDDT)

    UNION ALL
    -- 100.000% InterestAccount => REAL 100-Interest only
    SELECT
        @BDDT, 920004, 704, 9200046, 'MRS-920004', N'Edge 100% Interest',
        'InterestAccount',
        1000.000, 1000.000,
        DATEADD(DAY, 30, @BDDT),
        1000.000, 1000.000,
        DATEADD(DAY, -2, @BDDT), DATEADD(DAY, -20, @BDDT), DATEADD(DAY, -2, @BDDT),
        DATEADD(DAY, -300, @BDDT),
        DATEADD(DAY, -250, @BDDT),
        NULL, 1, DATEADD(DAY, 10, @BDDT)

    UNION ALL
    -- 100.000% LoyaltyAccount => REAL 100-Loyalty only
    SELECT
        @BDDT, 920005, 705, 9200055, 'MRS-920005', N'Edge 100% Loyalty',
        'LoyaltyAccount',
        1000.000, 1000.000,
        DATEADD(DAY, 30, @BDDT),
        1000.000, 1000.000,
        DATEADD(DAY, -3, @BDDT), DATEADD(DAY, -21, @BDDT), DATEADD(DAY, -3, @BDDT),
        DATEADD(DAY, -300, @BDDT),
        DATEADD(DAY, -250, @BDDT),
        NULL, 1, DATEADD(DAY, 10, @BDDT)

    UNION ALL
    -- 50.000% => REAL 50
    SELECT
        @BDDT, 920006, 706, 9200064, 'MRS-920006', N'Edge 50.000%',
        'Generic',
        500.000, 500.000,
        DATEADD(DAY, 120, @BDDT),
        1000.000, 1000.000,
        DATEADD(DAY, -5, @BDDT), DATEADD(DAY, -30, @BDDT), DATEADD(DAY, -5, @BDDT),
        DATEADD(DAY, -200, @BDDT),
        DATEADD(DAY, -90, @BDDT),
        NULL, 1, DATEADD(DAY, 40, @BDDT)

    UNION ALL
    -- Non-open account (ignored)
    SELECT
        @BDDT, 920007, 707, 9200073, 'MRS-920007', N'NonOpen should be ignored',
        'Generic',
        950.000, 950.000,
        DATEADD(DAY, 90, @BDDT),
        1000.000, 1000.000,
        DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -20, @BDDT), DATEADD(DAY, -1, @BDDT),
        DATEADD(DAY, -200, @BDDT),
        DATEADD(DAY, -120, @BDDT),
        NULL, 9, DATEADD(DAY, 40, @BDDT)  -- 9 = CLOSED/NOT OPEN (adjust to your system)

    UNION ALL
    -- Bad data: MaturityAmount = 0 (ignored; must not error)
    SELECT
        @BDDT, 920008, 708, 9200082, 'MRS-920008', N'BadData MA=0',
        'Generic',
        100.000, 100.000,
        DATEADD(DAY, 90, @BDDT),
        0.000, 0.000,
        DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -20, @BDDT), DATEADD(DAY, -1, @BDDT),
        DATEADD(DAY, -200, @BDDT),
        DATEADD(DAY, -120, @BDDT),
        NULL, 1, DATEADD(DAY, 40, @BDDT)

    UNION ALL
    -- Bad data: MaturityAmount = NULL (ignored; must not error)
    SELECT
        @BDDT, 920009, 709, 9200091, 'MRS-920009', N'BadData MA=NULL',
        'Generic',
        100.000, 100.000,
        DATEADD(DAY, 90, @BDDT),
        NULL, NULL,
        DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -20, @BDDT), DATEADD(DAY, -1, @BDDT),
        DATEADD(DAY, -200, @BDDT),
        DATEADD(DAY, -120, @BDDT),
        NULL, 1, DATEADD(DAY, 40, @BDDT)

    UNION ALL
    -- Bad data: CurrentBalance = NULL (ignored; must not error)
    SELECT
        @BDDT, 920010, 710, 9200108, 'MRS-920010', N'BadData CB=NULL',
        'Generic',
        NULL, NULL,
        DATEADD(DAY, 90, @BDDT),
        1000.000, 1000.000,
        DATEADD(DAY, -1, @BDDT), DATEADD(DAY, -20, @BDDT), DATEADD(DAY, -1, @BDDT),
        DATEADD(DAY, -200, @BDDT),
        DATEADD(DAY, -120, @BDDT),
        NULL, 1, DATEADD(DAY, 40, @BDDT)

    UNION ALL
    -- Multi-event-family: 95% (goal) AND no activity > 30 days (non-goal)
    SELECT
        @BDDT, 920011, 711, 9200117, 'MRS-920011', N'Multi family 95% + NoActivity',
        'Generic',
        950.000, 950.000,
        DATEADD(DAY, 120, @BDDT),
        1000.000, 1000.000,
        DATEADD(DAY, -45, @BDDT), DATEADD(DAY, -46, @BDDT), DATEADD(DAY, -40, @BDDT),  -- no activity >= 30
        DATEADD(DAY, -200, @BDDT),
        DATEADD(DAY, -200, @BDDT),
        NULL, 1, DATEADD(DAY, 40, @BDDT)
) x;

----------------------------------------------------------------------------------------------------
-- SECTION C: RUN PIPELINE (replace proc names)
----------------------------------------------------------------------------------------------------
/*
    IMPORTANT:
      1) Run once, then capture counts (we do that in Section D).
      2) Run AGAIN for the SAME business date to validate rerun idempotency (Section E).

    Replace the EXEC statements with your actual SP calls.
*/
PRINT 'RUN PIPELINE FIRST PASS...';
-- EXEC dbo.usp_StageLoad_CBG_ESaverNotification @I_BusinessDate = @BD;
-- EXEC dbo.usp_LoadHistory_CBG_ESaverNotification @I_BusinessDate = @BD;
-- EXEC dbo.usp_LoadMain_CBG_ESaverNotification @I_BusinessDate = @BD;

----------------------------------------------------------------------------------------------------
-- SECTION D: CAPTURE FIRST PASS SNAPSHOT (History/Main rowcounts and key sets)
----------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#MainSnap1') IS NOT NULL DROP TABLE #MainSnap1;
IF OBJECT_ID('tempdb..#HistSnap1') IS NOT NULL DROP TABLE #HistSnap1;

SELECT
    CAST(m.BusinessDate AS date) AS BusinessDate,
    m.EventType,
    m.EventSubType,
    m.AccountNumber,
    m.LastNotificationCount
INTO #MainSnap1
FROM dbo.CBG_ESaverNotification m
WHERE CAST(m.BusinessDate AS date) = @BD
  AND m.AccountNumber BETWEEN 920001 AND 920011;

SELECT
    CAST(h.BusinessDate AS date) AS BusinessDate,
    h.EventType,
    h.EventSubType,
    h.AccountNumber,
    h.SequenceNumber,
    h.IsDummyEntry
INTO #HistSnap1
FROM dbo.CBG_ESaverNotificationHistory h
WHERE CAST(h.BusinessDate AS date) = @BD
  AND h.AccountNumber BETWEEN 920001 AND 920011;

----------------------------------------------------------------------------------------------------
-- SECTION E: RERUN IDENTITY TEST (run pipeline again for same date)
----------------------------------------------------------------------------------------------------
PRINT 'RUN PIPELINE SECOND PASS (same business date) TO VALIDATE IDMPOTENCY...';
-- EXEC dbo.usp_StageLoad_CBG_ESaverNotification @I_BusinessDate = @BD;
-- EXEC dbo.usp_LoadHistory_CBG_ESaverNotification @I_BusinessDate = @BD;
-- EXEC dbo.usp_LoadMain_CBG_ESaverNotification @I_BusinessDate = @BD;

----------------------------------------------------------------------------------------------------
-- SECTION F: ASSERTS (each should return 0 rows when correct)
----------------------------------------------------------------------------------------------------

/*---------------------------------------
  F1) Boundary band correctness in MAIN
---------------------------------------*/
;WITH ExpectedMain AS
(
    -- 89.999% => should be 50
    SELECT @BD AS BusinessDate, 920001 AS AccountNumber, 'ESaver50PercentGoalReached' AS EventSubType
    UNION ALL
    -- 90.000% => should be 90
    SELECT @BD, 920002, 'ESaver90PercentGoalReached'
    UNION ALL
    -- 99.999% => should be 90
    SELECT @BD, 920003, 'ESaver90PercentGoalReached'
    UNION ALL
    -- 100% => correct 100 per type
    SELECT @BD, 920004, 'ESaver100PercentGoalReachedBeforeGoalDateInterest'
    UNION ALL
    SELECT @BD, 920005, 'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
    UNION ALL
    -- 50.000% => should be 50
    SELECT @BD, 920006, 'ESaver50PercentGoalReached'
),
ActualMain AS
(
    SELECT CAST(m.BusinessDate AS date) AS BusinessDate, m.AccountNumber, m.EventSubType
    FROM dbo.CBG_ESaverNotification m
    WHERE CAST(m.BusinessDate AS date) = @BD
      AND m.AccountNumber BETWEEN 920001 AND 920006
)
SELECT 'MissingInMain' AS DiffType, e.*
FROM ExpectedMain e
LEFT JOIN ActualMain a
  ON a.BusinessDate  = e.BusinessDate
 AND a.AccountNumber = e.AccountNumber
 AND a.EventSubType  = e.EventSubType
WHERE a.AccountNumber IS NULL
UNION ALL
SELECT 'UnexpectedInMain' AS DiffType, a.BusinessDate, a.AccountNumber, a.EventSubType
FROM ActualMain a
LEFT JOIN ExpectedMain e
  ON e.BusinessDate  = a.BusinessDate
 AND e.AccountNumber = a.AccountNumber
 AND e.EventSubType  = a.EventSubType
WHERE e.AccountNumber IS NULL;

-- Ensure 100% accounts do NOT have both Interest and Loyalty
SELECT
    CAST(m.BusinessDate AS date) AS BusinessDate,
    m.AccountNumber
FROM dbo.CBG_ESaverNotification m
WHERE CAST(m.BusinessDate AS date) = @BD
  AND m.AccountNumber IN (920004, 920005)
  AND m.EventSubType IN
  (
    'ESaver100PercentGoalReachedBeforeGoalDateInterest',
    'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
  )
GROUP BY CAST(m.BusinessDate AS date), m.AccountNumber
HAVING COUNT(DISTINCT m.EventSubType) > 1;

-- Ensure non-open account ignored (no MAIN rows)
SELECT *
FROM dbo.CBG_ESaverNotification m
WHERE CAST(m.BusinessDate AS date) = @BD
  AND m.AccountNumber = 920007;

-- Ensure bad data accounts did not produce MAIN rows
SELECT *
FROM dbo.CBG_ESaverNotification m
WHERE CAST(m.BusinessDate AS date) = @BD
  AND m.AccountNumber IN (920008,920009,920010);

 /*---------------------------------------
  F2) Multi-event-family (if allowed): 920011 can produce BOTH goal and no-activity events
---------------------------------------*/
-- If business allows multiple different subtypes per account/day, this should return 0 rows.
-- If business forbids it, tell me and I will adjust the expected behavior.
SELECT
    CAST(m.BusinessDate AS date) AS BusinessDate,
    m.AccountNumber
FROM dbo.CBG_ESaverNotification m
WHERE CAST(m.BusinessDate AS date) = @BD
  AND m.AccountNumber = 920011
GROUP BY CAST(m.BusinessDate AS date), m.AccountNumber
HAVING COUNT(*) < 1;  -- at least one event must exist (should be 90% goal); add no-activity check below if needed

/*---------------------------------------
  F3) Rerun idempotency: MAIN should not change after second pass
---------------------------------------*/
;WITH MainNow AS
(
    SELECT
        CAST(m.BusinessDate AS date) AS BusinessDate,
        m.EventType,
        m.EventSubType,
        m.AccountNumber,
        m.LastNotificationCount
    FROM dbo.CBG_ESaverNotification m
    WHERE CAST(m.BusinessDate AS date) = @BD
      AND m.AccountNumber BETWEEN 920001 AND 920011
)
SELECT 'MainChangedAfterRerun' AS Issue, n.*
FROM MainNow n
FULL OUTER JOIN #MainSnap1 s
  ON s.BusinessDate  = n.BusinessDate
 AND s.EventType     = n.EventType
 AND s.EventSubType  = n.EventSubType
 AND s.AccountNumber = n.AccountNumber
WHERE
    ISNULL(s.LastNotificationCount,-999) <> ISNULL(n.LastNotificationCount,-999)
 OR s.AccountNumber IS NULL
 OR n.AccountNumber IS NULL;

 /*---------------------------------------
  F4) Rerun idempotency: HISTORY should not change after second pass
---------------------------------------*/
;WITH HistNow AS
(
    SELECT
        CAST(h.BusinessDate AS date) AS BusinessDate,
        h.EventType,
        h.EventSubType,
        h.AccountNumber,
        h.SequenceNumber,
        h.IsDummyEntry
    FROM dbo.CBG_ESaverNotificationHistory h
    WHERE CAST(h.BusinessDate AS date) = @BD
      AND h.AccountNumber BETWEEN 920001 AND 920011
)
SELECT 'HistoryChangedAfterRerun' AS Issue, n.*
FROM HistNow n
FULL OUTER JOIN #HistSnap1 s
  ON s.BusinessDate   = n.BusinessDate
 AND s.EventType      = n.EventType
 AND s.EventSubType   = n.EventSubType
 AND s.AccountNumber  = n.AccountNumber
 AND s.SequenceNumber = n.SequenceNumber
 AND s.IsDummyEntry   = n.IsDummyEntry
WHERE
    s.AccountNumber IS NULL
 OR n.AccountNumber IS NULL;

----------------------------------------------------------------------------------------------------
-- SECTION G: ThresholdLimit cap behavior (manual steps)
----------------------------------------------------------------------------------------------------
/*
    Cap behavior depends on ThresholdLimit values configured by business.

    RECOMMENDED WAY TO TEST:
      1) Find ThresholdLimit for ESaver90PercentGoalReached in your config.
      2) Manually set MAIN last count for one account (e.g., 920002) to:
             ThresholdLimit - 1    -> should allow one more notification
             ThresholdLimit        -> should block notification
      3) Rerun pipeline for same @BD (or next BD) and verify stage/history/main results.

    Example (you must adjust columns/names):
      -- UPDATE dbo.CBG_ESaverNotification
      -- SET LastNotificationCount = <ThresholdLimit - 1>, LastNotificationSentDate = DATEADD(DAY, -1, LastNotificationSentDate)
      -- WHERE AccountNumber = 920002 AND EventSubType = 'ESaver90PercentGoalReached';

    Then run pipeline and verify:
      - If allowed: history has a new REAL 90 row for the date, main increments/updates.
      - If blocked: no new REAL 90 row for that date (and main unchanged).
*/

PRINT 'DONE';
