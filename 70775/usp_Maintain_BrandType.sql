
USE Dinarwise
GO

CREATE PROCEDURE dbo.usp_Maintain_BrandType
    @I_ActionType            VARCHAR(20),     -- CREATE/UPDATE/UPSERT/DELETE
    @I_BrandTypeID           BIGINT     = NULL,  -- Mandatory only for UPDATE/DELETE
    @I_BrandTypeCode         VARCHAR(32) = NULL,  -- Mandatory only for CREATE
    @I_BrandTypeNameEN       VARCHAR(128)= NULL,  -- Mandatory only for CREATE
    @I_IsCategoryApplicable  CHAR(1)     = NULL,  -- Non Mandatory - Default Value = N
    @I_UserNote              VARCHAR(2048)= NULL,
    @I_UserID                VARCHAR(20)  = NULL
AS
/*****************************************************************************************
* File  : usp_Maintain_BrandType
* Name  : usp_Maintain_BrandType
* Desc  : Using this SP to maintain data in BrandType table.
* Input : Parameters to insert/update/delete BrandType.
*
* Auth  : Venkat Bodempudi
* Date  : 22-May-2025
******************************************************************************************

EXEC usp_Maintain_BrandType
    @I_ActionType           = 'UPSERT',
    @I_BrandTypeID          = 1001,
    @I_BrandTypeCode        = 'MERCH',
    @I_BrandTypeNameEN      = 'Merchant Transaction',
    @I_IsCategoryApplicable = 'Y',
    @I_UserNote             = 'Auto generated',
    @I_UserID               = 'venkat'

******************************************************************************************
* Change History
******************************************************************************************
* Date       Author             Description                    Status
* ---------- ------------------ ----------------------------- ---------------------------
* 22-May-25  Venkat Bodempudi   Initial Version                Development Phase
*****************************************************************************************/

