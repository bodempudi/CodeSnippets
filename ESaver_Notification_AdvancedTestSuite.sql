
/*
    ESaver Notifications – Advanced Functional Test Script
    ======================================================

    PURPOSE
    -------
    This script is an ADD-ON to your basic test suite.

    It specifically tests ADVANCED BEHAVIOR of:

        dbo.usp_StageLoad_CBG_ESaverNotification

    Focus areas:

    1) Cross-day behavior for Goal% milestones
         - Day1 90% reached, Day2 still 90%  → NO duplicate
         - Day1 50% reached, Day2 crosses 90% → ONLY 90% fires

    2) ThresholdLimit > 1 for "ESaverNoActivityOverOneMonth"
         - Same account eligible on multiple days
         - Notification allowed up to ThresholdLimit times
         - Then blocked after limit is reached

    NOTES
    -----
    - This script assumes ALL tables and the procedure already exist:
        dbo.ESaverAccount
        dbo.CBG_ESaverNotificationEventType
        dbo.CBG_ESaverNotification
        dbo.Stage_CBG_ESaverNotification
        dbo.usp_StageLoad_CBG_ESaverNotification

    - Adjust column names if your real schema differs.

    - Run this ONLY in DEV / SANDBOX.

    - This script is independent of the "FullTestSuite" script, but
      it uses different account numbers (7000+ and 8000+) to avoid overlap.
*/

------------------------------------------------------------
-- 0. OPTIONAL CLEANUP FOR ADVANCED TEST ACCOUNTS ONLY
------------------------------------------------------------
/*
DELETE FROM dbo.Stage_CBG_ESaverNotification
WHERE AccountNumber BETWEEN 7000 AND 8999;

DELETE FROM dbo.CBG_ESaverNotification
WHERE AccountNumber BETWEEN 7000 AND 8999;

DELETE FROM dbo.ESaverAccount
WHERE AccountNumber BETWEEN 7000 AND 8999;
*/

------------------------------------------------------------
-- 1. Ensure EventType metadata exists (idempotent inserts)
--    We only touch the specific rows we need for advanced tests.
------------------------------------------------------------
PRINT 'Ensuring CBG_ESaverNotificationEventType rows for advanced tests...';

-- Goal percent events
IF NOT EXISTS (
    SELECT 1 FROM dbo.CBG_ESaverNotificationEventType
    WHERE EventType = 'BatchGeneric'
      AND EventSubType = 'ESaver50PercentGoalReached'
)
BEGIN
    INSERT INTO dbo.CBG_ESaverNotificationEventType
    (
          EventType
        , EventSubType
        , EventGroup
        , ThresholdPercentage
        , ThresholdLimit
        , IsOneTimeEvent
        , IsActive
    )
    VALUES
    ( 'BatchGeneric', 'ESaver50PercentGoalReached',
      'GoalPercentReached', 50.0, 1, 'Y', 'Y');
END;

IF NOT EXISTS (
    SELECT 1 FROM dbo.CBG_ESaverNotificationEventType
    WHERE EventType = 'BatchGeneric'
      AND EventSubType = 'ESaver90PercentGoalReached'
)
BEGIN
    INSERT INTO dbo.CBG_ESaverNotificationEventType
    (
          EventType
        , EventSubType
        , EventGroup
        , ThresholdPercentage
        , ThresholdLimit
        , IsOneTimeEvent
        , IsActive
    )
    VALUES
    ( 'BatchGeneric', 'ESaver90PercentGoalReached',
      'GoalPercentReached', 90.0, 1, 'Y', 'Y');
END;

IF NOT EXISTS (
    SELECT 1 FROM dbo.CBG_ESaverNotificationEventType
    WHERE EventType = 'BatchGeneric'
      AND EventSubType = 'ESaver100PercentGoalReachedBeforeGoalDateInterest'
)
BEGIN
    INSERT INTO dbo.CBG_ESaverNotificationEventType
    (
          EventType
        , EventSubType
        , EventGroup
        , ThresholdPercentage
        , ThresholdLimit
        , IsOneTimeEvent
        , IsActive
    )
    VALUES
    ( 'BatchGeneric', 'ESaver100PercentGoalReachedBeforeGoalDateInterest',
      'GoalPercentReached', 100.0, 1, 'Y', 'Y');
END;

