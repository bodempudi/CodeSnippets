
/*
    ESaver Notifications – Functional Test Script
    ============================================

    PURPOSE
    -------
    This script helps you functionally test:

        dbo.usp_StageLoad_CBG_ESaverNotification

    It will:

    1) (Optionally) clear existing test data in:
           - Stage_CBG_ESaverNotification
           - CBG_ESaverNotification
           - CBG_ESaverNotificationEventType
           - ESaverAccount
    2) Seed CBG_ESaverNotificationEventType with minimal metadata
       for all required sub-events.
    3) Seed ESaverAccount snapshot for a single BusinessDate
       with accounts designed to cover all key scenarios:
           - 50 / 90 / 100% goal milestones (Interest + Loyalty)
           - OneMonthLeftForGoalMaturity
           - NoActivityOverOneMonth
           - Closed goal reached (Interest + Loyalty + ThreeDaysBack)
           - Negative cases that should NOT create any notifications
    4) Execute dbo.usp_StageLoad_CBG_ESaverNotification.
    5) Select from Stage_CBG_ESaverNotification and document
       expected results per account (for visual/manual verification).
    6) Provide a regression test for duplicate-prevention.

    IMPORTANT
    ---------
    - This script assumes the following tables exist with at least
      the listed columns. If your real tables have different names
      or additional NOT NULL columns, adjust the INSERT statements
      accordingly.

        dbo.ESaverAccount
            (BusinessDate, AccountNumber, CustomerID,
             ESaverName, ESaverAccountType, AccountStatus,
             GoalAmount, CurrentBalanceAsOnBusinessDate,
             MaturityDate, MaturityAmountAsOnMaturityDate,
             LastAccountActivityDate)

        dbo.CBG_ESaverNotificationEventType
            (EventType, EventSubType, EventGroup,
             ThresholdPercentage, ThresholdLimit,
             IsOneTimeEvent, IsActive)

        dbo.CBG_ESaverNotification
            (EventType, EventSubType, AccountNumber,
             CustomerID, LastNotificationCount, BusinessDate)

        dbo.Stage_CBG_ESaverNotification
            (BusinessDate, SystemID, EventType, EventSubType,
             AccountNumber, CustomerID, ESaverName,
             SequenceNumber, IsDummyEntry,
             EventDataKey01, EventDataValue01,
             EventDataKey02, EventDataValue02,
             PuffinTargetTableName, CreateUserID, CreateDateTime)

    - BusinessDate under test in this script = 2025-12-01.

    - Run this script in a DEV / SANDBOX database only.
*/

------------------------------------------------------------
-- 0. OPTIONAL CLEANUP (UNCOMMENT IN DEV/SANDBOX ONLY)
------------------------------------------------------------
/*
TRUNCATE TABLE dbo.Stage_CBG_ESaverNotification;
DELETE FROM dbo.CBG_ESaverNotification;
DELETE FROM dbo.CBG_ESaverNotificationEventType;
DELETE FROM dbo.ESaverAccount;
*/

------------------------------------------------------------
-- 1. Seed EventType metadata (minimal set of columns)
--    You can extend with more columns from your real config table.
------------------------------------------------------------
PRINT 'Seeding CBG_ESaverNotificationEventType...';

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
-- Goal percent group (50 / 90 / 100)
( 'BatchGeneric', 'ESaver50PercentGoalReached',
  'GoalPercentReached',  50.0, 1, 'Y', 'Y'),

( 'BatchGeneric', 'ESaver90PercentGoalReached',
  'GoalPercentReached',  90.0, 1, 'Y', 'Y'),

( 'BatchGeneric', 'ESaver100PercentGoalReachedBeforeGoalDateInterest',
  'GoalPercentReached', 100.0, 1, 'Y', 'Y'),

( 'BatchGeneric', 'ESaver100PercentGoalReachedBeforeGoalDateLoyalty',
  'GoalPercentReached', 100.0, 1, 'Y', 'Y'),

