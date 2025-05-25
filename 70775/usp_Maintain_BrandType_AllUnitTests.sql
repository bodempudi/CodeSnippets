-- ====================================================================================================
-- Unit Test Execution Script for usp_Maintain_BrandType
-- Date: 25-May-2025
-- Description: Executes and verifies all unit test cases for the stored procedure.
-- ====================================================================================================

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

DECLARE @StatusCode BIT, @StatusMessage VARCHAR(128);

-- ===================================================================================
-- TC_001: CREATE – Valid new BrandTypeCode
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'CREATE',
    @I_BrandTypeCode = 'BT001',
    @I_BrandTypeNameEN = 'Test',
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_001', 'CREATE – Valid new BrandTypeCode', 1, 'SUCCESS', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 1 AND @StatusMessage = 'SUCCESS' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_002: CREATE – Duplicate BrandTypeCode
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'CREATE',
    @I_BrandTypeCode = 'BT001',
    @I_BrandTypeNameEN = 'Test',
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_002', 'CREATE – Duplicate BrandTypeCode', 0, 'BrandTypeCode already exists.', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 0 AND @StatusMessage = 'BrandTypeCode already exists.' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_003: UPDATE – Valid update using BrandTypeID
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'UPDATE',
    @I_BrandTypeID = 1,
    @I_BrandTypeNameEN = 'Updated',
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_003', 'UPDATE – Valid update using BrandTypeID', 1, 'SUCCESS', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 1 AND @StatusMessage = 'SUCCESS' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_004: UPDATE – Missing BrandTypeID
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'UPDATE',
    @I_BrandTypeCode = 'BT001',
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_004', 'UPDATE – Missing BrandTypeID', 0, 'BrandTypeID is mandatory for ActionType UPDATE', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 0 AND @StatusMessage LIKE 'BrandTypeID is mandatory%' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_005: DELETE – Soft delete
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'DELETE',
    @I_BrandTypeID = 1,
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_005', 'DELETE – Soft delete', 1, 'SUCCESS', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 1 AND @StatusMessage = 'SUCCESS' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_006: UPSERT – Insert new BrandType
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'UPSERT',
    @I_BrandTypeCode = 'BT002',
    @I_BrandTypeNameEN = 'New',
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_006', 'UPSERT – Insert new BrandType', 1, 'SUCCESS', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 1 AND @StatusMessage = 'SUCCESS' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_007: UPSERT – Update existing BrandType using BrandTypeID
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'UPSERT',
    @I_BrandTypeID = 1,
    @I_BrandTypeCode = 'BT001',
    @I_BrandTypeNameEN = 'Updated Again',
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_007', 'UPSERT – Update existing BrandType using BrandTypeID', 1, 'SUCCESS', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 1 AND @StatusMessage = 'SUCCESS' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_008: Invalid ActionType
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'INVALID',
    @I_BrandTypeCode = 'BTX',
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_008', 'Invalid ActionType', 0, 'Invalid ActionType Provided.', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 0 AND @StatusMessage = 'Invalid ActionType Provided.' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_009: Missing UserID
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'CREATE',
    @I_BrandTypeCode = 'BT003';

INSERT INTO #TestResults
SELECT 'TC_009', 'Missing UserID', 0, 'UserID is mandatory.', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 0 AND @StatusMessage = 'UserID is mandatory.' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- TC_010: UPSERT – BrandTypeID and BrandTypeCode mismatch
-- ===================================================================================
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType = 'UPSERT',
    @I_BrandTypeID = 1,
    @I_BrandTypeCode = 'BT999',
    @I_UserID = 'admin';

INSERT INTO #TestResults
SELECT 'TC_010', 'Conflict – BrandTypeID and BrandTypeCode mismatch', 0, 'Mismatch: BrandTypeID and BrandTypeCode refer to different records.', @StatusCode, @StatusMessage,
       CASE WHEN @StatusCode = 0 AND @StatusMessage LIKE 'Mismatch:%' THEN 'PASS' ELSE 'FAIL' END;

-- ===================================================================================
-- Display All Results
-- ===================================================================================
SELECT * FROM #TestResults;
