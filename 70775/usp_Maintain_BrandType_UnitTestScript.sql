-- ====================================================================================================
-- Unit Test Execution Script for usp_Maintain_BrandType
-- Date: 25-May-2025
-- Description: Executes and verifies multiple test cases with expected status and message.
-- ====================================================================================================

-- Assumes a temp table to capture results
IF OBJECT_ID('tempdb..#TestResults') IS NOT NULL
    DROP TABLE #TestResults;

CREATE TABLE #TestResults (
    TestCaseID        VARCHAR(20),
    Description       VARCHAR(512),
    ExpectedStatus    BIT,
    ExpectedMessage   VARCHAR(128),
    ActualStatus      BIT,
    ActualMessage     VARCHAR(128),
    TestResult        VARCHAR(20)
);

-- ===================================================================================
-- Test Case TC_001: CREATE – Valid new BrandTypeCode
-- ===================================================================================
DECLARE @StatusCode BIT, @StatusMessage VARCHAR(128);

EXEC dbo.usp_Maintain_BrandType
    @I_ActionType           = 'CREATE',
    @I_BrandTypeCode        = 'BT001',
    @I_BrandTypeNameEN      = 'Test',
    @I_UserID               = 'admin';

SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage;

INSERT INTO #TestResults
SELECT
    'TC_001',
    'CREATE – Valid new BrandTypeCode',
    1,
    'SUCCESS',
    @StatusCode,
    @StatusMessage,
    CASE
        WHEN @StatusCode = 1 AND @StatusMessage = 'SUCCESS' THEN 'PASS'
        ELSE 'FAIL'
    END;

-- Additional test cases would follow the same pattern as above
-- For brevity, only TC_001 is written here, but others (TC_002 to TC_010) would follow similarly.

-- ===================================================================================
-- View Test Results
-- ===================================================================================
SELECT * FROM #TestResults;
