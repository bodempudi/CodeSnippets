/*==================================================================================================
    FILE:   ESaver_E2E_Advanced_Scenarios.sql
    PURPOSE:
        End-to-end scenario pack to validate precedence + suppression for Goal % events:
            - Direct 90% reached (same day)
            - Direct 100% Interest reached (same day)
            - Direct 100% Loyalty reached (same day)
            - Cross-day progression: 90% -> 100% (Interest) and 90% -> 100% (Loyalty)
            - Cross-day stability: same band repeated (e.g., 90% again next day)
            - Confirm lower-precedence suppression via dummy rows in History, and "real only" in Main

    IMPORTANT NOTES / ASSUMPTIONS (adjust if different in your system):
        1) dbo.CBG_ESaverAccountDetail has 1 row per (BusinessDate, AccountNumber).
        2) Stage is truncated/rebuilt each run.
        3) History has unique key (EventType, EventSubType, AccountNumber, SequenceNumber) and keeps dummy rows too.
        4) Main table dbo.CBG_ESaverNotification should be updated using ONLY IsDummyEntry='N' rows.
        5) Your 90% block uses: CurrentBalancePercentage >= 90 AND < 100   (prevents 100% accounts from entering 90-block)
        6) You have two separate 100% blocks:
                - ESaver100PercentGoalReachedBeforeGoalDateInterest (InterestAccount)
                - ESaver100PercentGoalReachedBeforeGoalDateLoyalty  (LoyaltyAccount)

    HOW TO USE:
        Step 0) Replace procedure names in Section [RUN PIPELINE] with your actual procs (if needed).
        Step 1) Run this file.
        Step 2) Review the ASSERT queries under [EXPECTED RESULTS] – each should return 0 rows when correct.

==================================================================================================*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @BD1 date = '2025-12-12';
DECLARE @BD2 date = '2025-12-13';

DECLARE @BD1DT datetime2(0) = CONVERT(datetime2(0), @BD1);
DECLARE @BD2DT datetime2(0) = CONVERT(datetime2(0), @BD2);

----------------------------------------------------------------------------------------------------
-- SECTION A: CLEANUP (safe re-run)
----------------------------------------------------------------------------------------------------
/*
    We delete ONLY our sample accounts for the two business dates.
    Adjust account ranges if needed.
*/
DELETE d
FROM dbo.CBG_ESaverAccountDetail d
WHERE d.BusinessDate IN (@BD1DT, @BD2DT)
  AND d.AccountNumber BETWEEN 910001 AND 910010;

-- Optional cleanup of Main for these sample accounts/days (UNCOMMENT if you want full reset)
-- DELETE m
-- FROM dbo.CBG_ESaverNotification m
-- WHERE m.AccountNumber BETWEEN 910001 AND 910010;

-- Optional cleanup of History for these sample accounts/days (UNCOMMENT if you want full reset)
-- DELETE h
-- FROM dbo.CBG_ESaverNotificationHistory h
-- WHERE h.BusinessDate IN (@BD1DT, @BD2DT)
--   AND h.AccountNumber BETWEEN 910001 AND 910010;

