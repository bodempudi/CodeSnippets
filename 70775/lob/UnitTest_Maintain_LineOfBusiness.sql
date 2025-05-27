
-- =====================================================================================================
-- UNIT TESTING SCRIPT FOR usp_Maintain_LineOfBusiness
-- Assumptions:
--   - Valid Tenant exists with known TenantCode = 'TESTTENANT', TenantISOcountryCode = 'IN'
--   - Procedure performs soft delete and writes to Audit_LineOfBusiness
--   - Run in TEST environment
-- =====================================================================================================

-- STEP 1: CREATE
EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'CREATE'
    , @I_LineOfBusinessID     = NULL
    , @I_TenantISOcountryCode = 'IN'
    , @I_TenantCode           = 'TESTTENANT'
    , @I_LineOfBusinessName   = 'Insurance'
    , @I_UserNote             = 'LOB created via unit test'
    , @I_UserID               = 'unit_tester'

-- STEP 2: FETCH CREATED RECORD
SELECT * FROM InMem.LineOfBusiness
WHERE LineOfBusinessName = 'Insurance'
AND TenantID IN (
    SELECT TenantID FROM InMem.Tenant WHERE TenantCode = 'TESTTENANT' AND TenantISOcountryCode = 'IN'
)

-- STEP 3: UPDATE
-- (Replace below ID with the actual one fetched in Step 2 if manually testing)
DECLARE @LOBID BIGINT
SELECT @LOBID = LineOfBusinessID FROM InMem.LineOfBusiness
WHERE LineOfBusinessName = 'Insurance'
AND TenantID IN (
    SELECT TenantID FROM InMem.Tenant WHERE TenantCode = 'TESTTENANT' AND TenantISOcountryCode = 'IN'
)

EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'UPDATE'
    , @I_LineOfBusinessID     = @LOBID
    , @I_TenantISOcountryCode = 'IN'
    , @I_TenantCode           = 'TESTTENANT'
    , @I_LineOfBusinessName   = 'Insurance Updated'
    , @I_UserNote             = 'LOB updated via unit test'
    , @I_UserID               = 'unit_tester'

-- STEP 4: UPSERT (should update)
EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'UPSERT'
    , @I_LineOfBusinessID     = NULL
    , @I_TenantISOcountryCode = 'IN'
    , @I_TenantCode           = 'TESTTENANT'
    , @I_LineOfBusinessName   = 'Insurance Updated'
    , @I_UserNote             = 'LOB upsert test'
    , @I_UserID               = 'unit_tester'

-- STEP 5: DELETE
EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'DELETE'
    , @I_LineOfBusinessID     = @LOBID
    , @I_TenantISOcountryCode = 'IN'
    , @I_TenantCode           = 'TESTTENANT'
    , @I_LineOfBusinessName   = NULL
    , @I_UserNote             = NULL
    , @I_UserID               = 'unit_tester'

-- STEP 6: VALIDATE AUDIT ENTRIES
SELECT * FROM dbo.Audit_LineOfBusiness
WHERE TenantID = (
    SELECT TenantID FROM InMem.Tenant WHERE TenantCode = 'TESTTENANT' AND TenantISOcountryCode = 'IN'
)
ORDER BY AuditDateTime DESC
