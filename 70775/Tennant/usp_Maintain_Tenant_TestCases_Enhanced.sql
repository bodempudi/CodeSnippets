
-- =====================================================================================================================
-- Enhanced Test Script for InMem.usp_Maintain_Tenant
-- Includes: CREATE, UPSERT, DELETE, REACTIVATE, INVALID, MISSING DATA
-- Adds: Result validation and UPDATE check
-- =====================================================================================================================

-- Clean up
DELETE FROM InMem.Tenant WHERE TenantCode LIKE 'TEST_%';

-- =====================================================================================================================
-- 1. Valid CREATE
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'CREATE',
    @I_TenantID              = NULL,
    @I_TenantCode            = 'TEST_TENANT_01',
    @I_TenantISOCountryCode  = 'IN',
    @I_DisplayCategoryPrecedence = NULL,
    @I_UserID                = 'test_user';

-- Validate
SELECT * FROM InMem.Tenant WHERE TenantCode = 'TEST_TENANT_01';

-- =====================================================================================================================
-- 2. Duplicate CREATE (Active Row) – Expect error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'CREATE',
    @I_TenantID              = NULL,
    @I_TenantCode            = 'TEST_TENANT_01',
    @I_TenantISOCountryCode  = 'IN',
    @I_DisplayCategoryPrecedence = NULL,
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 3. Soft DELETE
-- =====================================================================================================================
DECLARE @TenantID BIGINT = (
    SELECT TOP 1 TenantID FROM InMem.Tenant WHERE TenantCode = 'TEST_TENANT_01' AND IsActive = 'Y'
);

EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'DELETE',
    @I_TenantID              = @TenantID,
    @I_TenantCode            = NULL,
    @I_TenantISOCountryCode  = NULL,
    @I_DisplayCategoryPrecedence = NULL,
    @I_UserID                = 'test_user';

-- Validate soft delete
SELECT * FROM InMem.Tenant WHERE TenantID = @TenantID;

-- =====================================================================================================================
-- 4. Reactivate with CREATE (was soft-deleted)
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'CREATE',
    @I_TenantID              = NULL,
    @I_TenantCode            = 'TEST_TENANT_01',
    @I_TenantISOCountryCode  = 'IN',
    @I_DisplayCategoryPrecedence = NULL,
    @I_UserID                = 'test_user';

-- Validate reactivation
SELECT * FROM InMem.Tenant WHERE TenantCode = 'TEST_TENANT_01';

-- =====================================================================================================================
-- 5. Valid UPSERT - New Tenant
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'UPSERT',
    @I_TenantID              = NULL,
    @I_TenantCode            = 'TEST_TENANT_02',
    @I_TenantISOCountryCode  = 'US',
    @I_DisplayCategoryPrecedence = 1,
    @I_UserID                = 'test_user';

-- Validate insert
SELECT * FROM InMem.Tenant WHERE TenantCode = 'TEST_TENANT_02';

-- =====================================================================================================================
-- 6. Valid UPSERT - Existing Tenant (UPDATE)
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'UPSERT',
    @I_TenantID              = NULL,
    @I_TenantCode            = 'TEST_TENANT_02',
    @I_TenantISOCountryCode  = 'US',
    @I_DisplayCategoryPrecedence = 5,
    @I_UserID                = 'test_user';

-- Validate update
SELECT * FROM InMem.Tenant WHERE TenantCode = 'TEST_TENANT_02';

-- =====================================================================================================================
-- 7. Invalid ActionType – Expect error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'INVALID',
    @I_TenantID              = NULL,
    @I_TenantCode            = 'TEST_TENANT_03',
    @I_TenantISOCountryCode  = 'UK',
    @I_DisplayCategoryPrecedence = NULL,
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 8. Missing TenantCode – Expect error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'CREATE',
    @I_TenantID              = NULL,
    @I_TenantCode            = NULL,
    @I_TenantISOCountryCode  = 'UK',
    @I_DisplayCategoryPrecedence = NULL,
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 9. UPSERT without DisplayCategoryPrecedence – Expect error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'UPSERT',
    @I_TenantID              = NULL,
    @I_TenantCode            = 'TEST_TENANT_04',
    @I_TenantISOCountryCode  = 'CA',
    @I_DisplayCategoryPrecedence = NULL,
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 10. DELETE on Invalid TenantID – Expect error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_Tenant
    @I_ActionType            = 'DELETE',
    @I_TenantID              = 99999999,
    @I_TenantCode            = NULL,
    @I_TenantISOCountryCode  = NULL,
    @I_DisplayCategoryPrecedence = NULL,
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- Audit Check
-- =====================================================================================================================
SELECT * FROM dbo.Audit_Tenant WHERE TenantCode LIKE 'TEST_TENANT_%' ORDER BY AuditDateTime DESC;
