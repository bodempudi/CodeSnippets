CREATE OR ALTER PROCEDURE dbo.usp_Maintain_CPGDocumentMaster
(
      @I_ActionType          VARCHAR(20)
    , @I_CPGDocumentMasterID BIGINT = NULL
    , @I_TennantCode         VARCHAR(50) = NULL
    , @I_ProductCode         VARCHAR(50) = NULL
    , @I_DocumentTypeCode    VARCHAR(50) = NULL
    , @I_EffectiveStartDate  DATE = NULL
    , @I_CreateUserID        VARCHAR(50)

    , @O_StatusCode          VARCHAR(30) OUTPUT
    , @O_StatusMessage       VARCHAR(128) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
          @V_CurrentDateTime     DATETIME = GETDATE()
        , @V_CurrentDate         DATE = CONVERT(DATE,GETDATE())
        , @V_IsTransactionOwner  CHAR(1) = 'N'
        , @V_ActionType          VARCHAR(20)
        , @V_CoveringID          BIGINT = NULL
        , @V_CoveringEndDate     DATE = NULL
        , @V_NextStartDate       DATE = NULL
        , @V_NewEndDate          DATE = NULL;

    BEGIN TRY

        SELECT
              @V_ActionType = UPPER(LTRIM(RTRIM(ISNULL(@I_ActionType,''))))
            , @I_TennantCode = NULLIF(LTRIM(RTRIM(@I_TennantCode)), '')
            , @I_ProductCode = NULLIF(LTRIM(RTRIM(@I_ProductCode)), '')
            , @I_DocumentTypeCode = NULLIF(LTRIM(RTRIM(@I_DocumentTypeCode)), '')
            , @I_CreateUserID = NULLIF(LTRIM(RTRIM(@I_CreateUserID)), '');

        IF @V_ActionType NOT IN ('CREATE','UPDATE','DELETE','UPSERT')
            RAISERROR('Invalid ActionType.',16,1);

        IF @I_CreateUserID IS NULL
            RAISERROR('CreateUserID is mandatory.',16,1);

        IF @V_ActionType IN ('UPDATE','DELETE')
           AND @I_CPGDocumentMasterID IS NULL
            RAISERROR('CPGDocumentMasterID is mandatory for UPDATE/DELETE.',16,1);

        IF @V_ActionType IN ('CREATE','UPSERT')
        BEGIN
            IF @I_TennantCode IS NULL
                RAISERROR('TennantCode is mandatory.',16,1);

            IF @I_ProductCode IS NULL
                RAISERROR('ProductCode is mandatory.',16,1);

            IF @I_DocumentTypeCode IS NULL
                RAISERROR('DocumentTypeCode is mandatory.',16,1);

            IF @I_EffectiveStartDate IS NULL
                RAISERROR('EffectiveStartDate is mandatory.',16,1);
        END

        IF @V_ActionType = 'UPSERT'
        BEGIN
            IF @I_CPGDocumentMasterID IS NOT NULL
               AND EXISTS
               (
                   SELECT 1
                   FROM dbo.CPGDocumentMaster WITH (NOLOCK)
                   WHERE CPGDocumentMasterID = @I_CPGDocumentMasterID
               )
            BEGIN
                SELECT @V_ActionType = 'UPDATE';
            END
            ELSE
            BEGIN
                SELECT @V_ActionType = 'CREATE';
            END
        END

        IF @@TRANCOUNT = 0
        BEGIN
            SELECT @V_IsTransactionOwner = 'Y';
            BEGIN TRAN;
        END

        IF @V_ActionType = 'CREATE'
        BEGIN
            SELECT
                  @V_CoveringID = CPGDocumentMasterID
                , @V_CoveringEndDate = EffectiveEndDate
            FROM dbo.CPGDocumentMaster WITH (UPDLOCK,HOLDLOCK)
            WHERE TennantCode = @I_TennantCode
              AND ProductCode = @I_ProductCode
              AND DocumentTypeCode = @I_DocumentTypeCode
              AND EffectiveStartDate < @I_EffectiveStartDate
              AND EffectiveEndDate >= @I_EffectiveStartDate;

            SELECT
                @V_NextStartDate = MIN(EffectiveStartDate)
            FROM dbo.CPGDocumentMaster WITH (UPDLOCK,HOLDLOCK)
            WHERE TennantCode = @I_TennantCode
              AND ProductCode = @I_ProductCode
              AND DocumentTypeCode = @I_DocumentTypeCode
              AND EffectiveStartDate > @I_EffectiveStartDate;

            SELECT
                @V_NewEndDate =
                    CASE
                        WHEN @V_CoveringEndDate IS NOT NULL
                            THEN @V_CoveringEndDate
                        WHEN @V_NextStartDate IS NOT NULL
                            THEN DATEADD(DAY,-1,@V_NextStartDate)
                        ELSE CONVERT(DATE,'20991231')
                    END;

            IF @V_CoveringID IS NOT NULL
            BEGIN
                UPDATE dbo.CPGDocumentMaster
                SET EffectiveEndDate = DATEADD(DAY,-1,@I_EffectiveStartDate)
                WHERE CPGDocumentMasterID = @V_CoveringID;
            END

            INSERT INTO dbo.CPGDocumentMaster
            (
                  TennantCode
                , ProductCode
                , DocumentTypeCode
                , EffectiveStartDate
                , EffectiveEndDate
                , CreateDateTime
                , CreateUserID
            )
            VALUES
            (
                  @I_TennantCode
                , @I_ProductCode
                , @I_DocumentTypeCode
                , @I_EffectiveStartDate
                , @V_NewEndDate
                , @V_CurrentDateTime
                , @I_CreateUserID
            );
        END

        IF @V_ActionType = 'UPDATE'
        BEGIN
            UPDATE dbo.CPGDocumentMaster
            SET
                  CreateUserID = @I_CreateUserID
            WHERE CPGDocumentMasterID = @I_CPGDocumentMasterID;

            IF @@ROWCOUNT = 0
                RAISERROR('Record not found for UPDATE.',16,1);
        END

        IF @V_ActionType = 'DELETE'
        BEGIN
            UPDATE dbo.CPGDocumentMaster
            SET
                  EffectiveEndDate =
                        CASE
                            WHEN EffectiveStartDate > @V_CurrentDate
                                THEN EffectiveStartDate
                            ELSE @V_CurrentDate
                        END
            WHERE CPGDocumentMasterID = @I_CPGDocumentMasterID;

            IF @@ROWCOUNT = 0
                RAISERROR('Record not found for DELETE.',16,1);
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
                CASE
                    WHEN ERROR_NUMBER() IN (2601,2627)
                        THEN 'Duplicate effective start date.'
                    ELSE LEFT(ERROR_MESSAGE(),128)
                  END;

        THROW;

    END CATCH
END;
GO
