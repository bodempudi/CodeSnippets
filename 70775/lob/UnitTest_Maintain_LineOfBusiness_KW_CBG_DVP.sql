
-- =====================================================================================================
-- UNIT TESTING SCRIPT FOR usp_Maintain_LineOfBusiness (Updated for TenantCode: CBG, DVP and ISO Code: KW)
-- =====================================================================================================

-- STEP 1: CREATE (Tenant: CBG, ISO Code: KW)
EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'CREATE'
    , @I_LineOfBusinessID     = NULL
    , @I_TenantISOcountryCode = 'KW'
    , @I_TenantCode           = 'CBG'
    , @I_LineOfBusinessName   = 'Corporate Banking'
    , @I_UserNote             = 'Created for CBG'
    , @I_UserID               = 'unit_tester'

-- STEP 2: CREATE (Tenant: DVP, ISO Code: KW)
EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'CREATE'
    , @I_LineOfBusinessID     = NULL
    , @I_TenantISOcountryCode = 'KW'
    , @I_TenantCode           = 'DVP'
    , @I_LineOfBusinessName   = 'Digital Ventures'
    , @I_UserNote             = 'Created for DVP'
    , @I_UserID               = 'unit_tester'

-- STEP 3: FETCH CREATED RECORDS
SELECT * FROM InMem.LineOfBusiness
WHERE LineOfBusinessName IN ('Corporate Banking', 'Digital Ventures')
AND TenantID IN (
    SELECT TenantID FROM InMem.Tenant WHERE TenantCode IN ('CBG', 'DVP') AND TenantISOcountryCode = 'KW'
)

-- STEP 4: UPDATE Corporate Banking
DECLARE @LOBID_CBG BIGINT
SELECT @LOBID_CBG = LineOfBusinessID FROM InMem.LineOfBusiness
WHERE LineOfBusinessName = 'Corporate Banking'
AND TenantID = (SELECT TenantID FROM InMem.Tenant WHERE TenantCode = 'CBG' AND TenantISOcountryCode = 'KW')

EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'UPDATE'
    , @I_LineOfBusinessID     = @LOBID_CBG
    , @I_TenantISOcountryCode = 'KW'
    , @I_TenantCode           = 'CBG'
    , @I_LineOfBusinessName   = 'Corporate Banking Updated'
    , @I_UserNote             = 'Update test for CBG'
    , @I_UserID               = 'unit_tester'

-- STEP 5: UPSERT Digital Ventures (should update)
EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'UPSERT'
    , @I_LineOfBusinessID     = NULL
    , @I_TenantISOcountryCode = 'KW'
    , @I_TenantCode           = 'DVP'
    , @I_LineOfBusinessName   = 'Digital Ventures'
    , @I_UserNote             = 'Upsert test for DVP'
    , @I_UserID               = 'unit_tester'

-- STEP 6: DELETE Corporate Banking
EXEC InMem.usp_Maintain_LineOfBusiness
      @I_ActionType           = 'DELETE'
    , @I_LineOfBusinessID     = @LOBID_CBG
    , @I_TenantISOcountryCode = 'KW'
    , @I_TenantCode           = 'CBG'
    , @I_LineOfBusinessName   = NULL
    , @I_UserNote             = NULL
    , @I_UserID               = 'unit_tester'

-- STEP 7: VALIDATE AUDIT ENTRIES
SELECT * FROM dbo.Audit_LineOfBusiness
WHERE TenantID IN (
    SELECT TenantID FROM InMem.Tenant WHERE TenantCode IN ('CBG', 'DVP') AND TenantISOcountryCode = 'KW'
)
ORDER BY AuditDateTime DESC
