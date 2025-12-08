
/*
    Master Procedure: usp_StageLoad_CBG_ESaverNotification.sql

    NOTE:
    - Adjust table and column names to match your actual schema.
    - This script assumes existence of:
        dbo.ESaverAccount
        dbo.CBG_ESaverNotificationEventType
        dbo.CBG_ESaverNotification
        dbo.Stage_CBG_ESaverNotification
*/

IF OBJECT_ID('dbo.usp_StageLoad_CBG_ESaverNotification', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_StageLoad_CBG_ESaverNotification;
GO

CREATE PROCEDURE dbo.usp_StageLoad_CBG_ESaverNotification
(
      @BusinessDate   DATE,
      @UserID         VARCHAR(20),
      @SystemID       NVARCHAR(20)   = N'1',            -- from spec
      @EventType      NVARCHAR(128) = N'BatchGeneric'  -- from spec
)
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------------------------------
    -- Common setup
    -------------------------------------------------------------------------
    DECLARE @SeqNum INT = CONVERT(INT, CONVERT(CHAR(8), @BusinessDate, 112));

    -------------------------------------------------------------------------
    -- BASE: Load all ESaverAccount rows for this BusinessDate into a temp
    -- (replace dbo.ESaverAccount with your derived table / TVP name)
    -------------------------------------------------------------------------
    CREATE TABLE #ESaverAccount
    (
          BusinessDate                   DATE
        , AccountNumber                  BIGINT
        , CustomerID                     BIGINT
        , ESaverName                     NVARCHAR(200)
        , ESaverAccountType              NVARCHAR(50)   -- InterestAccount / LoyaltyAccount / etc.
        , AccountStatus                  NVARCHAR(20)   -- OPEN / CLOSED / etc.
        , GoalAmount                     DECIMAL(18,2)
        , CurrentBalanceAsOnBusinessDate DECIMAL(18,2)
        , MaturityDate                   DATE
        , MaturityAmountAsOnMaturityDate DECIMAL(18,2)
        , LastAccountActivityDate        DATE
    );

    INSERT INTO #ESaverAccount
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
    SELECT
          a.BusinessDate
        , a.AccountNumber
        , a.CustomerID
        , a.ESaverName
        , a.ESaverAccountType
        , a.AccountStatus
        , a.GoalAmount
        , a.CurrentBalanceAsOnBusinessDate
        , a.MaturityDate
        , a.MaturityAmountAsOnMaturityDate
        , a.LastAccountActivityDate
    FROM dbo.ESaverAccount a
    WHERE a.BusinessDate = @BusinessDate;

    /**********************************************************************
     * BLOCK A – GOAL PERCENT GROUP (Events #5, #6, #7, #8)
     *   ESaver50PercentGoalReached
     *   ESaver90PercentGoalReached
     *   ESaver100PercentGoalReachedBeforeGoalDateInterest
     *   ESaver100PercentGoalReachedBeforeGoalDateLoyalty
     * Precedence within group + IsDummyEntry logic implemented here.
     *********************************************************************/

    ---------------------------------------------------------------------
    -- A1. Open accounts + GoalPercent
    ---------------------------------------------------------------------
    CREATE TABLE #OpenAccountsGoal
    (
          AccountNumber       BIGINT
        , CustomerID          BIGINT
        , ESaverName          NVARCHAR(200)
        , ESaverAccountType   NVARCHAR(50)
        , GoalPercent         DECIMAL(9,4)
    );

    INSERT INTO #OpenAccountsGoal
    (
          AccountNumber
        , CustomerID
        , ESaverName
        , ESaverAccountType
        , GoalPercent
    )
    SELECT
          a.AccountNumber
        , a.CustomerID
        , a.ESaverName
        , a.ESaverAccountType
        , CAST(
              CASE WHEN a.GoalAmount = 0 THEN 0
                   ELSE (a.CurrentBalanceAsOnBusinessDate * 100.0) / a.GoalAmount
              END AS DECIMAL(9,4)
          ) AS GoalPercent
    FROM #ESaverAccount a
    WHERE a.AccountStatus = 'OPEN';

    ---------------------------------------------------------------------
    -- A2. Join with EventType metadata for GoalPercentReached group
    ---------------------------------------------------------------------
    CREATE TABLE #GoalAccountsWithEvent
    (
          AccountNumber        BIGINT
        , CustomerID           BIGINT
        , ESaverName           NVARCHAR(200)
        , ESaverAccountType    NVARCHAR(50)
        , GoalPercent          DECIMAL(9,4)
        , EventType            NVARCHAR(128)
        , EventSubType         NVARCHAR(128)
        , ThresholdPercentage  DECIMAL(9,4)   -- 50 / 90 / 100
        , ThresholdLimit       INT            -- max sends for this subevent
    );

    INSERT INTO #GoalAccountsWithEvent
    (
          AccountNumber
        , CustomerID
        , ESaverName
        , ESaverAccountType
        , GoalPercent
        , EventType
        , EventSubType
        , ThresholdPercentage
        , ThresholdLimit
    )
    SELECT
          g.AccountNumber
        , g.CustomerID
        , g.ESaverName
        , g.ESaverAccountType
        , g.GoalPercent
        , et.EventType
        , et.EventSubType
        , et.ThresholdPercentage
        , et.ThresholdLimit
    FROM #OpenAccountsGoal g
    JOIN dbo.CBG_ESaverNotificationEventType et
          ON et.EventType      = @EventType
         AND et.EventGroup     = 'GoalPercentReached'
         AND et.IsOneTimeEvent = 'Y'
         AND et.IsActive       = 'Y';

    ---------------------------------------------------------------------
    -- A3. Filter by LastNotificationCount < ThresholdLimit and basic band
    ---------------------------------------------------------------------
    CREATE TABLE #GoalEligibleCountBand
    (
          AccountNumber        BIGINT
        , CustomerID           BIGINT
        , ESaverName           NVARCHAR(200)
        , ESaverAccountType    NVARCHAR(50)
        , GoalPercent          DECIMAL(9,4)
        , EventType            NVARCHAR(128)
        , EventSubType         NVARCHAR(128)
        , ThresholdPercentage  DECIMAL(9,4)
        , ThresholdLimit       INT
        , LastNotificationCount INT
    );

    INSERT INTO #GoalEligibleCountBand
    (
          AccountNumber
        , CustomerID
        , ESaverName
        , ESaverAccountType
        , GoalPercent
        , EventType
        , EventSubType
        , ThresholdPercentage
        , ThresholdLimit
        , LastNotificationCount
    )
    SELECT
          awe.AccountNumber
        , awe.CustomerID
        , awe.ESaverName
        , awe.ESaverAccountType
        , awe.GoalPercent
        , awe.EventType
        , awe.EventSubType
        , awe.ThresholdPercentage
        , awe.ThresholdLimit
        , ISNULL(n.LastNotificationCount, 0) AS LastNotificationCount
    FROM #GoalAccountsWithEvent awe
    LEFT JOIN dbo.CBG_ESaverNotification n
           ON n.EventType     = awe.EventType
          AND n.EventSubType  = awe.EventSubType
          AND n.AccountNumber = awe.AccountNumber
    WHERE
          ISNULL(n.LastNotificationCount, 0) < awe.ThresholdLimit
          AND awe.GoalPercent >= 50.0;

    ---------------------------------------------------------------------
    -- A4. Build #ESaverThresholdPercentage from metadata
    ---------------------------------------------------------------------
    CREATE TABLE #ESaverThresholdPercentage
    (
          EventType           NVARCHAR(128)
        , EventSubType        NVARCHAR(128)
        , ThresholdPercentage DECIMAL(9,4)
    );

    INSERT INTO #ESaverThresholdPercentage
    (
          EventType
        , EventSubType
        , ThresholdPercentage
    )
    SELECT
          et.EventType
        , et.EventSubType
        , et.ThresholdPercentage
    FROM dbo.CBG_ESaverNotificationEventType et
    WHERE et.EventType      = @EventType
      AND et.EventGroup     = 'GoalPercentReached'
      AND et.IsOneTimeEvent = 'Y'
      AND et.IsActive       = 'Y';

    ---------------------------------------------------------------------
    -- A5. Cross apply threshold table → precedence + IsDummyEntry (Y/N)
    ---------------------------------------------------------------------
    CREATE TABLE #GoalPrecedence
    (
          AccountNumber        BIGINT
        , CustomerID           BIGINT
        , ESaverName           NVARCHAR(200)
        , ESaverAccountType    NVARCHAR(50)
        , GoalPercent          DECIMAL(9,4)
        , EventType            NVARCHAR(128)
        , EventSubType         NVARCHAR(128)
        , ThresholdPercentage  DECIMAL(9,4)
        , ThresholdLimit       INT
        , LastNotificationCount INT
        , PrecedenceRank       INT
        , IsDummyEntry         CHAR(1)
    );

    ;WITH EligibleMilestones AS
    (
        SELECT
              e.AccountNumber
            , e.CustomerID
            , e.ESaverName
            , e.ESaverAccountType
            , e.GoalPercent
            , e.EventType
            , tp.EventSubType
            , tp.ThresholdPercentage
            , e.ThresholdLimit
            , e.LastNotificationCount
        FROM #GoalEligibleCountBand e
        CROSS APPLY
        (
            SELECT
                  t.EventType
                , t.EventSubType
                , t.ThresholdPercentage
            FROM #ESaverThresholdPercentage t
            WHERE t.EventType           = e.EventType
              AND t.ThresholdPercentage <= e.GoalPercent
        ) AS tp
    ),
    RankedMilestones AS
    (
        SELECT
              em.*
            , ROW_NUMBER() OVER
              (
                  PARTITION BY em.AccountNumber
                  ORDER BY em.ThresholdPercentage DESC
              ) AS PrecedenceRank
        FROM EligibleMilestones em
    )
    INSERT INTO #GoalPrecedence
    (
          AccountNumber
        , CustomerID
        , ESaverName
        , ESaverAccountType
        , GoalPercent
        , EventType
        , EventSubType
        , ThresholdPercentage
        , ThresholdLimit
        , LastNotificationCount
        , PrecedenceRank
        , IsDummyEntry
    )
    SELECT
          r.AccountNumber
        , r.CustomerID
        , r.ESaverName
        , r.ESaverAccountType
        , r.GoalPercent
        , r.EventType
        , r.EventSubType
        , r.ThresholdPercentage
        , r.ThresholdLimit
        , r.LastNotificationCount
        , r.PrecedenceRank
        , CASE WHEN r.PrecedenceRank = 1 THEN 'N' ELSE 'Y' END AS IsDummyEntry
    FROM RankedMilestones r;

    ---------------------------------------------------------------------
    -- A6. Insert GoalPercent events into Stage (all thresholds, IsDummy used)
    ---------------------------------------------------------------------
    INSERT INTO dbo.Stage_CBG_ESaverNotification
    (
          BusinessDate
        , SystemID
        , EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , ESaverName
        , SequenceNumber
        , IsDummyEntry
        , EventDataKey01
        , EventDataValue01
        , EventDataKey02
        , EventDataValue02
        , PuffinTargetTableName
        , CreateUserID
        , CreateDateTime
    )
    SELECT
          @BusinessDate
        , @SystemID
        , p.EventType
        , p.EventSubType
        , p.AccountNumber
        , p.CustomerID
        , p.ESaverName
        , @SeqNum
        , p.IsDummyEntry
        , 'GoalPercent'                        AS EventDataKey01
        , CONVERT(VARCHAR(20), p.GoalPercent)  AS EventDataValue01
        , 'ThresholdPercent'                   AS EventDataKey02
        , CONVERT(VARCHAR(20), p.ThresholdPercentage) AS EventDataValue02
        , N'CBG_ESaverNotificationHistory'
        , @UserID
        , SYSDATETIME()
    FROM #GoalPrecedence p
    LEFT JOIN dbo.CBG_ESaverNotification n
           ON n.EventType     = p.EventType
          AND n.EventSubType  = p.EventSubType
          AND n.AccountNumber = p.AccountNumber
    WHERE
          ISNULL(p.LastNotificationCount, 0) + 1
          > ISNULL(n.LastNotificationCount, 0);

    /**********************************************************************
     * BLOCK B – ESaverOneMonthLeftForGoalMaturity (Event #3)
     *********************************************************************/
    INSERT INTO dbo.Stage_CBG_ESaverNotification
    (
          BusinessDate
        , SystemID
        , EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , ESaverName
        , SequenceNumber
        , IsDummyEntry
        , EventDataKey01
        , EventDataValue01
        , PuffinTargetTableName
        , CreateUserID
        , CreateDateTime
    )
    SELECT
          @BusinessDate
        , @SystemID
        , @EventType
        , et.EventSubType            -- 'ESaverOneMonthLeftForGoalMaturity'
        , a.AccountNumber
        , a.CustomerID
        , a.ESaverName
        , @SeqNum
        , 'N'
        , 'MaturityDateDiffDays'
        , '30'
        , N'CBG_ESaverNotificationHistory'
        , @UserID
        , SYSDATETIME()
    FROM #ESaverAccount a
    JOIN dbo.CBG_ESaverNotificationEventType et
         ON et.EventType    = @EventType
        AND et.EventSubType = 'ESaverOneMonthLeftForGoalMaturity'
        AND et.IsActive     = 'Y'
    LEFT JOIN dbo.CBG_ESaverNotification n
         ON n.EventType     = et.EventType
        AND n.EventSubType  = et.EventSubType
        AND n.AccountNumber = a.AccountNumber
    WHERE a.AccountStatus = 'OPEN'
      AND DATEDIFF(DAY, @BusinessDate, a.MaturityDate) = 30
      AND a.CurrentBalanceAsOnBusinessDate < a.MaturityAmountAsOnMaturityDate
      AND ISNULL(n.LastNotificationCount, 0) < et.ThresholdLimit;

    /**********************************************************************
     * BLOCK C – ESaverNoActivityOverOneMonth (Event #4)
     *********************************************************************/
    INSERT INTO dbo.Stage_CBG_ESaverNotification
    (
          BusinessDate
        , SystemID
        , EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , ESaverName
        , SequenceNumber
        , IsDummyEntry
        , EventDataKey01
        , EventDataValue01
        , PuffinTargetTableName
        , CreateUserID
        , CreateDateTime
    )
    SELECT
          @BusinessDate
        , @SystemID
        , @EventType
        , et.EventSubType     -- 'ESaverNoActivityOverOneMonth'
        , a.AccountNumber
        , a.CustomerID
        , a.ESaverName
        , @SeqNum
        , 'N'
        , 'DaysSinceLastActivity'
        , '30'
        , N'CBG_ESaverNotificationHistory'
        , @UserID
        , SYSDATETIME()
    FROM #ESaverAccount a
    JOIN dbo.CBG_ESaverNotificationEventType et
         ON et.EventType    = @EventType
        AND et.EventSubType = 'ESaverNoActivityOverOneMonth'
        AND et.IsActive     = 'Y'
    LEFT JOIN dbo.CBG_ESaverNotification n
         ON n.EventType     = et.EventType
        AND n.EventSubType  = et.EventSubType
        AND n.AccountNumber = a.AccountNumber
    WHERE a.AccountStatus = 'OPEN'
      AND DATEDIFF(DAY, a.LastAccountActivityDate, @BusinessDate) > 30
      AND a.CurrentBalanceAsOnBusinessDate < a.MaturityAmountAsOnMaturityDate
      AND ISNULL(n.LastNotificationCount, 0) < et.ThresholdLimit;

    /**********************************************************************
     * BLOCK D – ESaverClosedGoalReachedInterest (Event #9)
     *********************************************************************/
    INSERT INTO dbo.Stage_CBG_ESaverNotification
    (
          BusinessDate
        , SystemID
        , EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , ESaverName
        , SequenceNumber
        , IsDummyEntry
        , EventDataKey01
        , EventDataValue01
        , PuffinTargetTableName
        , CreateUserID
        , CreateDateTime
    )
    SELECT
          @BusinessDate
        , @SystemID
        , @EventType
        , et.EventSubType    -- 'ESaverClosedGoalReachedInterest'
        , a.AccountNumber
        , a.CustomerID
        , a.ESaverName
        , @SeqNum
        , 'N'
        , 'ClosedReason'
        , 'GoalReachedInterest'
        , N'CBG_ESaverNotificationHistory'
        , @UserID
        , SYSDATETIME()
    FROM #ESaverAccount a
    JOIN dbo.CBG_ESaverNotificationEventType et
         ON et.EventType    = @EventType
        AND et.EventSubType = 'ESaverClosedGoalReachedInterest'
        AND et.IsActive     = 'Y'
    LEFT JOIN dbo.CBG_ESaverNotification n
         ON n.EventType     = et.EventType
        AND n.EventSubType  = et.EventSubType
        AND n.AccountNumber = a.AccountNumber
    WHERE a.AccountStatus      = 'CLOSED'
      AND a.ESaverAccountType  = 'InterestAccount'
      AND a.MaturityDate       < @BusinessDate
      AND a.CurrentBalanceAsOnMaturityDate >= a.MaturityAmountAsOnMaturityDate
      AND ISNULL(n.LastNotificationCount, 0) < et.ThresholdLimit;

    /**********************************************************************
     * BLOCK E – ESaverClosedGoalReachedLoyalty (Event #10)
     *********************************************************************/
    INSERT INTO dbo.Stage_CBG_ESaverNotification
    (
          BusinessDate
        , SystemID
        , EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , ESaverName
        , SequenceNumber
        , IsDummyEntry
        , EventDataKey01
        , EventDataValue01
        , PuffinTargetTableName
        , CreateUserID
        , CreateDateTime
    )
    SELECT
          @BusinessDate
        , @SystemID
        , @EventType
        , et.EventSubType   -- 'ESaverClosedGoalReachedLoyalty'
        , a.AccountNumber
        , a.CustomerID
        , a.ESaverName
        , @SeqNum
        , 'N'
        , 'ClosedReason'
        , 'GoalReachedLoyalty'
        , N'CBG_ESaverNotificationHistory'
        , @UserID
        , SYSDATETIME()
    FROM #ESaverAccount a
    JOIN dbo.CBG_ESaverNotificationEventType et
         ON et.EventType    = @EventType
        AND et.EventSubType = 'ESaverClosedGoalReachedLoyalty'
        AND et.IsActive     = 'Y'
    LEFT JOIN dbo.CBG_ESaverNotification n
         ON n.EventType     = et.EventType
        AND n.EventSubType  = et.EventSubType
        AND n.AccountNumber = a.AccountNumber
    WHERE a.AccountStatus      = 'CLOSED'
      AND a.ESaverAccountType  = 'LoyaltyAccount'
      AND a.MaturityDate       < @BusinessDate
      AND a.CurrentBalanceAsOnMaturityDate >= a.MaturityAmountAsOnMaturityDate
      AND ISNULL(n.LastNotificationCount, 0) < et.ThresholdLimit;

    /**********************************************************************
     * BLOCK F – ESaverClosedGoalReachedLoyaltyThreeDaysBack (Event #11)
     *********************************************************************/
    DECLARE @ClosedDate3Back DATE = DATEADD(DAY, -3, @BusinessDate);

    INSERT INTO dbo.Stage_CBG_ESaverNotification
    (
          BusinessDate
        , SystemID
        , EventType
        , EventSubType
        , AccountNumber
        , CustomerID
        , ESaverName
        , SequenceNumber
        , IsDummyEntry
        , EventDataKey01
        , EventDataValue01
        , PuffinTargetTableName
        , CreateUserID
        , CreateDateTime
    )
    SELECT
          @BusinessDate
        , @SystemID
        , @EventType
        , et.EventSubType   -- 'ESaverClosedGoalReachedLoyaltyThreeDaysBack'
        , a.AccountNumber
        , a.CustomerID
        , a.ESaverName
        , @SeqNum
        , 'N'
        , 'ClosedReason'
        , 'GoalReachedLoyaltyThreeDaysBack'
        , N'CBG_ESaverNotificationHistory'
        , @UserID
        , SYSDATETIME()
    FROM #ESaverAccount a
    JOIN dbo.CBG_ESaverNotificationEventType et
         ON et.EventType    = @EventType
        AND et.EventSubType = 'ESaverClosedGoalReachedLoyaltyThreeDaysBack'
        AND et.IsActive     = 'Y'
    LEFT JOIN dbo.CBG_ESaverNotification n
         ON n.EventType     = et.EventType
        AND n.EventSubType  = et.EventSubType
        AND n.AccountNumber = a.AccountNumber
    WHERE a.AccountStatus      = 'CLOSED'
      AND a.ESaverAccountType  = 'LoyaltyAccount'
      AND a.MaturityDate       < @ClosedDate3Back
      AND a.CurrentBalanceAsOnMaturityDate >= a.MaturityAmountAsOnMaturityDate
      AND ISNULL(n.LastNotificationCount, 0) < et.ThresholdLimit;

END;
GO
