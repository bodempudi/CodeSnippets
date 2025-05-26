
USE InMem;
GO

---------------------------------------------------------------------------------------
-- Procedure: usp_Maintain_Tenant
-- Description: CREATE, UPDATE, DELETE, UPSERT for InMem.Tenant with audit logging
-- Note      : StatusCode = 0 (SUCCESS), 1 = ERROR; no RAISERROR used
-- Developer : Auto-generated
-- Date      : 2025-05-26
---------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.usp_Maintain_Tenant
(
    @I_ActionType                VARCHAR(128),
    @I_TenantID                  BIGINT            = NULL,
    @I_TenantISOCountryCode      CHAR(2)           = NULL,
    @I_TenantCode                VARCHAR(128)      = NULL,
    @I_TenantNameEN              VARCHAR(128)      = NULL,
    @I_TenantNameAR              NVARCHAR(256)     = NULL,
    @I_DisplayCategoryPrecedence VARCHAR(512)      = NULL,
    @I_UserNote                  VARCHAR(2048)     = NULL,
    @I_UserID                    VARCHAR(20)
)
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE
        @CurrentDateTime  DATETIME     = GETDATE(),
        @AuditActionType  VARCHAR(128)

    ---------------------------------------------------------------------------------------
    -- Validate ActionType
    ---------------------------------------------------------------------------------------

    IF (
           @I_ActionType IS NULL
        OR LTRIM(RTRIM(@I_ActionType)) = ''
        OR @I_ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT')
    )
    BEGIN
        SELECT
              StatusCode    = CONVERT(BIT, 1)
            , StatusMessage = CONVERT(VARCHAR(128), 'Invalid or missing ActionType')
        RETURN
    END

    ---------------------------------------------------------------------------------------
    -- BEGIN TRY...CATCH WITH TRANSACTION
    ---------------------------------------------------------------------------------------

    BEGIN TRY
        BEGIN TRANSACTION

        ---------------------------------------------------------------------------------------
        -- Check existence for UPSERT logic
        ---------------------------------------------------------------------------------------

        DECLARE @RecordExists BIT = 0

        IF @I_TenantISOCountryCode IS NOT NULL AND @I_TenantCode IS NOT NULL
        BEGIN
            IF EXISTS (
                SELECT 1 FROM InMem.Tenant WITH (NOLOCK)
                WHERE TenantISOCountryCode = @I_TenantISOCountryCode
                  AND TenantCode = @I_TenantCode
            )
                SET @RecordExists = 1
        END

        ---------------------------------------------------------------------------------------
        -- CREATE
        ---------------------------------------------------------------------------------------

        IF @I_ActionType = 'CREATE'
        BEGIN
            IF @RecordExists = 1
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'Tenant already exists. Cannot CREATE.')
                RETURN
            END

            IF (
                   @I_TenantISOCountryCode IS NULL OR LTRIM(RTRIM(@I_TenantISOCountryCode)) = ''
                OR @I_TenantCode IS NULL OR LTRIM(RTRIM(@I_TenantCode)) = ''
            )
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'Mandatory fields missing for CREATE')
                RETURN
            END

            -- Reuse INSERT block
            INSERT INTO InMem.Tenant
            (
                  TenantISOCountryCode
                , TenantCode
                , TenantNameEN
                , TenantNameAR
                , DisplayCategoryPrecedence
                , IsActive
                , UserNote
                , CreateUserID
                , CreateDateTime
                , UpdateUserID
                , UpdateDateTime
            )
            SELECT
                  @I_TenantISOCountryCode
                , @I_TenantCode
                , @I_TenantNameEN
                , @I_TenantNameAR
                , @I_DisplayCategoryPrecedence
                , 'Y'
                , @I_UserNote
                , @I_UserID
                , @CurrentDateTime
                , @I_UserID
                , @CurrentDateTime

            SET @AuditActionType = 'CREATE'
        END

        ---------------------------------------------------------------------------------------
        -- UPDATE
        ---------------------------------------------------------------------------------------

        ELSE IF @I_ActionType = 'UPDATE'
        BEGIN
            IF @I_TenantID IS NULL
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'TenantID is required for UPDATE')
                RETURN
            END

            IF NOT EXISTS (SELECT 1 FROM InMem.Tenant WITH (NOLOCK) WHERE TenantID = @I_TenantID)
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'No matching Tenant found for UPDATE')
                RETURN
            END

            -- Reuse UPDATE block
            UPDATE InMem.Tenant
            SET
                  TenantNameEN              = @I_TenantNameEN
                , TenantNameAR              = @I_TenantNameAR
                , DisplayCategoryPrecedence = @I_DisplayCategoryPrecedence
                , UserNote                  = @I_UserNote
                , UpdateUserID              = @I_UserID
                , UpdateDateTime            = @CurrentDateTime
            WHERE
                TenantID = @I_TenantID

            SET @AuditActionType = 'UPDATE'
        END

        ---------------------------------------------------------------------------------------
        -- DELETE
        ---------------------------------------------------------------------------------------

        ELSE IF @I_ActionType = 'DELETE'
        BEGIN
            IF @I_TenantID IS NULL
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'TenantID is required for DELETE')
                RETURN
            END

            IF NOT EXISTS (SELECT 1 FROM InMem.Tenant WITH (NOLOCK) WHERE TenantID = @I_TenantID)
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'No matching Tenant found for DELETE')
                RETURN
            END

            UPDATE InMem.Tenant
            SET
                  IsActive       = 'N'
                , UpdateUserID   = @I_UserID
                , UpdateDateTime = @CurrentDateTime
            WHERE
                TenantID = @I_TenantID

            SET @AuditActionType = 'DELETE'
        END

        ---------------------------------------------------------------------------------------
        -- UPSERT (Reuses CREATE or UPDATE logic)
        ---------------------------------------------------------------------------------------

        ELSE IF @I_ActionType = 'UPSERT'
        BEGIN
            IF (
                   @I_TenantISOCountryCode IS NULL OR LTRIM(RTRIM(@I_TenantISOCountryCode)) = ''
                OR @I_TenantCode IS NULL OR LTRIM(RTRIM(@I_TenantCode)) = ''
            )
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'Mandatory fields missing for UPSERT')
                RETURN
            END

            IF @RecordExists = 1
            BEGIN
                -- Reuse UPDATE logic
                UPDATE InMem.Tenant
                SET
                      TenantNameEN              = @I_TenantNameEN
                    , TenantNameAR              = @I_TenantNameAR
                    , DisplayCategoryPrecedence = @I_DisplayCategoryPrecedence
                    , UserNote                  = @I_UserNote
                    , UpdateUserID              = @I_UserID
                    , UpdateDateTime            = @CurrentDateTime
                WHERE
                    TenantISOCountryCode = @I_TenantISOCountryCode
                    AND TenantCode = @I_TenantCode

                SET @AuditActionType = 'UPDATE-UPSERT'
            END
            ELSE
            BEGIN
                -- Reuse INSERT logic
                INSERT INTO InMem.Tenant
                (
                      TenantISOCountryCode
                    , TenantCode
                    , TenantNameEN
                    , TenantNameAR
                    , DisplayCategoryPrecedence
                    , IsActive
                    , UserNote
                    , CreateUserID
                    , CreateDateTime
                    , UpdateUserID
                    , UpdateDateTime
                )
                SELECT
                      @I_TenantISOCountryCode
                    , @I_TenantCode
                    , @I_TenantNameEN
                    , @I_TenantNameAR
                    , @I_DisplayCategoryPrecedence
                    , 'Y'
                    , @I_UserNote
                    , @I_UserID
                    , @CurrentDateTime
                    , @I_UserID
                    , @CurrentDateTime

                SET @AuditActionType = 'CREATE-UPSERT'
            END
        END

        ---------------------------------------------------------------------------------------
        -- AUDIT
        ---------------------------------------------------------------------------------------

        INSERT INTO dbo.Audit_Tennant
        (
              TenantID
            , TenantISOCountryCode
            , TenantCode
            , TenantNameEN
            , TenantNameAR
            , DisplayCategoryPrecedence
            , IsActive
            , UserNote
            , CreateUserID
            , CreateDateTime
            , UpdateUserID
            , UpdateDateTime
            , AuditDateTime
            , AuditUserID
            , ActionType
        )
        SELECT
              TenantID
            , TenantISOCountryCode
            , TenantCode
            , TenantNameEN
            , TenantNameAR
            , DisplayCategoryPrecedence
            , IsActive
            , UserNote
            , CreateUserID
            , CreateDateTime
            , UpdateUserID
            , UpdateDateTime
            , @CurrentDateTime
            , @I_UserID
            , @AuditActionType
        FROM
            InMem.Tenant
        WHERE
            TenantISOCountryCode = @I_TenantISOCountryCode
            AND TenantCode = @I_TenantCode

        COMMIT

        SELECT
              StatusCode    = CONVERT(BIT, 0)
            , StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK
        SELECT
              StatusCode    = CONVERT(BIT, 1)
            , StatusMessage = CONVERT(VARCHAR(128), ERROR_MESSAGE())
    END CATCH
END
GO
