
-- =====================================================================================================================
-- Test Script for InMem.usp_Maintain_BrandType
-- Includes CREATE, UPSERT, UPDATE, DELETE (soft), REACTIVATION, VALIDATION & AUDIT
-- =====================================================================================================================

-- Clean up
DELETE FROM InMem.BrandType WHERE BrandTypeCode LIKE 'TEST_%';

-- =====================================================================================================================
-- 1. Valid CREATE
-- =====================================================================================================================
EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'CREATE',
    @I_BrandTypeID           = NULL,
    @I_BrandTypeCode         = 'TEST_BRAND_01',
    @I_BrandTypeNameEN       = 'Test Brand One',
    @I_IsCategoryApplicable  = 'Y',
    @I_UserNote              = 'Unit test',
    @I_UserID                = 'test_user';

-- Validate
SELECT * FROM InMem.BrandType WHERE BrandTypeCode = 'TEST_BRAND_01';

-- =====================================================================================================================
-- 2. Duplicate CREATE (Active Exists) – Expect Error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'CREATE',
    @I_BrandTypeID           = NULL,
    @I_BrandTypeCode         = 'TEST_BRAND_01',
    @I_BrandTypeNameEN       = 'Test Brand One Duplicate',
    @I_IsCategoryApplicable  = 'Y',
    @I_UserNote              = 'Dup create',
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 3. Soft DELETE
-- =====================================================================================================================
DECLARE @BrandTypeID BIGINT = (
    SELECT TOP 1 BrandTypeID FROM InMem.BrandType WHERE BrandTypeCode = 'TEST_BRAND_01' AND IsActive = 'Y'
);

EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'DELETE',
    @I_BrandTypeID           = @BrandTypeID,
    @I_BrandTypeCode         = NULL,
    @I_BrandTypeNameEN       = NULL,
    @I_IsCategoryApplicable  = NULL,
    @I_UserNote              = NULL,
    @I_UserID                = 'test_user';

-- Validate Soft Delete
SELECT * FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID;

-- =====================================================================================================================
-- 4. Reactivate using CREATE
-- =====================================================================================================================
EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'CREATE',
    @I_BrandTypeID           = NULL,
    @I_BrandTypeCode         = 'TEST_BRAND_01',
    @I_BrandTypeNameEN       = 'Test Brand One Reactivated',
    @I_IsCategoryApplicable  = 'N',
    @I_UserNote              = 'Reactivated',
    @I_UserID                = 'test_user';

-- Validate Reactivation
SELECT * FROM InMem.BrandType WHERE BrandTypeCode = 'TEST_BRAND_01';

-- =====================================================================================================================
-- 5. Valid UPSERT (New Record)
-- =====================================================================================================================
EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'UPSERT',
    @I_BrandTypeID           = NULL,
    @I_BrandTypeCode         = 'TEST_BRAND_02',
    @I_BrandTypeNameEN       = 'Brand Two',
    @I_IsCategoryApplicable  = 'Y',
    @I_UserNote              = 'New Upsert',
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 6. Valid UPSERT (Update Existing)
-- =====================================================================================================================
EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'UPSERT',
    @I_BrandTypeID           = NULL,
    @I_BrandTypeCode         = 'TEST_BRAND_02',
    @I_BrandTypeNameEN       = 'Brand Two Updated',
    @I_IsCategoryApplicable  = 'N',
    @I_UserNote              = 'Upsert updated',
    @I_UserID                = 'test_user';

-- Validate update
SELECT * FROM InMem.BrandType WHERE BrandTypeCode = 'TEST_BRAND_02';

-- =====================================================================================================================
-- 7. Valid UPDATE
-- =====================================================================================================================
DECLARE @BrandTypeID_Update BIGINT = (
    SELECT TOP 1 BrandTypeID FROM InMem.BrandType WHERE BrandTypeCode = 'TEST_BRAND_02'
);

EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'UPDATE',
    @I_BrandTypeID           = @BrandTypeID_Update,
    @I_BrandTypeCode         = 'TEST_BRAND_02',
    @I_BrandTypeNameEN       = 'Brand Two Final',
    @I_IsCategoryApplicable  = 'Y',
    @I_UserNote              = 'Direct Update',
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 8. DELETE on Non-Existent ID – Expect Error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'DELETE',
    @I_BrandTypeID           = 99999999,
    @I_BrandTypeCode         = NULL,
    @I_BrandTypeNameEN       = NULL,
    @I_IsCategoryApplicable  = NULL,
    @I_UserNote              = NULL,
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 9. CREATE with Missing Mandatory (BrandTypeCode) – Expect Error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'CREATE',
    @I_BrandTypeID           = NULL,
    @I_BrandTypeCode         = NULL,
    @I_BrandTypeNameEN       = 'Missing Code',
    @I_IsCategoryApplicable  = 'Y',
    @I_UserNote              = 'Missing',
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 10. Invalid ActionType – Expect Error
-- =====================================================================================================================
EXEC InMem.usp_Maintain_BrandType
    @I_ActionType            = 'JUNK',
    @I_BrandTypeID           = NULL,
    @I_BrandTypeCode         = 'TEST_BRAND_03',
    @I_BrandTypeNameEN       = 'Invalid',
    @I_IsCategoryApplicable  = 'Y',
    @I_UserNote              = 'Invalid ActionType',
    @I_UserID                = 'test_user';

-- =====================================================================================================================
-- 11. Audit Check
-- =====================================================================================================================
SELECT * FROM dbo.Audit_BrandType WHERE BrandTypeCode LIKE 'TEST_%' ORDER BY AuditDateTime DESC;
