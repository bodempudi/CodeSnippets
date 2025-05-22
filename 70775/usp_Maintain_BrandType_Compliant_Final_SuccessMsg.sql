CREATE PROCEDURE dbo.usp_Maintain_BrandType
    @I_ActionType              VARCHAR(20),     -- CREATE / UPDATE / UPSERT / DELETE
    @I_BrandTypeID             BIGINT       = NULL,
    @I_BrandTypeCode           VARCHAR(32)   = NULL,
    @I_BrandTypeNameEN         VARCHAR(128)  = NULL,
    @I_IsCategoryApplicable    CHAR(1)       = NULL,
    @I_UserNote                VARCHAR(2048) = NULL,
    @I_UserID                  VARCHAR(20)   = NULL
AS
/*****************************************************************************************
    Name      : usp_Maintain_BrandType
    Purpose   : To Create / Update / Delete / Upsert data in BrandType table and audit it
    Author    : Venkat Bodempudi
    Date      : 22-May-2025

    Sample Execution:

    EXEC dbo.usp_Maintain_BrandType
        @I_ActionType            = 'UPSERT',
        @I_BrandTypeID           = 1001,
        @I_BrandTypeCode         = 'MERCH',
        @I_BrandTypeNameEN       = 'Merchant Code for all Non-EMI registered Merchant Transaction',
        @I_IsCategoryApplicable  = 'N',
        @I_UserNote              = 'System',
        @I_UserID                = 'venkat';

******************************************************************************************
    Change History:
******************************************************************************************
    Date         Author              Description                         Status
    -----------  ------------------  ----------------------------------  ----------------
    22-May-2025  Venkat Bodempudi    Created with audit logging             Development Phase
*****************************************************************************************/
BEGIN
    ------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------------------------------
-- Declare local variables
---------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------
    DECLARE
  @CurrentDateTime   DATETIME,
  @StatusCode        BIT,
  @StatusMessage     VARCHAR(256),
  @AuditActionType   VARCHAR(32)

SELECT @CurrentDateTime = GETDATE()


    ------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------------------------------