-- NoActivityOverOneMonth event: we will set ThresholdLimit = 3 for advanced test
IF NOT EXISTS (
    SELECT 1 FROM dbo.CBG_ESaverNotificationEventType
    WHERE EventType = 'BatchGeneric'
      AND EventSubType = 'ESaverNoActivityOverOneMonth'
)
BEGIN
    INSERT INTO dbo.CBG_ESaverNotificationEventType
    (
          EventType
        , EventSubType
        , EventGroup
        , ThresholdPercentage
        , ThresholdLimit
        , IsOneTimeEvent
        , IsActive
    )
    VALUES
    ( 'BatchGeneric', 'ESaverNoActivityOverOneMonth',
      'Inactivity', NULL, 3, 'N', 'Y');  -- ThresholdLimit=3, not one-time
END
ELSE
BEGIN
    -- Force ThresholdLimit = 3 just for advanced test
    UPDATE dbo.CBG_ESaverNotificationEventType
    SET ThresholdLimit = 3,
        IsOneTimeEvent = 'N'
    WHERE EventType = 'BatchGeneric'
      AND EventSubType = 'ESaverNoActivityOverOneMonth';
END;

------------------------------------------------------------
-- 2. CROSS-DAY GOAL% TESTS
--    Accounts: 7001, 7002
------------------------------------------------------------
PRINT '==== CROSS-DAY GOAL% TESTS (Accounts 7001, 7002) ====';

DECLARE @BD1 DATE = '2025-12-05';  -- Day 1
DECLARE @BD2 DATE = '2025-12-06';  -- Day 2

------------------------------------------------------------
-- 2.1 Day 1 snapshot for 7001 and 7002
------------------------------------------------------------
PRINT 'Inserting ESaverAccount snapshot for Day1 (7001:92%, 7002:52%)...';

INSERT INTO dbo.ESaverAccount
(
      BusinessDate
    , AccountNumber
    , CustomerID
    , ESaverName
    , ESaverAccountType
    , AccountStatus
    , GoalAmount
    , CurrentBalanceAsOnBusinessDate
    , MaturityDate
    , MaturityAmountAsOnMaturityDate
    , LastAccountActivityDate
)
VALUES
----------------------------------------------------------------------
-- 7001 – 92% goal reached on Day1
-- Expectation on Day1:
--   - 50% dummy + 90% main (IsDummyEntry = 'N')
----------------------------------------------------------------------
( @BD1, 7001, 87001, '7001_Day1_92pct', 'InterestAccount', 'OPEN',
  1000.00, 920.00, '2026-06-01', 1000.00, DATEADD(DAY, -10, @BD1)),

----------------------------------------------------------------------
-- 7002 – 52% goal reached on Day1
-- Expectation on Day1:
--   - Only 50% main (IsDummyEntry = 'N')
----------------------------------------------------------------------
( @BD1, 7002, 87002, '7002_Day1_52pct', 'InterestAccount', 'OPEN',
  1000.00, 520.00, '2026-06-01', 1000.00, DATEADD(DAY, -10, @BD1));

------------------------------------------------------------
-- 2.2 Run SP for Day1
------------------------------------------------------------
PRINT 'Running usp_StageLoad_CBG_ESaverNotification for Day1 (cross-day tests)...';

EXEC dbo.usp_StageLoad_CBG_ESaverNotification
     @BusinessDate = @BD1,
     @UserID       = 'ADVTEST1',
     @SystemID     = N'1',
     @EventType    = N'BatchGeneric';

PRINT 'Stage rows for Day1 (7001 & 7002):';
SELECT *
FROM dbo.Stage_CBG_ESaverNotification
WHERE AccountNumber IN (7001, 7002)
  AND BusinessDate = @BD1
ORDER BY AccountNumber, EventSubType;

------------------------------------------------------------
-- 2.3 Simulate main table update (CBG_ESaverNotification) after Day1
--     We aggregate Stage rows to maintain LastNotificationCount per
--     EventType/EventSubType/AccountNumber.
------------------------------------------------------------
PRINT 'Updating CBG_ESaverNotification based on Day1 Stage rows (simulating notification sent)...';

;WITH DistinctDay1 AS
(
    SELECT DISTINCT
          s.EventType
        , s.EventSubType
        , s.AccountNumber
        , s.CustomerID
        , s.BusinessDate
    FROM dbo.Stage_CBG_ESaverNotification s
    WHERE s.AccountNumber IN (7001, 7002)
      AND s.BusinessDate = @BD1
)
MERGE dbo.CBG_ESaverNotification AS T
USING DistinctDay1 AS S
   ON  T.EventType     = S.EventType
   AND T.EventSubType  = S.EventSubType
   AND T.AccountNumber = S.AccountNumber