-- One month left for goal maturity
( 'BatchGeneric', 'ESaverOneMonthLeftForGoalMaturity',
  'MaturityReminder',    NULL, 1, 'Y', 'Y'),

-- No activity over one month
( 'BatchGeneric', 'ESaverNoActivityOverOneMonth',
  'Inactivity',          NULL, 1, 'Y', 'Y'),

-- Closed goal reached - Interest
( 'BatchGeneric', 'ESaverClosedGoalReachedInterest',
  'ClosedInterest',      NULL, 1, 'Y', 'Y'),

-- Closed goal reached - Loyalty (same day)
( 'BatchGeneric', 'ESaverClosedGoalReachedLoyalty',
  'ClosedLoyalty',       NULL, 1, 'Y', 'Y'),

-- Closed goal reached - Loyalty three days back
( 'BatchGeneric', 'ESaverClosedGoalReachedLoyaltyThreeDaysBack',
  'ClosedLoyalty',       NULL, 1, 'Y', 'Y');

------------------------------------------------------------
-- 2. Seed ESaverAccount snapshot for BusinessDate = 2025-12-01
------------------------------------------------------------
PRINT 'Seeding ESaverAccount test data...';

DECLARE @BD DATE = '2025-12-01';

-- Positive cases (should create notifications)
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
-- A1001 – 52% goal reached (Interest)
-- Expectation:
--   - Only "ESaver50PercentGoalReached" rows
--   - For this account: 50% becomes the highest threshold reached
--     → IsDummyEntry = 'N'
----------------------------------------------------------------------
( @BD, 1001, 9001, 'Goal52_Interest',   'InterestAccount', 'OPEN',
  1000.00,  520.00, '2026-06-01', 1000.00, DATEADD(DAY, -10, @BD)),

----------------------------------------------------------------------
-- A1002 – 92% goal reached (Interest)
-- Expectation:
--   - Eligible thresholds: 50, 90
--   - Precedence: 90% is highest → IsDummyEntry = 'N'
--   - 50% should appear as IsDummyEntry = 'Y'
----------------------------------------------------------------------
( @BD, 1002, 9002, 'Goal92_Interest',   'InterestAccount', 'OPEN',
  1000.00,  920.00, '2026-06-01', 1000.00, DATEADD(DAY, -10, @BD)),

----------------------------------------------------------------------
-- A1003 – 102% goal reached (Interest)
-- Expectation:
--   - Eligible thresholds: 50, 90, 100
--   - Uses the Interest 100% subevent
--   - 100% (Interest) → IsDummyEntry = 'N'
--   - 50% & 90% → IsDummyEntry = 'Y'
----------------------------------------------------------------------
( @BD, 1003, 9003, 'Goal102_Interest',  'InterestAccount', 'OPEN',
  1000.00, 1020.00, '2025-12-20', 1000.00, DATEADD(DAY, -10, @BD)),

----------------------------------------------------------------------
-- A1004 – 103% goal reached (Loyalty)
-- Expectation:
--   - Eligible thresholds: 50, 90, 100-Loyalty.
--   - 100% (Loyalty) → IsDummyEntry = 'N'
--   - 50% & 90% → IsDummyEntry = 'Y'
----------------------------------------------------------------------
( @BD, 1004, 9004, 'Goal103_Loyalty',   'LoyaltyAccount',  'OPEN',
  1000.00, 1030.00, '2025-12-20', 1000.00, DATEADD(DAY, -10, @BD)),

----------------------------------------------------------------------
-- A2001 – OneMonthLeftForGoalMaturity
-- (MaturityDate - BusinessDate = 30, balance < maturity amount)
-- Expectation:
--   - 1 row with EventSubType = 'ESaverOneMonthLeftForGoalMaturity'
----------------------------------------------------------------------
( @BD, 2001, 9201, 'MaturityMinus30',   'InterestAccount', 'OPEN',
  5000.00, 3000.00, DATEADD(DAY, 30, @BD), 5000.00, DATEADD(DAY, -5, @BD)),

