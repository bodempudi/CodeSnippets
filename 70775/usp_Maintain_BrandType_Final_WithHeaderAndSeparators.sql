/*****************************************************************************************
  Procedure Name  : usp_Maintain_BrandType
  Created By      : Venkat Bodempudi
  Created Date    : 22-May-2025
  Last Modified   : 22-May-2025
  Version         : 1.0
*****************************************************************************************/

/*****************************************************************************************
  Sample Execution:

  EXEC dbo.usp_Maintain_BrandType
      @I_ActionType            = 'UPSERT',
      @I_BrandTypeID           = 1001,
      @I_BrandTypeCode         = 'MERCH',
      @I_BrandTypeNameEN       = 'Merchant Transaction',
      @I_IsCategoryApplicable  = 'Y',
      @I_UserNote              = 'test note',
      @I_UserID                = 'venkat';
*****************************************************************************************/

-- usp_Maintain_BrandType
-- Fully compliant with Sachin's standards
-- Author: Venkat Bodempudi
-- Date: 22-May-2025

CREATE PROCEDURE dbo.usp_Maintain_BrandType
(
  @I_ActionType              VARCHAR(20)     -- CREATE / UPDATE / UPSERT / DELETE
 ,@I_BrandTypeID             BIGINT       = NULL
 ,@I_BrandTypeCode           VARCHAR(32)   = NULL
 ,@I_BrandTypeNameEN         VARCHAR(128)  = NULL
 ,@I_IsCategoryApplicable    CHAR(1)       = NULL
 ,@I_UserNote                VARCHAR(2048) = NULL
 ,@I_UserID                  VARCHAR(20)   = NULL
)
AS
BEGIN

---------------------------------------------------------------------------------------------------------------------------------------
-- Declare local variables
---------------------------------------------------------------------------------------------------------------------------------------
DECLARE
  @CurrentDateTime   DATETIME
 ,@StatusCode        BIT
 ,@StatusMessage     VARCHAR(128)
 ,@AuditActionType   VARCHAR(32)

SELECT @CurrentDateTime = GETDATE()

---------------------------------------------------------------------------------------------------------------------------------------
-- Validation Block
---------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------
IF @I_ActionType IS NULL
  OR LTRIM(RTRIM(@I_ActionType)) = ''
BEGIN

  SELECT
    @StatusCode    = CONVERT(BIT, 1)
   ,@StatusMessage = CONVERT(VARCHAR(128), 'ActionType is mandatory.')

  RETURN

END

---------------------------------------------------------------------------------------------------------------------------------------
IF @I_ActionType NOT IN ('CREATE', 'UPDATE', 'UPSERT', 'DELETE')
BEGIN

  SELECT
    @StatusCode    = CONVERT(BIT, 1)
   ,@StatusMessage = CONVERT(VARCHAR(128), 'Invalid ActionType.')

  RETURN

END

---------------------------------------------------------------------------------------------------------------------------------------
IF @I_UserID IS NULL
  OR LTRIM(RTRIM(@I_UserID)) = ''
BEGIN

  SELECT
    @StatusCode    = CONVERT(BIT, 1)
   ,@StatusMessage = CONVERT(VARCHAR(128), 'UserID is mandatory.')

  RETURN

END

---------------------------------------------------------------------------------------------------------------------------------------
IF @I_ActionType IN ('CREATE', 'UPDATE', 'UPSERT')
BEGIN

  IF @I_BrandTypeCode IS NULL
    OR LTRIM(RTRIM(@I_BrandTypeCode)) = ''
  BEGIN

    SELECT
      @StatusCode    = CONVERT(BIT, 1)
     ,@StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeCode is mandatory.')

    RETURN

  END

  IF @I_BrandTypeNameEN IS NULL
    OR LTRIM(RTRIM(@I_BrandTypeNameEN)) = ''
  BEGIN

    SELECT
      @StatusCode    = CONVERT(BIT, 1)
     ,@StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeNameEN is mandatory.')

    RETURN

  END

END

---------------------------------------------------------------------------------------------------------------------------------------
IF @I_ActionType IN ('UPDATE', 'DELETE', 'UPSERT')
  AND @I_BrandTypeID IS NULL
BEGIN

  SELECT
    @StatusCode    = CONVERT(BIT, 1)
   ,@StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeID is mandatory.')

  RETURN

END

---------------------------------------------------------------------------------------------------------------------------------------
-- Perform CREATE (or UPSERT insert)
---------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------
IF @I_ActionType = 'CREATE'
  OR (
       @I_ActionType = 'UPSERT'
   AND NOT EXISTS (
         SELECT 1
           FROM InMem.BrandType WITH (NOLOCK)
          WHERE
            BrandTypeID = @I_BrandTypeID
       )
     )