-- Validation Block
---------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------
    IF @I_ActionType IS NULL OR LTRIM(RTRIM(@I_ActionType)) = ''
    BEGIN
        SELECT
  @StatusCode    = CONVERT(BIT, 1),
  @StatusMessage = CONVERT(VARCHAR(128), 'ActionType is mandatory.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    IF @I_ActionType NOT IN ('CREATE', 'UPDATE', 'UPSERT', 'DELETE')
    BEGIN
        SELECT
  @StatusCode    = CONVERT(BIT, 1),
  @StatusMessage = CONVERT(VARCHAR(128), 'Invalid ActionType.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    IF @I_UserID IS NULL OR LTRIM(RTRIM(@I_UserID)) = ''
    BEGIN
        SELECT
  @StatusCode    = CONVERT(BIT, 1),
  @StatusMessage = CONVERT(VARCHAR(128), 'UserID is mandatory.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    IF @I_ActionType IN ('CREATE', 'UPDATE', 'UPSERT')
    BEGIN
        IF @I_BrandTypeCode IS NULL OR LTRIM(RTRIM(@I_BrandTypeCode)) = ''
        BEGIN
            SELECT
  @StatusCode    = CONVERT(BIT, 1),
  @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeCode is mandatory.')
            SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
            RETURN
        END

        IF @I_BrandTypeNameEN IS NULL OR LTRIM(RTRIM(@I_BrandTypeNameEN)) = ''
        BEGIN
            SELECT
  @StatusCode    = CONVERT(BIT, 1),
  @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeNameEN is mandatory.')
            SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
            RETURN
        END
    END

    IF @I_ActionType IN ('UPDATE', 'DELETE', 'UPSERT') AND @I_BrandTypeID IS NULL
    BEGIN
        SELECT
  @StatusCode    = CONVERT(BIT, 1),
  @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeID is mandatory.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    ------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------------------------------
-- Perform CREATE Operation
--------------------------------------------------------------------------------------------------------------------------------------- (or UPSERT insert)
    ------------------------------------------------------
    IF (@I_ActionType = 'CREATE')
       OR (@I_ActionType = 'UPSERT' AND NOT EXISTS (
           SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID
       ))
    BEGIN
        INSERT INTO InMem.BrandType (
  BrandTypeCode
 ,BrandTypeNameEN
 ,IsCategoryApplicable
 ,UserNote
 ,CreateUserID
 ,CreateDateTime
)
VALUES (
            @I_BrandTypeCode, @I_BrandTypeNameEN, @I_IsCategoryApplicable,
            @I_UserNote, @I_UserID, @CurrentDateTime
        )

        SELECT @AuditActionType = CASE 
            WHEN @I_ActionType = 'UPSERT' THEN 'CREATE-UPSERT' 
            ELSE 'CREATE-CREATE' 
        END

        INSERT INTO dbo.Audit_BrandType (
  BrandTypeID
 ,BrandTypeCode
 ,BrandTypeNameEN
 ,IsCategoryApplicable
 ,UserNote
 ,CreateUserID
 ,CreateDateTime
 ,UpdateUserID
 ,UpdateDateTime
 ,AuditUserID
 ,AuditDateTime
 ,AuditActionType
)
SELECT
            BrandTypeID, BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable,
            UserNote, CreateUserID, CreateDateTime,
            UpdateUserID, UpdateDateTime,
            @I_UserID, @CurrentDateTime, @AuditActionType
        FROM InMem.BrandType
        WHERE BrandTypeCode = @I_BrandTypeCode

        SELECT @StatusCode = 0,
       @StatusMessage = @AuditActionType + ' executed successfully.'
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    ------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------------------------------
-- Perform UPDATE Operation
--------------------------------------------------------------------------------------------------------------------------------------- (or UPSERT update)
    ------------------------------------------------------
    IF (@I_ActionType = 'UPDATE')
       OR (@I_ActionType = 'UPSERT' AND EXISTS (
           SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID
       ))
    BEGIN
        UPDATE InMem.BrandType
        SET BrandTypeCode         = @I_BrandTypeCode,
            BrandTypeNameEN       = @I_BrandTypeNameEN,
            IsCategoryApplicable  = @I_IsCategoryApplicable,
            UserNote              = @I_UserNote,
            UpdateUserID          = @I_UserID,
            UpdateDateTime        = @CurrentDateTime
        WHERE BrandTypeID = @I_BrandTypeID

        SELECT @AuditActionType = CASE 
            WHEN @I_ActionType = 'UPSERT' THEN 'UPDATE-UPSERT' 
            ELSE 'UPDATE-UPDATE' 
        END

        INSERT INTO dbo.Audit_BrandType (
  BrandTypeID
 ,BrandTypeCode
 ,BrandTypeNameEN
 ,IsCategoryApplicable
 ,UserNote
 ,CreateUserID
 ,CreateDateTime
 ,UpdateUserID
 ,UpdateDateTime
 ,AuditUserID
 ,AuditDateTime
 ,AuditActionType
)
SELECT
            BrandTypeID, BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable,
            UserNote, CreateUserID, CreateDateTime,
            UpdateUserID, UpdateDateTime,
            @I_UserID, @CurrentDateTime, @AuditActionType
        FROM InMem.BrandType
        WHERE BrandTypeID = @I_BrandTypeID

        SELECT @StatusCode = 0,
       @StatusMessage = @AuditActionType + ' executed successfully.'
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    ------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------------------------------
-- Perform DELETE Operation
---------------------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------
    IF @I_ActionType = 'DELETE'
    BEGIN
        INSERT INTO dbo.Audit_BrandType (
  BrandTypeID
 ,BrandTypeCode
 ,BrandTypeNameEN
 ,IsCategoryApplicable
 ,UserNote
 ,CreateUserID
 ,CreateDateTime
 ,UpdateUserID
 ,UpdateDateTime
 ,AuditUserID
 ,AuditDateTime
 ,AuditActionType
)
SELECT
            BrandTypeID, BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable,
            UserNote, CreateUserID, CreateDateTime,
            UpdateUserID, UpdateDateTime,
            @I_UserID, @CurrentDateTime, 'DELETE-DELETE'
        FROM InMem.BrandType
        WHERE BrandTypeID = @I_BrandTypeID

        DELETE FROM InMem.BrandType
        WHERE BrandTypeID = @I_BrandTypeID

        SELECT
  @StatusCode    = CONVERT(BIT, 0),
  @StatusMessage = CONVERT(VARCHAR(128), 'success')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END
END

/*****************************************************************************************
    Sample Unit Tests (Run one at a time)
*****************************************************************************************/

---------------------------------------------------------------------------------------------------------------------------------------
-- Sample Unit Tests
--------------------------------------------------------------------------------------------------------------------------------------- 1: CREATE-CREATE
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType            = 'CREATE',
    @I_BrandTypeCode         = 'BR001',
    @I_BrandTypeNameEN       = 'BrandType - Create',
    @I_IsCategoryApplicable  = 'Y',
    @I_UserNote              = 'Created via unit test',
    @I_UserID                = 'unittest_user';

-- Test Case 2: UPDATE-UPDATE
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType            = 'UPDATE',
    @I_BrandTypeID           = 1, -- Replace with valid ID from Test 1
    @I_BrandTypeCode         = 'BR001-UPD',
    @I_BrandTypeNameEN       = 'BrandType - Updated',
    @I_IsCategoryApplicable  = 'N',
    @I_UserNote              = 'Updated via unit test',
    @I_UserID                = 'unittest_user';

-- Test Case 3: DELETE-DELETE
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType            = 'DELETE',
    @I_BrandTypeID           = 1, -- Replace with valid ID
    @I_UserID                = 'unittest_user';

-- Test Case 4: UPSERT as INSERT (CREATE-UPSERT)
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType            = 'UPSERT',
    @I_BrandTypeID           = 9999, -- Assume this ID doesn't exist
    @I_BrandTypeCode         = 'BR999',
    @I_BrandTypeNameEN       = 'BrandType - UPSERT insert',
    @I_IsCategoryApplicable  = 'Y',
    @I_UserNote              = 'UPSERT insert path',
    @I_UserID                = 'unittest_user';

-- Test Case 5: UPSERT as UPDATE (UPDATE-UPSERT)
EXEC dbo.usp_Maintain_BrandType
    @I_ActionType            = 'UPSERT',
    @I_BrandTypeID           = 9999, -- ID from previous UPSERT
    @I_BrandTypeCode         = 'BR999-UPD',
    @I_BrandTypeNameEN       = 'BrandType - UPSERT update',
    @I_IsCategoryApplicable  = 'N',
    @I_UserNote              = 'UPSERT update path',
    @I_UserID                = 'unittest_user';