----------------------------------------------------------------------
-- A3001 – NoActivityOverOneMonth
-- (LastAccountActivityDate older than 30 days, balance < maturity)
-- Expectation:
--   - 1 row with EventSubType = 'ESaverNoActivityOverOneMonth'
----------------------------------------------------------------------
( @BD, 3001, 9301, 'NoActivity>30',     'InterestAccount', 'OPEN',
  4000.00, 2000.00, '2026-01-31', 4000.00, DATEADD(DAY, -40, @BD)),

----------------------------------------------------------------------
-- A4001 – Closed goal reached – Interest
-- (Closed, interest type, maturity already passed, at or above maturity amount)
-- Expectation:
--   - 1 row with EventSubType = 'ESaverClosedGoalReachedInterest'
----------------------------------------------------------------------
( @BD, 4001, 9401, 'ClosedGoal_Int',    'InterestAccount', 'CLOSED',
  6000.00, 6000.00, DATEADD(DAY, -10, @BD), 6000.00, DATEADD(DAY, -10, @BD)),

----------------------------------------------------------------------
-- A5001 – Closed goal reached – Loyalty (closed on BusinessDate)
-- (Closed, loyalty type, maturity already passed, at or above maturity amount)
-- Expectation:
--   - 1 row with EventSubType = 'ESaverClosedGoalReachedLoyalty'
----------------------------------------------------------------------
( @BD, 5001, 9501, 'ClosedGoal_Loy_Today', 'LoyaltyAccount', 'CLOSED',
  7000.00, 7000.00, DATEADD(DAY, -5, @BD), 7000.00, DATEADD(DAY, -5, @BD)),

----------------------------------------------------------------------
-- A5002 – Closed goal reached – Loyalty (for ThreeDaysBack event)
-- (Closed, loyalty, maturity < BusinessDate-3)
-- Expectation:
--   - 1 row with EventSubType = 'ESaverClosedGoalReachedLoyaltyThreeDaysBack'
----------------------------------------------------------------------
( @BD, 5002, 9502, 'ClosedGoal_Loy_Old',   'LoyaltyAccount', 'CLOSED',
  7000.00, 7000.00, DATEADD(DAY, -10, @BD), 7000.00, DATEADD(DAY, -10, @BD));

------------------------------------------------------------
-- 2b. NEGATIVE CASES (should NOT create any notifications)
------------------------------------------------------------
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
-- A9001 – GoalPercent < 50 (45%)
-- Expectation:
--   - NO goal-percent notifications
----------------------------------------------------------------------
( @BD, 9001, 9901, 'Goal45_NoEvent',  'InterestAccount', 'OPEN',
  1000.00, 450.00, '2026-06-01', 1000.00, DATEADD(DAY, -10, @BD)),

----------------------------------------------------------------------
-- A9002 – Maturity difference is 29 days (not exactly 30)
-- Expectation:
--   - NO 'ESaverOneMonthLeftForGoalMaturity' notification
----------------------------------------------------------------------
( @BD, 9002, 9902, 'MaturityMinus29', 'InterestAccount', 'OPEN',
  5000.00, 3000.00, DATEADD(DAY, 29, @BD), 5000.00, DATEADD(DAY, -5, @BD)),

----------------------------------------------------------------------
-- A9003 – Inactivity only 20 days
-- Expectation:
--   - NO 'ESaverNoActivityOverOneMonth' notification
----------------------------------------------------------------------
( @BD, 9003, 9903, 'NoActivity20',   'InterestAccount', 'OPEN',
  4000.00, 2000.00, '2026-01-31', 4000.00, DATEADD(DAY, -20, @BD)),