BEGIN

    DECLARE @CurrentDateTime  DATETIME = GETDATE()
    DECLARE @StatusCode       BIT
    DECLARE @StatusMessage    VARCHAR(128)
    DECLARE @AuditActionType  VARCHAR(32)

    IF @I_ActionType IS NULL OR LTRIM(RTRIM(@I_ActionType)) = ''
    BEGIN
        SELECT @StatusCode = CONVERT(BIT, 1),
               @StatusMessage = CONVERT(VARCHAR(128), 'ActionType is mandatory.')
        RETURN
    END

    IF @I_ActionType NOT IN ('CREATE', 'UPDATE', 'UPSERT', 'DELETE')
    BEGIN
        SELECT @StatusCode = CONVERT(BIT, 1),
               @StatusMessage = CONVERT(VARCHAR(128), 'Invalid ActionType.')
        RETURN
    END

    IF @I_UserID IS NULL OR LTRIM(RTRIM(@I_UserID)) = ''
    BEGIN
        SELECT @StatusCode = CONVERT(BIT, 1),
               @StatusMessage = CONVERT(VARCHAR(128), 'UserID is mandatory.')
        RETURN
    END

    IF @I_ActionType IN ('CREATE', 'UPDATE', 'UPSERT')
    BEGIN
        IF @I_BrandTypeCode IS NULL OR LTRIM(RTRIM(@I_BrandTypeCode)) = ''
        BEGIN
            SELECT @StatusCode = CONVERT(BIT, 1),
                   @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeCode is mandatory.')
            RETURN
        END

        IF @I_BrandTypeNameEN IS NULL OR LTRIM(RTRIM(@I_BrandTypeNameEN)) = ''
        BEGIN
            SELECT @StatusCode = CONVERT(BIT, 1),
                   @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeNameEN is mandatory.')
            RETURN
        END
    END

    IF @I_ActionType IN ('UPDATE', 'DELETE', 'UPSERT') AND @I_BrandTypeID IS NULL
    BEGIN
        SELECT @StatusCode = CONVERT(BIT, 1),
               @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeID is mandatory.')
        RETURN
    END

    BEGIN TRY
        BEGIN TRANSACTION

        IF @I_ActionType = 'CREATE'
           OR (@I_ActionType = 'UPSERT'
               AND NOT EXISTS (
                   SELECT 1 FROM InMem.BrandType WITH (NOLOCK)
                   WHERE BrandTypeID = @I_BrandTypeID
               ))
        BEGIN
            SELECT @AuditActionType = CASE WHEN @I_ActionType = 'UPSERT' THEN 'CREATE-UPSERT' ELSE 'CREATE-CREATE' END

            INSERT INTO InMem.BrandType
            (
                BrandTypeCode,
                BrandTypeNameEN,
                IsCategoryApplicable,
                UserNote,
                CreateUserID,
                CreateDateTime
            )
            SELECT
                BrandTypeCode         = @I_BrandTypeCode,
                BrandTypeNameEN       = @I_BrandTypeNameEN,
                IsCategoryApplicable  = @I_IsCategoryApplicable,
                UserNote              = @I_UserNote,
                CreateUserID          = @I_UserID,
                CreateDateTime        = @CurrentDateTime

            INSERT INTO dbo.Audit_BrandType
            (
                BrandTypeID,
                BrandTypeCode,
                BrandTypeNameEN,
                IsCategoryApplicable,
                UserNote,
                CreateUserID,
                CreateDateTime,
                UpdateUserID,
                UpdateDateTime,
                AuditUserID,
                AuditDateTime,
                AuditActionType
            )
            SELECT
                BrandTypeID         = BrandTypeID,
                BrandTypeCode       = BrandTypeCode,
                BrandTypeNameEN     = BrandTypeNameEN,
                IsCategoryApplicable = IsCategoryApplicable,
                UserNote            = UserNote,
                CreateUserID        = CreateUserID,
                CreateDateTime      = CreateDateTime,
                UpdateUserID        = UpdateUserID,
                UpdateDateTime      = UpdateDateTime,
                AuditUserID         = @I_UserID,
                AuditDateTime       = @CurrentDateTime,
                AuditActionType     = @AuditActionType
            FROM InMem.BrandType WITH (NOLOCK)
            WHERE BrandTypeCode = @I_BrandTypeCode
        END

        IF @I_ActionType = 'UPDATE'
           OR (@I_ActionType = 'UPSERT'
               AND EXISTS (
                   SELECT 1 FROM InMem.BrandType WITH (NOLOCK)
                   WHERE BrandTypeID = @I_BrandTypeID
               ))
        BEGIN
            SELECT @AuditActionType = CASE WHEN @I_ActionType = 'UPSERT' THEN 'UPDATE-UPSERT' ELSE 'UPDATE-UPDATE' END

            UPDATE InMem.BrandType
               SET BrandTypeCode         = @I_BrandTypeCode,
                   BrandTypeNameEN       = @I_BrandTypeNameEN,
                   IsCategoryApplicable  = @I_IsCategoryApplicable,
                   UserNote              = @I_UserNote,
                   UpdateUserID          = @I_UserID,
                   UpdateDateTime        = @CurrentDateTime
             WHERE BrandTypeID = @I_BrandTypeID

            INSERT INTO dbo.Audit_BrandType
            (
                BrandTypeID,
                BrandTypeCode,
                BrandTypeNameEN,
                IsCategoryApplicable,
                UserNote,
                CreateUserID,
                CreateDateTime,
                UpdateUserID,
                UpdateDateTime,
                AuditUserID,
                AuditDateTime,
                AuditActionType
            )
            SELECT
                BrandTypeID         = BrandTypeID,
                BrandTypeCode       = BrandTypeCode,
                BrandTypeNameEN     = BrandTypeNameEN,
                IsCategoryApplicable = IsCategoryApplicable,
                UserNote            = UserNote,
                CreateUserID        = CreateUserID,
                CreateDateTime      = CreateDateTime,
                UpdateUserID        = UpdateUserID,
                UpdateDateTime      = UpdateDateTime,
                AuditUserID         = @I_UserID,
                AuditDateTime       = @CurrentDateTime,
                AuditActionType     = @AuditActionType
            FROM InMem.BrandType WITH (NOLOCK)
            WHERE BrandTypeID = @I_BrandTypeID
        END

        IF @I_ActionType = 'DELETE'
        BEGIN
            INSERT INTO dbo.Audit_BrandType
            (
                BrandTypeID,
                BrandTypeCode,
                BrandTypeNameEN,
                IsCategoryApplicable,
                UserNote,
                CreateUserID,
                CreateDateTime,
                UpdateUserID,
                UpdateDateTime,
                AuditUserID,
                AuditDateTime,
                AuditActionType
            )
            SELECT
                BrandTypeID         = BrandTypeID,
                BrandTypeCode       = BrandTypeCode,
                BrandTypeNameEN     = BrandTypeNameEN,
                IsCategoryApplicable = IsCategoryApplicable,
                UserNote            = UserNote,
                CreateUserID        = CreateUserID,
                CreateDateTime      = CreateDateTime,
                UpdateUserID        = UpdateUserID,
                UpdateDateTime      = UpdateDateTime,
                AuditUserID         = @I_UserID,
                AuditDateTime       = @CurrentDateTime,
                AuditActionType     = 'DELETE-DELETE'
            FROM InMem.BrandType WITH (NOLOCK)
            WHERE BrandTypeID = @I_BrandTypeID

            DELETE FROM InMem.BrandType
            WHERE BrandTypeID = @I_BrandTypeID
        END

        COMMIT TRANSACTION

        SELECT @StatusCode = CONVERT(BIT, 0),
               @StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        SELECT @StatusCode = CONVERT(BIT, 1),
               @StatusMessage = CONVERT(VARCHAR(128), 'SP failed with error - ' + ERROR_MESSAGE())
    END CATCH

    SELECT @StatusCode AS StatusCode,
           @StatusMessage AS StatusMessage

END