WHEN MATCHED THEN
    UPDATE SET
        T.LastNotificationCount = T.LastNotificationCount + 1,
        T.BusinessDate          = S.BusinessDate
WHEN NOT MATCHED THEN
    INSERT
    (
          EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , LastNotificationCount
        , BusinessDate
    )
    VALUES
    (
          S.EventType
        , S.EventSubType
        , S.AccountNumber
        , S.CustomerID
        , 1
        , S.BusinessDate
    );

PRINT 'Current CBG_ESaverNotification rows for 7001 & 7002 AFTER Day1:';
SELECT *
FROM dbo.CBG_ESaverNotification
WHERE AccountNumber IN (7001, 7002)
ORDER BY AccountNumber, EventSubType;

------------------------------------------------------------
-- 2.4 Day 2 snapshot
--     - 7001 stays at 92% (no new threshold, should NOT generate new rows)
--     - 7002 jumps from 52% to 95% (new 90% threshold reached,
--       only 90% main event should fire; 50% was already used Day1)
------------------------------------------------------------
PRINT 'Inserting ESaverAccount snapshot for Day2 (7001:92%, 7002:95%)...';

INSERT INTO dbo.ESaverAccount
(
      BusinessDate
    , AccountNumber
    , CustomerID
    , ESaverName
    , ESaverAccountType
    , AccountStatus
    , GoalAmount
    , CurrentBalanceAsOnBusinessDate
    , MaturityDate
    , MaturityAmountAsOnMaturityDate
    , LastAccountActivityDate
)
VALUES
-- 7001 – still 92% on Day2 (no new threshold)
( @BD2, 7001, 87001, '7001_Day2_92pct', 'InterestAccount', 'OPEN',
  1000.00, 920.00, '2026-06-01', 1000.00, DATEADD(DAY, -11, @BD2)),

-- 7002 – now 95% on Day2 (new 90% band)
( @BD2, 7002, 87002, '7002_Day2_95pct', 'InterestAccount', 'OPEN',
  1000.00, 950.00, '2026-06-01', 1000.00, DATEADD(DAY, -11, @BD2));

------------------------------------------------------------
-- 2.5 Run SP for Day2
------------------------------------------------------------
PRINT 'Running usp_StageLoad_CBG_ESaverNotification for Day2 (cross-day tests)...';

EXEC dbo.usp_StageLoad_CBG_ESaverNotification
     @BusinessDate = @BD2,
     @UserID       = 'ADVTEST2',
     @SystemID     = N'1',
     @EventType    = N'BatchGeneric';

PRINT 'Stage rows for Day2 (7001 & 7002):';
SELECT *
FROM dbo.Stage_CBG_ESaverNotification
WHERE AccountNumber IN (7001, 7002)
  AND BusinessDate = @BD2
ORDER BY AccountNumber, EventSubType;

/*
EXPECTED RESULTS – CROSS-DAY

Day1 (BD1 = 2025-12-05):

  Account 7001 (~92%):
    - ESaver50PercentGoalReached       (likely Dummy='Y')
    - ESaver90PercentGoalReached       (Dummy='N')

  Account 7002 (~52%):
    - ESaver50PercentGoalReached       (Dummy='N')

After MERGE into CBG_ESaverNotification:
    - 7001 has LastNotificationCount >=1 for 50% and 90%
    - 7002 has LastNotificationCount >=1 for 50%

Day2 (BD2 = 2025-12-06):

  Account 7001 (still ~92%):
    - 90% already sent, ThresholdLimit = 1 → NO new rows in Stage.
    - Check that Stage has ZERO rows for account 7001 for BD2.

  Account 7002 (now ~95%):
    - 50% already sent (LastNotificationCount >= ThresholdLimit)
    - 90% not yet sent → should produce only:
         ESaver90PercentGoalReached (Dummy='N')
    - Stage for BD2 should have exactly ONE row for 7002.
*/

------------------------------------------------------------
-- 3. THRESHOLDLIMIT > 1 TEST FOR INACTIVITY EVENT
--    Account: 8001
------------------------------------------------------------
PRINT '==== THRESHOLDLIMIT>1 TEST FOR ESaverNoActivityOverOneMonth (Account 8001) ====';