----------------------------------------------------------------------
-- A9004 – ClosedInterest but balance < maturity amount
-- Expectation:
--   - NO 'ESaverClosedGoalReachedInterest' notification
----------------------------------------------------------------------
( @BD, 9004, 9904, 'ClosedGoal_Int_NotReached', 'InterestAccount', 'CLOSED',
  6000.00, 5000.00, DATEADD(DAY, -10, @BD), 6000.00, DATEADD(DAY, -10, @BD)),

----------------------------------------------------------------------
-- A9005 – ClosedLoyalty but maturity date >= BusinessDate
-- Expectation:
--   - NO closed loyalty notifications
----------------------------------------------------------------------
( @BD, 9005, 9905, 'ClosedGoal_Loy_NotMatured', 'LoyaltyAccount', 'CLOSED',
  7000.00, 7000.00, DATEADD(DAY, 2, @BD), 7000.00, DATEADD(DAY, -5, @BD));

------------------------------------------------------------
-- 3. (Optional) Existing notification history in main table
--    Uncomment to simulate "already sent" behavior.
------------------------------------------------------------
/*
PRINT 'Seeding existing CBG_ESaverNotification history (optional)...';

-- Example: simulate that A1001 already got 50% notification once.
INSERT INTO dbo.CBG_ESaverNotification
(
      EventType
    , EventSubType
    , AccountNumber
    , CustomerID
    , LastNotificationCount
    , BusinessDate
)
VALUES
( 'BatchGeneric', 'ESaver50PercentGoalReached', 1001, 9001, 1, DATEADD(DAY,-1,@BD));
*/

------------------------------------------------------------
-- 4. Execute the staging procedure
------------------------------------------------------------
PRINT 'Executing dbo.usp_StageLoad_CBG_ESaverNotification...';

EXEC dbo.usp_StageLoad_CBG_ESaverNotification
     @BusinessDate = @BD,
     @UserID       = 'TESTUSER',
     @SystemID     = N'1',
     @EventType    = N'BatchGeneric';

------------------------------------------------------------
-- 5. Inspect results in Stage_CBG_ESaverNotification
------------------------------------------------------------

PRINT 'Selecting Stage_CBG_ESaverNotification results...';

SELECT *
FROM dbo.Stage_CBG_ESaverNotification
ORDER BY AccountNumber, EventSubType;

------------------------------------------------------------
-- 6. EXPECTED RESULTS PER ACCOUNT (MANUAL VERIFICATION GUIDE)
------------------------------------------------------------