----------------------------------------------------------------------------------------------------
-- SECTION B: INSERT SAMPLE ACCOUNTS (covers direct and cross-day scenarios)
----------------------------------------------------------------------------------------------------
/*
    ACCOUNT DESIGN:
      910001 - Direct 90% reached on BD1 (95%) => Expect REAL 90, DUMMY 50 in History
      910002 - Direct 100% Interest on BD1 (110%) => Expect REAL 100-Interest, DUMMY 90 & 50 in History
      910003 - Direct 100% Loyalty  on BD1 (105%) => Expect REAL 100-Loyalty,  DUMMY 90 & 50 in History

      910004 - Cross-day: BD1=95% (90 real), BD2=110% Interest (100 real) => BD2 should produce 100-Interest real and dummy 90/50
      910005 - Cross-day: BD1=95% (90 real), BD2=105% Loyalty  (100 real) => BD2 should produce 100-Loyalty real and dummy 90/50

      910006 - Cross-day stability: BD1=95% (90 real), BD2=96% (90 again) => BD2 should produce 90 real again (subject to ThresholdLimit)
               (Used to validate your "unlimited" or "ThresholdLimit" business rule)

    BALANCE MODEL:
      MaturityAmount = 1000 for all, so percentage is easy: 950=95%, 1100=110%, 1050=105%.
*/
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
    -- =========================
    -- DAY 1 (BD1)
    -- =========================
    SELECT
        BusinessDate = @BD1DT,
        AccountNumber = 910001,
        CustomerID = 601,
        AccountNumberWithCheckDigit = 9100019,
        MRSAccountNumber = 'MRS-910001',
        ESaverName = N'Direct 90% Day1',
        ESaverAccountType = 'Generic',
        CurrentBalance = 950.000,
        CurrentBalanceAsOnMaturityDate = 950.000,
        MaturityAmount = 1000.000,
        MaturityAmountAsOnMaturityDate = 1000.000,
        MaturityDate = DATEADD(DAY, 60, @BD1DT),
        LastCreditDate = DATEADD(DAY, -1, @BD1DT),
        LastDebitDate = DATEADD(DAY, -5, @BD1DT),
        LastAccountActivityDate = DATEADD(DAY, -1, @BD1DT),
        LastAccountStatusChangeDate = DATEADD(DAY, -200, @BD1DT),
        AccountOpenDate = DATEADD(DAY, -120, @BD1DT),
        AccountCloseDate = NULL,
        AccountStatusCode = 1,
        NextDormancyDate = DATEADD(DAY, 40, @BD1DT)

    UNION ALL
    SELECT
        @BD1DT, 910002, 602, 9100028, 'MRS-910002', N'Direct 100% Interest Day1',
        'InterestAccount',
        1100.000,1100.000,
        DATEADD(DAY, 45, @BD1DT),
        1000.000,1000.000,
        DATEADD(DAY, -2, @BD1DT), DATEADD(DAY, -10, @BD1DT), DATEADD(DAY, -2, @BD1DT),
        DATEADD(DAY, -300, @BD1DT),
        DATEADD(DAY, -250, @BD1DT),
        NULL, 1, DATEADD(DAY, 10, @BD1DT)

    UNION ALL
    SELECT
        @BD1DT, 910003, 603, 9100037, 'MRS-910003', N'Direct 100% Loyalty Day1',
        'LoyaltyAccount',
        1050.000,1050.000,
        DATEADD(DAY, 45, @BD1DT),
        1000.000,1000.000,
        DATEADD(DAY, -3, @BD1DT), DATEADD(DAY, -12, @BD1DT), DATEADD(DAY, -3, @BD1DT),
        DATEADD(DAY, -280, @BD1DT),
        DATEADD(DAY, -260, @BD1DT),
        NULL, 1, DATEADD(DAY, 15, @BD1DT)

    UNION ALL
    -- Cross-day accounts - Day1 snapshot (90 band)
    SELECT
        @BD1DT, 910004, 604, 9100046, 'MRS-910004', N'CrossDay 90->100 Interest',
        'InterestAccount',
        950.000,950.000,
        DATEADD(DAY, 75, @BD1DT),
        1000.000,1000.000,
        DATEADD(DAY, -1, @BD1DT), DATEADD(DAY, -8, @BD1DT), DATEADD(DAY, -1, @BD1DT),
        DATEADD(DAY, -220, @BD1DT),
        DATEADD(DAY, -180, @BD1DT),
        NULL, 1, DATEADD(DAY, 25, @BD1DT)

    UNION ALL
    SELECT
        @BD1DT, 910005, 605, 9100055, 'MRS-910005', N'CrossDay 90->100 Loyalty',
        'LoyaltyAccount',
        950.000,950.000,
        DATEADD(DAY, 75, @BD1DT),
        1000.000,1000.000,
        DATEADD(DAY, -1, @BD1DT), DATEADD(DAY, -9, @BD1DT), DATEADD(DAY, -1, @BD1DT),
        DATEADD(DAY, -240, @BD1DT),
        DATEADD(DAY, -200, @BD1DT),
        NULL, 1, DATEADD(DAY, 25, @BD1DT)

    UNION ALL
    SELECT
        @BD1DT, 910006, 606, 9100064, 'MRS-910006', N'CrossDay 90->90',
        'Generic',
        950.000,950.000,
        DATEADD(DAY, 100, @BD1DT),
        1000.000,1000.000,
        DATEADD(DAY, -1, @BD1DT), DATEADD(DAY, -20, @BD1DT), DATEADD(DAY, -1, @BD1DT),
        DATEADD(DAY, -150, @BD1DT),
        DATEADD(DAY, -120, @BD1DT),
        NULL, 1, DATEADD(DAY, 45, @BD1DT)

    -- =========================
    -- DAY 2 (BD2) - only for cross-day accounts
    -- =========================
    UNION ALL
    SELECT
        @BD2DT, 910004, 604, 9100046, 'MRS-910004', N'CrossDay 90->100 Interest (Day2)',
        'InterestAccount',
        1100.000,1100.000,
        DATEADD(DAY, 74, @BD2DT),
        1000.000,1000.000,
        DATEADD(DAY, -1, @BD2DT), DATEADD(DAY, -8, @BD2DT), DATEADD(DAY, -1, @BD2DT),
        DATEADD(DAY, -220, @BD2DT),
        DATEADD(DAY, -179, @BD2DT),
        NULL, 1, DATEADD(DAY, 25, @BD2DT)

    UNION ALL
    SELECT
        @BD2DT, 910005, 605, 9100055, 'MRS-910005', N'CrossDay 90->100 Loyalty (Day2)',
        'LoyaltyAccount',
        1050.000,1050.000,
        DATEADD(DAY, 74, @BD2DT),
        1000.000,1000.000,
        DATEADD(DAY, -1, @BD2DT), DATEADD(DAY, -9, @BD2DT), DATEADD(DAY, -1, @BD2DT),
        DATEADD(DAY, -240, @BD2DT),
        DATEADD(DAY, -199, @BD2DT),
        NULL, 1, DATEADD(DAY, 25, @BD2DT)

    UNION ALL
    SELECT
        @BD2DT, 910006, 606, 9100064, 'MRS-910006', N'CrossDay 90->90 (Day2)',
        'Generic',
        960.000,960.000,
        DATEADD(DAY, 99, @BD2DT),
        1000.000,1000.000,
        DATEADD(DAY, -1, @BD2DT), DATEADD(DAY, -20, @BD2DT), DATEADD(DAY, -1, @BD2DT),
        DATEADD(DAY, -150, @BD2DT),
        DATEADD(DAY, -119, @BD2DT),
        NULL, 1, DATEADD(DAY, 45, @BD2DT)
) x;