DECLARE @BD_I1 DATE = '2025-12-10';  -- Day 1
DECLARE @BD_I2 DATE = '2025-12-11';  -- Day 2
DECLARE @BD_I3 DATE = '2025-12-12';  -- Day 3
DECLARE @BD_I4 DATE = '2025-12-13';  -- Day 4 (should be blocked by limit)

------------------------------------------------------------
-- 3.1 Insert ESaverAccount snapshots for 4 consecutive days
--     LastAccountActivityDate stays constant at BD_I1 - 40
--     So DaysSinceLastActivity > 30 on all 4 days.
------------------------------------------------------------
PRINT 'Inserting ESaverAccount snapshots for Account 8001 (4 days of inactivity)...';

DECLARE @LastAct DATE = DATEADD(DAY, -40, @BD_I1);

INSERT INTO dbo.ESaverAccount
(
      BusinessDate
    , AccountNumber
    , CustomerID
    , ESaverName
    , ESaverAccountType
    , AccountStatus
    , GoalAmount
    , CurrentBalanceAsOnBusinessDate
    , MaturityDate
    , MaturityAmountAsOnMaturityDate
    , LastAccountActivityDate
)
VALUES
( @BD_I1, 8001, 88001, 'NoActDay1', 'InterestAccount', 'OPEN',
  5000.00, 2500.00, '2026-01-31', 5000.00, @LastAct ),

( @BD_I2, 8001, 88001, 'NoActDay2', 'InterestAccount', 'OPEN',
  5000.00, 2500.00, '2026-01-31', 5000.00, @LastAct ),

( @BD_I3, 8001, 88001, 'NoActDay3', 'InterestAccount', 'OPEN',
  5000.00, 2500.00, '2026-01-31', 5000.00, @LastAct ),

( @BD_I4, 8001, 88001, 'NoActDay4', 'InterestAccount', 'OPEN',
  5000.00, 2500.00, '2026-01-31', 5000.00, @LastAct );

------------------------------------------------------------
-- 3.2 Helper: run SP for a given date and MERGE Stage into main
--     (just like actual daily batch behavior)
------------------------------------------------------------
PRINT 'Running procedure and updating main table for 4 days of inactivity...';

DECLARE @LoopDate DATE;

-- Day 1
SET @LoopDate = @BD_I1;
EXEC dbo.usp_StageLoad_CBG_ESaverNotification
     @BusinessDate = @LoopDate,
     @UserID       = 'ADV_INACT',
     @SystemID     = N'1',
     @EventType    = N'BatchGeneric';

;WITH DistinctStage AS
(
    SELECT DISTINCT
          s.EventType
        , s.EventSubType
        , s.AccountNumber
        , s.CustomerID
        , s.BusinessDate
    FROM dbo.Stage_CBG_ESaverNotification s
    WHERE s.AccountNumber = 8001
      AND s.BusinessDate  = @LoopDate
      AND s.EventSubType  = 'ESaverNoActivityOverOneMonth'
)
MERGE dbo.CBG_ESaverNotification AS T
USING DistinctStage AS S
   ON  T.EventType     = S.EventType
   AND T.EventSubType  = S.EventSubType
   AND T.AccountNumber = S.AccountNumber
WHEN MATCHED THEN
    UPDATE SET
        T.LastNotificationCount = T.LastNotificationCount + 1,
        T.BusinessDate          = S.BusinessDate
WHEN NOT MATCHED THEN
    INSERT
    (
          EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , LastNotificationCount
        , BusinessDate
    )
    VALUES
    (
          S.EventType
        , S.EventSubType
        , S.AccountNumber
        , S.CustomerID
        , 1
        , S.BusinessDate
    );

-- Day 2
SET @LoopDate = @BD_I2;
EXEC dbo.usp_StageLoad_CBG_ESaverNotification
     @BusinessDate = @LoopDate,
     @UserID       = 'ADV_INACT',
     @SystemID     = N'1',
     @EventType    = N'BatchGeneric';

;WITH DistinctStage2 AS
(
    SELECT DISTINCT
          s.EventType
        , s.EventSubType
        , s.AccountNumber
        , s.CustomerID
        , s.BusinessDate
    FROM dbo.Stage_CBG_ESaverNotification s
    WHERE s.AccountNumber = 8001
      AND s.BusinessDate  = @LoopDate
      AND s.EventSubType  = 'ESaverNoActivityOverOneMonth'
)
MERGE dbo.CBG_ESaverNotification AS T
USING DistinctStage2 AS S
   ON  T.EventType     = S.EventType
   AND T.EventSubType  = S.EventSubType
   AND T.AccountNumber = S.AccountNumber