/*
POSITIVE CASES
==============

Account 1001 (Goal52_Interest, ~52%):
-------------------------------------
- Expect 1 row:
    EventSubType   = 'ESaver50PercentGoalReached'
    IsDummyEntry   = 'N'
- No 90% or 100% events.

Account 1002 (Goal92_Interest, ~92%):
-------------------------------------
- Expect 2 rows:
    1) EventSubType = 'ESaver50PercentGoalReached',  IsDummyEntry = 'Y'
    2) EventSubType = 'ESaver90PercentGoalReached',  IsDummyEntry = 'N'
- No 100% event because balance < 100% threshold.

Account 1003 (Goal102_Interest, ~102%):
---------------------------------------
- Eligible thresholds: 50, 90, 100-Interest.
- Expect 3 rows:
    1) EventSubType = 'ESaver50PercentGoalReached',                        IsDummyEntry = 'Y'
    2) EventSubType = 'ESaver90PercentGoalReached',                        IsDummyEntry = 'Y'
    3) EventSubType = 'ESaver100PercentGoalReachedBeforeGoalDateInterest', IsDummyEntry = 'N'

Account 1004 (Goal103_Loyalty, ~103%):
--------------------------------------
- Eligible thresholds: 50, 90, 100-Loyalty.
- Expect 3 rows:
    1) EventSubType = 'ESaver50PercentGoalReached',                       IsDummyEntry = 'Y'
    2) EventSubType = 'ESaver90PercentGoalReached',                       IsDummyEntry = 'Y'
    3) EventSubType = 'ESaver100PercentGoalReachedBeforeGoalDateLoyalty', IsDummyEntry = 'N'

Account 2001 (MaturityMinus30):
-------------------------------
- MaturityDate - BusinessDate = 30
- Balance < maturity amount.
- Expect 1 row:
    EventSubType = 'ESaverOneMonthLeftForGoalMaturity'

Account 3001 (NoActivity>30):
-----------------------------
- Days since LastAccountActivityDate > 30.
- Balance < maturity amount.
- Expect 1 row:
    EventSubType = 'ESaverNoActivityOverOneMonth'

Account 4001 (ClosedGoal_Int):
------------------------------
- AccountStatus      = 'CLOSED'
- ESaverAccountType  = 'InterestAccount'
- MaturityDate       < BusinessDate
- CurrentBalanceAsOnMaturityDate >= MaturityAmountAsOnMaturityDate
- Expect 1 row:
    EventSubType = 'ESaverClosedGoalReachedInterest'

Account 5001 (ClosedGoal_Loy_Today):
------------------------------------
- AccountStatus      = 'CLOSED'
- ESaverAccountType  = 'LoyaltyAccount'
- MaturityDate       < BusinessDate
- Expect 1 row:
    EventSubType = 'ESaverClosedGoalReachedLoyalty'

Account 5002 (ClosedGoal_Loy_Old):
----------------------------------
- AccountStatus      = 'CLOSED'
- ESaverAccountType  = 'LoyaltyAccount'
- MaturityDate       < BusinessDate - 3
- Expect 1 row:
    EventSubType = 'ESaverClosedGoalReachedLoyaltyThreeDaysBack'


NEGATIVE CASES
==============

Account 9001 (Goal45_NoEvent, ~45%):
------------------------------------
- GoalPercent < 50
- Expect: NO goal-percent notifications.

Account 9002 (MaturityMinus29):
-------------------------------
- MaturityDate - BusinessDate = 29 (not 30)
- Expect: NO 'ESaverOneMonthLeftForGoalMaturity'.

Account 9003 (NoActivity20):
----------------------------
- Days since LastAccountActivityDate = 20 (<= 30)
- Expect: NO 'ESaverNoActivityOverOneMonth'.

Account 9004 (ClosedGoal_Int_NotReached):
-----------------------------------------
- Closed interest but balance < maturity amount.
- Expect: NO 'ESaverClosedGoalReachedInterest'.

Account 9005 (ClosedGoal_Loy_NotMatured):
-----------------------------------------
- Closed loyalty but maturity date >= BusinessDate.
- Expect: NO closed loyalty notifications.


DUPLICATE-PREVENTION REGRESSION TEST
====================================

After first full run:

1) Insert main notification rows based on Stage.
   Example pattern:

   INSERT INTO dbo.CBG_ESaverNotification
   (
         EventType
       , EventSubType
       , AccountNumber
       , CustomerID
       , LastNotificationCount
       , BusinessDate
   )
   SELECT DISTINCT
         s.EventType
       , s.EventSubType
       , s.AccountNumber
       , s.CustomerID
       , 1                        -- simulate: already sent once
       , s.BusinessDate
   FROM dbo.Stage_CBG_ESaverNotification s;

2) TRUNCATE Stage_CBG_ESaverNotification:

   TRUNCATE TABLE dbo.Stage_CBG_ESaverNotification;

3) Run the procedure again for the same BusinessDate:

   EXEC dbo.usp_StageLoad_CBG_ESaverNotification
        @BusinessDate = @BD,
        @UserID       = 'TESTUSER',
        @SystemID     = N'1',
        @EventType    = N'BatchGeneric';

4) EXPECTATION:
   - No rows (or significantly fewer rows) should be reinserted
     into Stage for once-per-lifetime events (ThresholdLimit = 1),
     because LastNotificationCount >= ThresholdLimit now.
*/

PRINT 'Test script execution completed. Review Stage_CBG_ESaverNotification for results.';