----------------------------------------------------------------------------------------------------
-- SECTION C: RUN PIPELINE (replace proc names if needed)
----------------------------------------------------------------------------------------------------
/*
    Replace the proc names below with your actual end-to-end execution order.
    If you have ONE SP that does Stage+History+Main, call it once per date.

    Example placeholders:
        dbo.usp_StageLoad_CBG_ESaverNotification
        dbo.usp_LoadHistory_CBG_ESaverNotification
        dbo.usp_LoadMain_CBG_ESaverNotification
*/

PRINT 'RUN PIPELINE FOR BD1...';
-- EXEC dbo.usp_StageLoad_CBG_ESaverNotification @I_BusinessDate = @BD1;
-- EXEC dbo.usp_LoadHistory_CBG_ESaverNotification @I_BusinessDate = @BD1;
-- EXEC dbo.usp_LoadMain_CBG_ESaverNotification @I_BusinessDate = @BD1;

PRINT 'RUN PIPELINE FOR BD2...';
-- EXEC dbo.usp_StageLoad_CBG_ESaverNotification @I_BusinessDate = @BD2;
-- EXEC dbo.usp_LoadHistory_CBG_ESaverNotification @I_BusinessDate = @BD2;
-- EXEC dbo.usp_LoadMain_CBG_ESaverNotification @I_BusinessDate = @BD2;

----------------------------------------------------------------------------------------------------
-- SECTION D: EXPECTED RESULTS (ASSERT QUERIES) - each should return 0 rows when correct
----------------------------------------------------------------------------------------------------

