
-- ========================================================================================================================================================================
-- Procedure Name  : usp_Maintain_LineOfBusiness
-- Created On      : 2025-05-27 06:51:57
-- Created By      : venkat
-- Description     : Maintenance stored procedure for LineOfBusiness table (CREATE, UPDATE, DELETE, UPSERT)
-- ========================================================================================================================================================================

CREATE OR ALTER PROCEDURE InMem.usp_Maintain_LineOfBusiness
(
    @I_ActionType            VARCHAR(128),
    @I_LineOfBusinessID      BIGINT         = NULL,
    @I_TenantISOcountryCode  CHAR(2),
    @I_TenantCode            VARCHAR(128),
    @I_LineOfBusinessName    VARCHAR(128)   = NULL,
    @I_UserNote              VARCHAR(2048)  = NULL,
    @I_UserID                VARCHAR(20)
)
AS
BEGIN
    SET NOCOUNT ON;

    ---------------------------------------------------------------------------------------------------------------------------------------
    -- Variable Declaration
    ---------------------------------------------------------------------------------------------------------------------------------------
    DECLARE
          @StatusCode        BIT
        , @StatusMessage     VARCHAR(128)
        , @v_TenantID        BIGINT
        , @v_CurrentDateTime DATETIME = GETDATE()
        , @AuditActionType   VARCHAR(32)

    ---------------------------------------------------------------------------------------------------------------------------------------
    -- Validate ActionType
    ---------------------------------------------------------------------------------------------------------------------------------------
    IF
    (
           @I_ActionType IS NULL
        OR @I_ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT')
    )
    BEGIN

        SELECT
              @StatusCode    = CONVERT(BIT, 0)
            , @StatusMessage = CONVERT(VARCHAR(128), 'Invalid ActionType')

        SELECT
              StatusCode    = @StatusCode
            , StatusMessage = @StatusMessage

        RETURN

    END

    ---------------------------------------------------------------------------------------------------------------------------------------
    -- Validate TenantCode and ISOCountryCode
    ---------------------------------------------------------------------------------------------------------------------------------------
    IF
    (
           @I_TenantCode IS NULL
        OR @I_TenantISOcountryCode IS NULL
    )
    BEGIN

        SELECT
              @StatusCode    = CONVERT(BIT, 0)
            , @StatusMessage = CONVERT(VARCHAR(128), 'TenantCode and TenantISOcountryCode are mandatory')

        SELECT
              StatusCode    = @StatusCode
            , StatusMessage = @StatusMessage

        RETURN

    END

    ---------------------------------------------------------------------------------------------------------------------------------------
    -- Resolve TenantID using TenantCode and ISOCountryCode
    ---------------------------------------------------------------------------------------------------------------------------------------
    SELECT
        @v_TenantID = TenantID
    FROM InMem.Tenant WITH (NOLOCK)
    WHERE
          TenantCode = @I_TenantCode
      AND TenantISOcountryCode = @I_TenantISOcountryCode
      AND IsActive = 'Y'

    IF (@v_TenantID IS NULL)
    BEGIN

        SELECT
              @StatusCode    = CONVERT(BIT, 0)
            , @StatusMessage = CONVERT(VARCHAR(128), 'Invalid TenantCode or ISOCountryCode')

        SELECT
              StatusCode    = @StatusCode
            , StatusMessage = @StatusMessage

        RETURN

    END

    ---------------------------------------------------------------------------------------------------------------------------------------
    -- BEGIN TRANSACTION
    ---------------------------------------------------------------------------------------------------------------------------------------
    BEGIN TRY
        BEGIN TRANSACTION

        -----------------------------------------------------------------------------------------------------------------------------------
        -- Handle UPSERT
        -----------------------------------------------------------------------------------------------------------------------------------
        IF @I_ActionType = 'UPSERT'
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM InMem.LineOfBusiness WITH (NOLOCK)
                WHERE TenantID = @v_TenantID AND LineOfBusinessName = @I_LineOfBusinessName
            )
            BEGIN
                SET @I_ActionType = 'UPDATE'
                SET @AuditActionType = 'UPDATE-UPSERT'
            END
            ELSE
            BEGIN
                SET @I_ActionType = 'CREATE'
                SET @AuditActionType = 'CREATE-UPSERT'
            END
        END

        -----------------------------------------------------------------------------------------------------------------------------------
        -- CREATE
        -----------------------------------------------------------------------------------------------------------------------------------
        IF @I_ActionType = 'CREATE'
        BEGIN

            INSERT INTO InMem.LineOfBusiness
            (
                  TenantID
                , LineOfBusinessName
                , UserNote
                , CreateUserID
                , CreateDateTime
                , UpdateUserID
                , UpdateDateTime
            )
            SELECT
                  @v_TenantID
                , @I_LineOfBusinessName
                , @I_UserNote
                , @I_UserID
                , @v_CurrentDateTime
                , @I_UserID
                , @v_CurrentDateTime

            SET @AuditActionType = ISNULL(@AuditActionType, 'CREATE')

        END

        -----------------------------------------------------------------------------------------------------------------------------------
        -- UPDATE
        -----------------------------------------------------------------------------------------------------------------------------------
        IF @I_ActionType = 'UPDATE'
        BEGIN

            UPDATE LOB
            SET
                  LineOfBusinessName = @I_LineOfBusinessName
                , UserNote           = @I_UserNote
                , UpdateUserID       = @I_UserID
                , UpdateDateTime     = @v_CurrentDateTime
            FROM InMem.LineOfBusiness LOB
            WHERE
                  LOB.LineOfBusinessID = @I_LineOfBusinessID
              AND LOB.TenantID = @v_TenantID

            SET @AuditActionType = ISNULL(@AuditActionType, 'UPDATE')

        END

        -----------------------------------------------------------------------------------------------------------------------------------
        -- DELETE (Soft Delete)
        -----------------------------------------------------------------------------------------------------------------------------------
        IF @I_ActionType = 'DELETE'
        BEGIN

            UPDATE LOB
            SET
                  IsActive = 'N'
                , UpdateUserID = @I_UserID
                , UpdateDateTime = @v_CurrentDateTime
            FROM InMem.LineOfBusiness LOB
            WHERE
                  LOB.LineOfBusinessID = @I_LineOfBusinessID
              AND LOB.TenantID = @v_TenantID

            SET @AuditActionType = 'DELETE'

        END

        -----------------------------------------------------------------------------------------------------------------------------------
        -- AUDIT
        -----------------------------------------------------------------------------------------------------------------------------------
        INSERT INTO DBO.Audit_LineOfBusiness
        (
              AuditDateTime
            , AuditUserID
            , ActionType
            , LineOfBusinessID
            , TenantID
            , LineOfBusinessName
            , UserNote
        )
        SELECT
              @v_CurrentDateTime           AS AuditDateTime
            , @I_UserID                    AS AuditUserID
            , @AuditActionType            AS ActionType
            , LOB.LineOfBusinessID
            , LOB.TenantID
            , LOB.LineOfBusinessName
            , LOB.UserNote
        FROM InMem.LineOfBusiness LOB
        WHERE
              LOB.TenantID = @v_TenantID
          AND (
                 ( @I_ActionType = 'CREATE' AND LOB.LineOfBusinessName = @I_LineOfBusinessName )
              OR ( @I_ActionType = 'UPDATE' AND LOB.LineOfBusinessID = @I_LineOfBusinessID )
              OR ( @I_ActionType = 'DELETE' AND LOB.LineOfBusinessID = @I_LineOfBusinessID )
          )

        COMMIT TRANSACTION

        SELECT
              @StatusCode    = CONVERT(BIT, 1)
            , @StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION

        SELECT
              @StatusCode    = CONVERT(BIT, 0)
            , @StatusMessage = ERROR_MESSAGE()
    END CATCH

    ---------------------------------------------------------------------------------------------------------------------------------------
    -- Final Result
    ---------------------------------------------------------------------------------------------------------------------------------------
    SELECT
          StatusCode    = @StatusCode
        , StatusMessage = @StatusMessage
END