BEGIN

  SELECT @AuditActionType = CASE WHEN @I_ActionType = 'UPSERT' THEN 'CREATE-UPSERT' ELSE 'CREATE-CREATE' END

  INSERT INTO InMem.BrandType
  (
    BrandTypeCode
   ,BrandTypeNameEN
   ,IsCategoryApplicable
   ,UserNote
   ,CreateUserID
   ,CreateDateTime
  )
  SELECT
    BrandTypeCode         = @I_BrandTypeCode
   ,BrandTypeNameEN       = @I_BrandTypeNameEN
   ,IsCategoryApplicable  = @I_IsCategoryApplicable
   ,UserNote              = @I_UserNote
   ,CreateUserID          = @I_UserID
   ,CreateDateTime        = @CurrentDateTime

  INSERT INTO dbo.Audit_BrandType
  (
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
    BrandTypeID        = BrandTypeID
   ,BrandTypeCode      = BrandTypeCode
   ,BrandTypeNameEN    = BrandTypeNameEN
   ,IsCategoryApplicable = IsCategoryApplicable
   ,UserNote           = UserNote
   ,CreateUserID       = CreateUserID
   ,CreateDateTime     = CreateDateTime
   ,UpdateUserID       = UpdateUserID
   ,UpdateDateTime     = UpdateDateTime
   ,AuditUserID        = @I_UserID
   ,AuditDateTime      = @CurrentDateTime
   ,AuditActionType    = @AuditActionType
  FROM InMem.BrandType WITH (NOLOCK)
  WHERE
    BrandTypeCode = @I_BrandTypeCode

  SELECT
    @StatusCode    = CONVERT(BIT, 0)
   ,@StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

  RETURN

END
---------------------------------------------------------------------------------------------------------------------------------------
-- Perform UPDATE (or UPSERT update)
---------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------
IF @I_ActionType = 'UPDATE'
  OR (
       @I_ActionType = 'UPSERT'
   AND EXISTS (
         SELECT 1
           FROM InMem.BrandType WITH (NOLOCK)
          WHERE
            BrandTypeID = @I_BrandTypeID
       )
     )
BEGIN

  SELECT @AuditActionType = CASE WHEN @I_ActionType = 'UPSERT' THEN 'UPDATE-UPSERT' ELSE 'UPDATE-UPDATE' END

  UPDATE InMem.BrandType
     SET BrandTypeCode         = @I_BrandTypeCode
        ,BrandTypeNameEN       = @I_BrandTypeNameEN
        ,IsCategoryApplicable  = @I_IsCategoryApplicable
        ,UserNote              = @I_UserNote
        ,UpdateUserID          = @I_UserID
        ,UpdateDateTime        = @CurrentDateTime
   WHERE
     BrandTypeID = @I_BrandTypeID

  INSERT INTO dbo.Audit_BrandType
  (
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
    BrandTypeID         = BrandTypeID
   ,BrandTypeCode       = BrandTypeCode
   ,BrandTypeNameEN     = BrandTypeNameEN
   ,IsCategoryApplicable= IsCategoryApplicable
   ,UserNote            = UserNote
   ,CreateUserID        = CreateUserID
   ,CreateDateTime      = CreateDateTime
   ,UpdateUserID        = UpdateUserID
   ,UpdateDateTime      = UpdateDateTime
   ,AuditUserID         = @I_UserID
   ,AuditDateTime       = @CurrentDateTime
   ,AuditActionType     = @AuditActionType
  FROM InMem.BrandType WITH (NOLOCK)
  WHERE
    BrandTypeID = @I_BrandTypeID

  SELECT
    @StatusCode    = CONVERT(BIT, 0)
   ,@StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

  RETURN

END

---------------------------------------------------------------------------------------------------------------------------------------
-- Perform DELETE
---------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------
IF @I_ActionType = 'DELETE'
BEGIN

  INSERT INTO dbo.Audit_BrandType
  (
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
    BrandTypeID         = BrandTypeID
   ,BrandTypeCode       = BrandTypeCode
   ,BrandTypeNameEN     = BrandTypeNameEN
   ,IsCategoryApplicable= IsCategoryApplicable
   ,UserNote            = UserNote
   ,CreateUserID        = CreateUserID
   ,CreateDateTime      = CreateDateTime
   ,UpdateUserID        = UpdateUserID
   ,UpdateDateTime      = UpdateDateTime
   ,AuditUserID         = @I_UserID
   ,AuditDateTime       = @CurrentDateTime
   ,AuditActionType     = 'DELETE-DELETE'
  FROM InMem.BrandType WITH (NOLOCK)
  WHERE
    BrandTypeID = @I_BrandTypeID

  DELETE FROM InMem.BrandType
  WHERE
    BrandTypeID = @I_BrandTypeID

  SELECT
    @StatusCode    = CONVERT(BIT, 0)
   ,@StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

  RETURN

END
END