/*
    Expected REAL (N) events in MAIN per day:

    BD1:
        910001 -> ESaver90PercentGoalReached   (real)
        910002 -> ESaver100PercentGoalReachedBeforeGoalDateInterest (real)
        910003 -> ESaver100PercentGoalReachedBeforeGoalDateLoyalty  (real)
        910004 -> ESaver90PercentGoalReached   (real)
        910005 -> ESaver90PercentGoalReached   (real)
        910006 -> ESaver90PercentGoalReached   (real)

    BD2:
        910004 -> ESaver100PercentGoalReachedBeforeGoalDateInterest (real)
        910005 -> ESaver100PercentGoalReachedBeforeGoalDateLoyalty  (real)
        910006 -> ESaver90PercentGoalReached   (real)  [subject to ThresholdLimit logic]

    Expected DUMMY suppression rows exist in HISTORY (not in MAIN):
        For any REAL 90: dummy 50 should exist same day in history
        For any REAL 100: dummy 90 and 50 should exist same day in history
*/

------------------------------------------------------------
-- D1) MAIN: Ensure no account has more than one REAL goal event per business date
------------------------------------------------------------
SELECT
    m.BusinessDate,
    m.AccountNumber,
    RealCnt = COUNT(*)
FROM dbo.CBG_ESaverNotification m
WHERE CONVERT(date, m.BusinessDate) IN (@BD1, @BD2)
  AND m.AccountNumber BETWEEN 910001 AND 910006
  AND m.EventSubType IN
  (
    'ESaver50PercentGoalReached',
    'ESaver90PercentGoalReached',
    'ESaver100PercentGoalReachedBeforeGoalDateInterest',
    'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
  )
GROUP BY m.BusinessDate, m.AccountNumber
HAVING COUNT(*) > 1;

------------------------------------------------------------
-- D2) MAIN: Ensure no account has BOTH 100 Interest and 100 Loyalty (any day)
------------------------------------------------------------
SELECT
    m.BusinessDate,
    m.AccountNumber
FROM dbo.CBG_ESaverNotification m
WHERE CONVERT(date, m.BusinessDate) IN (@BD1, @BD2)
  AND m.AccountNumber BETWEEN 910001 AND 910006
  AND m.EventSubType IN
  (
    'ESaver100PercentGoalReachedBeforeGoalDateInterest',
    'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
  )
GROUP BY m.BusinessDate, m.AccountNumber
HAVING COUNT(DISTINCT m.EventSubType) > 1;

------------------------------------------------------------
-- D3) MAIN: Ensure BD1 expected set exists (missing rows)
------------------------------------------------------------
;WITH ExpectedMain AS
(
    SELECT CAST(@BD1 AS date) AS BusinessDate, 910001 AS AccountNumber, 'ESaver90PercentGoalReached' AS EventSubType
    UNION ALL SELECT @BD1, 910002, 'ESaver100PercentGoalReachedBeforeGoalDateInterest'
    UNION ALL SELECT @BD1, 910003, 'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
    UNION ALL SELECT @BD1, 910004, 'ESaver90PercentGoalReached'
    UNION ALL SELECT @BD1, 910005, 'ESaver90PercentGoalReached'
    UNION ALL SELECT @BD1, 910006, 'ESaver90PercentGoalReached'

    UNION ALL
    SELECT CAST(@BD2 AS date), 910004, 'ESaver100PercentGoalReachedBeforeGoalDateInterest'
    UNION ALL SELECT @BD2, 910005, 'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
    UNION ALL SELECT @BD2, 910006, 'ESaver90PercentGoalReached'
),
ActualMain AS
(
    SELECT CAST(m.BusinessDate AS date) AS BusinessDate, m.AccountNumber, m.EventSubType
    FROM dbo.CBG_ESaverNotification m
    WHERE CAST(m.BusinessDate AS date) IN (@BD1, @BD2)
      AND m.AccountNumber BETWEEN 910001 AND 910006
)
SELECT 'MissingInMain' AS DiffType, e.*
FROM ExpectedMain e
LEFT JOIN ActualMain a
  ON a.BusinessDate  = e.BusinessDate
 AND a.AccountNumber = e.AccountNumber
 AND a.EventSubType  = e.EventSubType