WHEN MATCHED THEN
    UPDATE SET
        T.LastNotificationCount = T.LastNotificationCount + 1,
        T.BusinessDate          = S.BusinessDate
WHEN NOT MATCHED THEN
    INSERT
    (
          EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , LastNotificationCount
        , BusinessDate
    )
    VALUES
    (
          S.EventType
        , S.EventSubType
        , S.AccountNumber
        , S.CustomerID
        , 1
        , S.BusinessDate
    );

-- Day 3
SET @LoopDate = @BD_I3;
EXEC dbo.usp_StageLoad_CBG_ESaverNotification
     @BusinessDate = @LoopDate,
     @UserID       = 'ADV_INACT',
     @SystemID     = N'1',
     @EventType    = N'BatchGeneric';

;WITH DistinctStage3 AS
(
    SELECT DISTINCT
          s.EventType
        , s.EventSubType
        , s.AccountNumber
        , s.CustomerID
        , s.BusinessDate
    FROM dbo.Stage_CBG_ESaverNotification s
    WHERE s.AccountNumber = 8001
      AND s.BusinessDate  = @LoopDate
      AND s.EventSubType  = 'ESaverNoActivityOverOneMonth'
)
MERGE dbo.CBG_ESaverNotification AS T
USING DistinctStage3 AS S
   ON  T.EventType     = S.EventType
   AND T.EventSubType  = S.EventSubType
   AND T.AccountNumber = S.AccountNumber
WHEN MATCHED THEN
    UPDATE SET
        T.LastNotificationCount = T.LastNotificationCount + 1,
        T.BusinessDate          = S.BusinessDate
WHEN NOT MATCHED THEN
    INSERT
    (
          EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , LastNotificationCount
        , BusinessDate
    )
    VALUES
    (
          S.EventType
        , S.EventSubType
        , S.AccountNumber
        , S.CustomerID
        , 1
        , S.BusinessDate
    );

-- Day 4
SET @LoopDate = @BD_I4;
EXEC dbo.usp_StageLoad_CBG_ESaverNotification
     @BusinessDate = @LoopDate,
     @UserID       = 'ADV_INACT',
     @SystemID     = N'1',
     @EventType    = N'BatchGeneric';

-- No MERGE for day4, we just want to see if Stage still produces rows
-- now that LastNotificationCount should be 3 (ThresholdLimit).

------------------------------------------------------------
-- 3.3 Inspect Stage and main table for account 8001
------------------------------------------------------------
PRINT 'Stage rows for Account 8001 (all 4 days):';
SELECT *
FROM dbo.Stage_CBG_ESaverNotification
WHERE AccountNumber = 8001
ORDER BY BusinessDate, EventSubType;

PRINT 'CBG_ESaverNotification row for Account 8001 (NoActivity):';
SELECT *
FROM dbo.CBG_ESaverNotification
WHERE AccountNumber = 8001
  AND EventSubType  = 'ESaverNoActivityOverOneMonth';

/*
EXPECTED RESULTS – THRESHOLDLIMIT>1

1) After Day1:
   - Stage should have 1 row for account 8001 on BD_I1
       EventSubType = 'ESaverNoActivityOverOneMonth'
   - CBG_ESaverNotification.LastNotificationCount for 8001 should be 1

2) After Day2:
   - Stage should have another row for BD_I2 (same subevent)
   - CBG_ESaverNotification.LastNotificationCount should be 2

3) After Day3:
   - Stage should again have a row for BD_I3
   - CBG_ESaverNotification.LastNotificationCount should be 3
     (now equal to ThresholdLimit)

4) On Day4 (BD_I4):
   - Because LastNotificationCount (3) >= ThresholdLimit (3),
     #GoalEligibleCountBand (for this subevent) should filter this out.
   - EXPECT: Stage has NO row for BD_I4 for account 8001
             with EventSubType = 'ESaverNoActivityOverOneMonth'.

This proves:
   - Multi-send up to ThresholdLimit works.
   - Additional days are correctly blocked by ThresholdLimit.
*/

PRINT 'Advanced test script execution completed. Review results above.';
