CREATE OR ALTER PROCEDURE dbo.usp_Maintain_DocumentTypeEffectiveDate
(
      @I_ActionType                  VARCHAR(20)      -- CREATE/UPDATE/DELETE
    , @I_DocumentTypeEffectiveDateID BIGINT = NULL
    , @I_DocumentTypeCode            VARCHAR(50) = NULL
    , @I_EffectiveStartDate          DATE = NULL
    , @I_EffectiveEndDate            DATE = NULL
    , @I_UserID                      VARCHAR(20)

    , @O_StatusCode                  VARCHAR(30) OUTPUT
    , @O_StatusMessage               VARCHAR(128) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
          @V_CurrentDateTime      DATETIME = GETDATE()
        , @V_IsTransactionOwner   CHAR(1) = 'N';

    BEGIN TRY

        SELECT
              @I_ActionType = UPPER(LTRIM(RTRIM(ISNULL(@I_ActionType,''))))
            , @I_DocumentTypeCode = NULLIF(LTRIM(RTRIM(@I_DocumentTypeCode)), '');

        IF @I_ActionType NOT IN ('CREATE','UPDATE','DELETE')
        BEGIN
            RAISERROR('Invalid ActionType. Allowed values CREATE/UPDATE/DELETE.',16,1);
        END

        IF NULLIF(LTRIM(RTRIM(ISNULL(@I_UserID,''))), '') IS NULL
        BEGIN
            RAISERROR('UserID is mandatory.',16,1);
        END

        IF @I_ActionType IN ('UPDATE','DELETE')
            AND @I_DocumentTypeEffectiveDateID IS NULL
        BEGIN
            RAISERROR('DocumentTypeEffectiveDateID is mandatory for UPDATE/DELETE.',16,1);
        END

        IF @I_ActionType IN ('CREATE','UPDATE')
        BEGIN
            IF @I_DocumentTypeCode IS NULL
            BEGIN
                RAISERROR('DocumentTypeCode is mandatory.',16,1);
            END

            IF @I_EffectiveStartDate IS NULL
                OR @I_EffectiveEndDate IS NULL
            BEGIN
                RAISERROR('EffectiveStartDate and EffectiveEndDate are mandatory.',16,1);
            END

            IF @I_EffectiveStartDate > @I_EffectiveEndDate
            BEGIN
                RAISERROR('EffectiveStartDate cannot be greater than EffectiveEndDate.',16,1);
            END

            IF @I_EffectiveEndDate > CONVERT(DATE,'20991231')
            BEGIN
                RAISERROR('EffectiveEndDate cannot be greater than 2099-12-31.',16,1);
            END

            IF EXISTS
            (
                SELECT
                    1
                FROM dbo.DocumentTypeEffectiveDate d WITH (NOLOCK)
                WHERE
                    d.DocumentTypeCode = @I_DocumentTypeCode
                    AND d.IsActive = 'Y'
                    AND d.DocumentTypeEffectiveDateID <> ISNULL(@I_DocumentTypeEffectiveDateID,-1)
                    AND @I_EffectiveStartDate <= d.EffectiveEndDate
                    AND @I_EffectiveEndDate >= d.EffectiveStartDate
            )
            BEGIN
                RAISERROR('Overlapping effective date range exists for DocumentTypeCode.',16,1);
            END
        END

        IF @@TRANCOUNT = 0
        BEGIN
            SELECT
                @V_IsTransactionOwner = 'Y';

            BEGIN TRAN;
        END

        IF @I_ActionType = 'CREATE'
        BEGIN
            INSERT INTO dbo.DocumentTypeEffectiveDate
            (
                  DocumentTypeCode
                , EffectiveStartDate
                , EffectiveEndDate
                , IsActive
                , CreatedUserID
                , CreatedDateTime
                , UpdateUserID
                , UpdateDateTime
            )
            VALUES
            (
                  @I_DocumentTypeCode
                , @I_EffectiveStartDate
                , @I_EffectiveEndDate
                , 'Y'
                , @I_UserID
                , @V_CurrentDateTime
                , @I_UserID
                , @V_CurrentDateTime
            );
        END

        IF @I_ActionType = 'UPDATE'
        BEGIN
            UPDATE dbo.DocumentTypeEffectiveDate
            SET
                  DocumentTypeCode = @I_DocumentTypeCode
                , EffectiveStartDate = @I_EffectiveStartDate
                , EffectiveEndDate = @I_EffectiveEndDate
                , UpdateUserID = @I_UserID
                , UpdateDateTime = @V_CurrentDateTime
            WHERE
                DocumentTypeEffectiveDateID = @I_DocumentTypeEffectiveDateID
                AND IsActive = 'Y';

            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR('Record does not exist or inactive for UPDATE.',16,1);
            END
        END

        IF @I_ActionType = 'DELETE'
        BEGIN
            UPDATE dbo.DocumentTypeEffectiveDate
            SET
                  IsActive = 'N'
                , UpdateUserID = @I_UserID
                , UpdateDateTime = @V_CurrentDateTime
            WHERE
                DocumentTypeEffectiveDateID = @I_DocumentTypeEffectiveDateID
                AND IsActive = 'Y';

            IF @@ROWCOUNT = 0
            BEGIN
                RAISERROR('Record does not exist or inactive for DELETE.',16,1);
            END
        END

        IF @V_IsTransactionOwner = 'Y'
            AND XACT_STATE() = 1
        BEGIN
            COMMIT TRAN;
        END

        SELECT
              @O_StatusCode = '0'
            , @O_StatusMessage = 'SUCCESS';

    END TRY
    BEGIN CATCH

        IF @V_IsTransactionOwner = 'Y'
            AND XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRAN;
        END

        SELECT
              @O_StatusCode = '1'
            , @O_StatusMessage =
                LEFT
                (
                    ERROR_MESSAGE()
                    + ' | '
                    + ISNULL(ERROR_PROCEDURE(),'N/A')
                    + ':'
                    + CONVERT(VARCHAR(10),ERROR_LINE())
                    ,128
                );

        THROW;

    END CATCH
END
GO
