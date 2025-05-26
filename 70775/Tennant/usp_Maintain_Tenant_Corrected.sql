
USE InMem;
GO

---------------------------------------------------------------------------------------
-- Procedure: usp_Maintain_Tenant
-- Description: CREATE, UPDATE, DELETE, UPSERT for InMem.Tenant with audit logging
-- Notes:
--   - UPSERT sets ActionType to CREATE-UPSERT or UPDATE-UPSERT and reuses logic
--   - StatusCode: 0 = SUCCESS, 1 = ERROR
-- Developer: Auto-generated
-- Date: 2025-05-26
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
        @AuditActionType  VARCHAR(128),
        @EffectiveAction  VARCHAR(128)

    ---------------------------------------------------------------------------------------
    -- Basic Validation
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

    IF (@I_UserID IS NULL OR LTRIM(RTRIM(@I_UserID)) = '')
    BEGIN
        SELECT
              StatusCode    = CONVERT(BIT, 1)
            , StatusMessage = CONVERT(VARCHAR(128), 'UserID is mandatory')
        RETURN
    END

    ---------------------------------------------------------------------------------------
    -- Begin TRY-CATCH Block
    ---------------------------------------------------------------------------------------

    BEGIN TRY
        BEGIN TRANSACTION

        SET @EffectiveAction = @I_ActionType

        ---------------------------------------------------------------------------------------
        -- UPSERT Resolution: Determine if record exists
        ---------------------------------------------------------------------------------------

        IF @I_ActionType = 'UPSERT'
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

            IF EXISTS (
                SELECT 1 FROM InMem.Tenant WITH (NOLOCK)
                WHERE TenantISOCountryCode = @I_TenantISOCountryCode
                  AND TenantCode = @I_TenantCode
            )
                SET @EffectiveAction = 'UPDATE-UPSERT'
            ELSE
                SET @EffectiveAction = 'CREATE-UPSERT'
        END

        ---------------------------------------------------------------------------------------
        -- CREATE or CREATE-UPSERT
        ---------------------------------------------------------------------------------------

        IF @EffectiveAction IN ('CREATE', 'CREATE-UPSERT')
        BEGIN
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

            IF EXISTS (
                SELECT 1 FROM InMem.Tenant WITH (NOLOCK)
                WHERE TenantISOCountryCode = @I_TenantISOCountryCode
                  AND TenantCode = @I_TenantCode
            )
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'Tenant already exists')
                RETURN
            END

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

            SET @AuditActionType = @EffectiveAction
        END

        ---------------------------------------------------------------------------------------
        -- UPDATE or UPDATE-UPSERT
        ---------------------------------------------------------------------------------------

        ELSE IF @EffectiveAction IN ('UPDATE', 'UPDATE-UPSERT')
        BEGIN
            DECLARE @UpdateTargetID BIGINT

            IF @EffectiveAction = 'UPDATE'
            BEGIN
                IF @I_TenantID IS NULL
                BEGIN
                    SELECT
                          StatusCode    = CONVERT(BIT, 1)
                        , StatusMessage = CONVERT(VARCHAR(128), 'TenantID is required for UPDATE')
                    RETURN
                END

                SET @UpdateTargetID = @I_TenantID

                IF NOT EXISTS (
                    SELECT 1 FROM InMem.Tenant WITH (NOLOCK)
                    WHERE TenantID = @UpdateTargetID
                )
                BEGIN
                    SELECT
                          StatusCode    = CONVERT(BIT, 1)
                        , StatusMessage = CONVERT(VARCHAR(128), 'Tenant not found for UPDATE')
                    RETURN
                END
            END
            ELSE
            BEGIN
                SELECT @UpdateTargetID = TenantID
                FROM InMem.Tenant WITH (NOLOCK)
                WHERE TenantISOCountryCode = @I_TenantISOCountryCode
                  AND TenantCode = @I_TenantCode
            END

            UPDATE InMem.Tenant
            SET
                  TenantNameEN              = @I_TenantNameEN
                , TenantNameAR              = @I_TenantNameAR
                , DisplayCategoryPrecedence = @I_DisplayCategoryPrecedence
                , UserNote                  = @I_UserNote
                , UpdateUserID              = @I_UserID
                , UpdateDateTime            = @CurrentDateTime
            WHERE
                TenantID = @UpdateTargetID

            SET @AuditActionType = @EffectiveAction
        END

        ---------------------------------------------------------------------------------------
        -- DELETE
        ---------------------------------------------------------------------------------------

        ELSE IF @EffectiveAction = 'DELETE'
        BEGIN
            IF @I_TenantID IS NULL
            BEGIN
                SELECT
                      StatusCode    = CONVERT(BIT, 1)
                    , StatusMessage = CONVERT(VARCHAR(128), 'TenantID is required for DELETE')
                RETURN
            END

            IF NOT EXISTS (SELECT 1 FROM InMem.Tenant WHERE TenantID = @I_TenantID)
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
              StatusCode    = CONVERT(BIT, 0),
              StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK
        SELECT
              StatusCode    = CONVERT(BIT, 1),
              StatusMessage = CONVERT(VARCHAR(128), ERROR_MESSAGE())
    END CATCH
END
GO