WHERE a.AccountNumber IS NULL;

------------------------------------------------------------
-- D4) HISTORY: For REAL 90, ensure dummy 50 exists same day
------------------------------------------------------------
SELECT
    h90.BusinessDate,
    h90.AccountNumber
FROM dbo.CBG_ESaverNotificationHistory h90
WHERE CAST(h90.BusinessDate AS date) IN (@BD1, @BD2)
  AND h90.AccountNumber BETWEEN 910001 AND 910006
  AND h90.EventSubType = 'ESaver90PercentGoalReached'
  AND h90.IsDummyEntry = 'N'
  AND NOT EXISTS
  (
      SELECT 1
      FROM dbo.CBG_ESaverNotificationHistory h50
      WHERE h50.BusinessDate  = h90.BusinessDate
        AND h50.AccountNumber = h90.AccountNumber
        AND h50.EventSubType  = 'ESaver50PercentGoalReached'
        AND h50.IsDummyEntry  = 'Y'
  );

------------------------------------------------------------
-- D5) HISTORY: For REAL 100, ensure dummy 90 and dummy 50 exist same day
------------------------------------------------------------
SELECT
    h100.BusinessDate,
    h100.AccountNumber,
    h100.EventSubType
FROM dbo.CBG_ESaverNotificationHistory h100
WHERE CAST(h100.BusinessDate AS date) IN (@BD1, @BD2)
  AND h100.AccountNumber BETWEEN 910001 AND 910006
  AND h100.IsDummyEntry = 'N'
  AND h100.EventSubType IN
  (
    'ESaver100PercentGoalReachedBeforeGoalDateInterest',
    'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
  )
  AND
  (
      NOT EXISTS
      (
          SELECT 1
          FROM dbo.CBG_ESaverNotificationHistory h90
          WHERE h90.BusinessDate  = h100.BusinessDate
            AND h90.AccountNumber = h100.AccountNumber
            AND h90.EventSubType  = 'ESaver90PercentGoalReached'
            AND h90.IsDummyEntry  = 'Y'
      )
      OR
      NOT EXISTS
      (
          SELECT 1
          FROM dbo.CBG_ESaverNotificationHistory h50
          WHERE h50.BusinessDate  = h100.BusinessDate
            AND h50.AccountNumber = h100.AccountNumber
            AND h50.EventSubType  = 'ESaver50PercentGoalReached'
            AND h50.IsDummyEntry  = 'Y'
      )
  );

------------------------------------------------------------
-- D6) OPTIONAL: show what got created in MAIN for quick human review
------------------------------------------------------------
SELECT
    CAST(m.BusinessDate AS date) AS BusinessDate,
    m.AccountNumber,
    m.EventType,
    m.EventSubType,
    m.LastNotificationCount,
    m.LastNotificationSentDate
FROM dbo.CBG_ESaverNotification m
WHERE CAST(m.BusinessDate AS date) IN (@BD1, @BD2)
  AND m.AccountNumber BETWEEN 910001 AND 910006
ORDER BY CAST(m.BusinessDate AS date), m.AccountNumber, m.EventSubType;

------------------------------------------------------------
-- D7) OPTIONAL: show HISTORY rows (real + dummy) for quick human review
------------------------------------------------------------
SELECT
    CAST(h.BusinessDate AS date) AS BusinessDate,
    h.AccountNumber,
    h.EventType,
    h.EventSubType,
    h.SequenceNumber,
    h.IsDummyEntry
FROM dbo.CBG_ESaverNotificationHistory h
WHERE CAST(h.BusinessDate AS date) IN (@BD1, @BD2)
  AND h.AccountNumber BETWEEN 910001 AND 910006
  AND h.EventSubType IN
  (
    'ESaver50PercentGoalReached',
    'ESaver90PercentGoalReached',
    'ESaver100PercentGoalReachedBeforeGoalDateInterest',
    'ESaver100PercentGoalReachedBeforeGoalDateLoyalty'
  )
ORDER BY CAST(h.BusinessDate AS date), h.AccountNumber, h.IsDummyEntry, h.EventSubType;

PRINT 'DONE';
