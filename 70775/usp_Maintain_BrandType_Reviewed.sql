-- =========================================================================================================================
-- Author      : Venkat Bodempudi
-- Create Date : 25-May-2025
-- Description : Maintain procedure for InMem.BrandType with support for CREATE, UPDATE, DELETE (soft), and UPSERT.
--               Includes audit logging and comprehensive validation.
-- =========================================================================================================================

USE InMem
GO

CREATE OR ALTER PROCEDURE dbo.usp_Maintain_BrandType
(
    @I_ActionType              VARCHAR(20)  -- 'CREATE', 'UPDATE', 'DELETE', 'UPSERT'
   ,@I_BrandTypeID             BIGINT       = NULL
   ,@I_BrandTypeCode           VARCHAR(32)  = NULL
   ,@I_BrandTypeNameEN         VARCHAR(128) = NULL
   ,@I_IsCategoryApplicable    CHAR(1)      = NULL  -- Optional; default in app layer as needed
   ,@I_UserNote                VARCHAR(2048)= NULL
   ,@I_UserID                  VARCHAR(20)  = NULL
)
AS
BEGIN

    -----------------------------------------------------------------------------------------------------------------------
    -- Declare Internal Variables
    -----------------------------------------------------------------------------------------------------------------------
    DECLARE
        @CurrentDateTime DATETIME      = GETDATE()
       ,@StatusCode      BIT
       ,@StatusMessage   VARCHAR(4096)
       ,@ExistingID      BIGINT

    -----------------------------------------------------------------------------------------------------------------------
    -- Validate ActionType
    -----------------------------------------------------------------------------------------------------------------------
    IF ISNULL(@I_ActionType, '') NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT')
    BEGIN

        SELECT
            @StatusCode    = CONVERT(BIT, 0)
           ,@StatusMessage = CONVERT(VARCHAR(128), 'Invalid ActionType Provided.')

        RETURN
    END

    -----------------------------------------------------------------------------------------------------------------------
    -- Validate UserID
    -----------------------------------------------------------------------------------------------------------------------
    IF LTRIM(RTRIM(ISNULL(@I_UserID, ''))) = ''
    BEGIN

        SELECT
            @StatusCode    = CONVERT(BIT, 0)
           ,@StatusMessage = CONVERT(VARCHAR(128), 'UserID is mandatory.')

        RETURN
    END

    -----------------------------------------------------------------------------------------------------------------------
    -- Validate BrandTypeCode on CREATE/UPDATE/UPSERT
    -----------------------------------------------------------------------------------------------------------------------
    IF @I_ActionType IN ('CREATE', 'UPDATE', 'UPSERT')
    BEGIN
        IF LTRIM(RTRIM(ISNULL(@I_BrandTypeCode, ''))) = ''
        BEGIN
            SELECT
                @StatusCode    = CONVERT(BIT, 0)
               ,@StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeCode is mandatory.')

            RETURN
        END
    END

    -----------------------------------------------------------------------------------------------------------------------
    -- Conflict: BrandTypeID and BrandTypeCode mismatch
    -----------------------------------------------------------------------------------------------------------------------
    IF @I_ActionType = 'UPSERT' AND @I_BrandTypeID IS NOT NULL AND @I_BrandTypeCode IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1
            FROM InMem.BrandType WITH (NOLOCK)
            WHERE BrandTypeID     = @I_BrandTypeID
              AND BrandTypeCode   = @I_BrandTypeCode
        )
        BEGIN
            SELECT
                @StatusCode    = CONVERT(BIT, 0)
               ,@StatusMessage = CONVERT(VARCHAR(128), 'Mismatch: BrandTypeID and BrandTypeCode refer to different records.')

            RETURN
        END
    END

    -----------------------------------------------------------------------------------------------------------------------
    -- Duplicate Check on CREATE
    -----------------------------------------------------------------------------------------------------------------------
    IF @I_ActionType = 'CREATE'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM InMem.BrandType WITH (NOLOCK)
            WHERE BrandTypeCode = @I_BrandTypeCode
        )
        BEGIN
            SELECT
                @StatusCode    = CONVERT(BIT, 0)
               ,@StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeCode already exists.')

            RETURN
        END
    END

    -----------------------------------------------------------------------------------------------------------------------
    -- Mandatory BrandTypeID for UPDATE/DELETE
    -----------------------------------------------------------------------------------------------------------------------
    IF @I_ActionType IN ('UPDATE', 'DELETE')
    BEGIN
        IF @I_BrandTypeID IS NULL
        BEGIN
            SELECT
                @StatusCode    = CONVERT(BIT, 0)
               ,@StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeID is mandatory for ActionType ' + @I_ActionType)

            RETURN
        END
    END

    -----------------------------------------------------------------------------------------------------------------------
    -- UPSERT: Ensure record exists for update or prepare for insert
    -----------------------------------------------------------------------------------------------------------------------
    IF @I_ActionType = 'UPSERT'
    BEGIN
        SELECT TOP 1 @ExistingID = BrandTypeID
        FROM InMem.BrandType WITH (NOLOCK)
        WHERE BrandTypeID   = @I_BrandTypeID
           OR BrandTypeCode = @I_BrandTypeCode
    END

    -----------------------------------------------------------------------------------------------------------------------
    -- Begin Transaction for Main Operation
    -----------------------------------------------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION

        IF @I_ActionType = 'CREATE'
        BEGIN
            INSERT INTO InMem.BrandType
            (
                BrandTypeCode
               ,BrandTypeNameEN
               ,IsCategoryApplicable
               ,UserNote
               ,IsActive
               ,CreateUserID
               ,CreateDateTime
               ,UpdateUserID
               ,UpdateDateTime
            )
            SELECT
                @I_BrandTypeCode
               ,@I_BrandTypeNameEN
               ,@I_IsCategoryApplicable
               ,@I_UserNote
               ,'Y'
               ,@I_UserID
               ,@CurrentDateTime
               ,@I_UserID
               ,@CurrentDateTime
        END

        ELSE IF @I_ActionType = 'UPDATE'
        BEGIN
            UPDATE InMem.BrandType
            SET
                BrandTypeNameEN      = @I_BrandTypeNameEN
               ,IsCategoryApplicable = @I_IsCategoryApplicable
               ,UserNote             = @I_UserNote
               ,UpdateUserID         = @I_UserID
               ,UpdateDateTime       = @CurrentDateTime
            WHERE BrandTypeID = @I_BrandTypeID
        END

        ELSE IF @I_ActionType = 'DELETE'
        BEGIN
            UPDATE InMem.BrandType
            SET
                IsActive        = 'N'
               ,UpdateUserID    = @I_UserID
               ,UpdateDateTime  = @CurrentDateTime
            WHERE BrandTypeID = @I_BrandTypeID
        END

        ELSE IF @I_ActionType = 'UPSERT'
        BEGIN
            IF @ExistingID IS NOT NULL
            BEGIN
                UPDATE InMem.BrandType
                SET
                    BrandTypeNameEN      = @I_BrandTypeNameEN
                   ,IsCategoryApplicable = @I_IsCategoryApplicable
                   ,UserNote             = @I_UserNote
                   ,IsActive             = 'Y'
                   ,UpdateUserID         = @I_UserID
                   ,UpdateDateTime       = @CurrentDateTime
                WHERE BrandTypeID = @ExistingID
            END
            ELSE
            BEGIN
                INSERT INTO InMem.BrandType
                (
                    BrandTypeCode
                   ,BrandTypeNameEN
                   ,IsCategoryApplicable
                   ,UserNote
                   ,IsActive
                   ,CreateUserID
                   ,CreateDateTime
                   ,UpdateUserID
                   ,UpdateDateTime
                )
                SELECT
                    @I_BrandTypeCode
                   ,@I_BrandTypeNameEN
                   ,@I_IsCategoryApplicable
                   ,@I_UserNote
                   ,'Y'
                   ,@I_UserID
                   ,@CurrentDateTime
                   ,@I_UserID
                   ,@CurrentDateTime
            END
        END

        -----------------------------------------------------------------------------------------------------------------------
        -- Audit Log
        -----------------------------------------------------------------------------------------------------------------------
        INSERT INTO dbo.Audit_BrandType
        (
            ActionType
           ,AuditDateTime
           ,AuditUserID
           ,BrandTypeCode
           ,BrandTypeNameEN
           ,IsCategoryApplicable
           ,UserNote
           ,IsActive
           ,CreateUserID
           ,CreateDateTime
           ,UpdateUserID
           ,UpdateDateTime
        )
        SELECT
            @I_ActionType
           ,@CurrentDateTime
           ,@I_UserID
           ,@I_BrandTypeCode
           ,@I_BrandTypeNameEN
           ,@I_IsCategoryApplicable
           ,@I_UserNote
           ,'Y'
           ,@I_UserID
           ,@CurrentDateTime
           ,@I_UserID
           ,@CurrentDateTime

        -----------------------------------------------------------------------------------------------------------------------
        -- Success Message
        -----------------------------------------------------------------------------------------------------------------------
        SELECT
            @StatusCode    = CONVERT(BIT, 1)
           ,@StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        SELECT
            @StatusCode    = CONVERT(BIT, 0)
           ,@StatusMessage = CONVERT(VARCHAR(128), ISNULL(ERROR_MESSAGE(), 'Unknown failure occurred.'))
    END CATCH

    SELECT
        @StatusCode    AS StatusCode
       ,@StatusMessage AS StatusMessage

END
