
CREATE PROCEDURE InMem.usp_Maintain_BrandType
(
    @_ActionType VARCHAR(128),  -- CREATE, UPDATE, DELETE, UPSERT
    @_BrandTypeID BIGINT = NULL,
    @_BrandTypeCode VARCHAR(32) = NULL,
    @_BrandTypeNameEN VARCHAR(128) = NULL,
    @_IsCategoryApplicable CHAR(1) = NULL,
    @_UserNote VARCHAR(2048) = NULL,
    @_UserID VARCHAR(20),
    @_StatusCode BIT OUTPUT,
    @_StatusMessage VARCHAR(128) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @_ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT')
        BEGIN
            SET @_StatusCode = 0;
            SET @_StatusMessage = 'Invalid ActionType';
            RETURN;
        END

        IF @_ActionType = 'CREATE'
        BEGIN
            IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID OR BrandTypeCode = @_BrandTypeCode)
            BEGIN
                IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID OR BrandTypeCode = @_BrandTypeCode AND IsActive = 'Y')
                BEGIN
                    SET @_StatusCode = 0;
                    SET @_StatusMessage = 'BrandType Already Exists';
                    RETURN;
                END
                ELSE
                BEGIN
                    -- Soft-deleted: Update as new record
                    UPDATE InMem.BrandType
                    SET
                        BrandTypeCode = @_BrandTypeCode,
                        BrandTypeNameEN = @_BrandTypeNameEN,
                        IsCategoryApplicable = ISNULL(@IsCategoryApplicable, 'N'),
                        UserNote = @_UserNote,
                        IsActive = 'Y',
                        CreateDateTime = GETDATE(),
                        UpdateDateTime = GETDATE(),
                        CreateUserID = @_UserID,
                        UpdateUserID = @_UserID
                    WHERE BrandTypeID = @_BrandTypeID OR BrandTypeCode = @_BrandTypeCode;
                END
            END
            ELSE
            BEGIN
                INSERT INTO InMem.BrandType (
                    BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable, UserNote,
                    IsActive, CreateDateTime, UpdateDateTime, CreateUserID, UpdateUserID
                ) VALUES (
                    @_BrandTypeCode, @_BrandTypeNameEN, ISNULL(@IsCategoryApplicable, 'N'), @_UserNote,
                    'Y', GETDATE(), GETDATE(), @_UserID, @_UserID
                );

                SET @_BrandTypeID = SCOPE_IDENTITY();
            END

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'CREATE/UPDATE', @_UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID;

            SET @_StatusCode = 1;
            SET @_StatusMessage = 'Success';
            RETURN;
        END

        IF @_ActionType = 'UPDATE'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID)
            BEGIN
                SET @_StatusCode = 0;
                SET @_StatusMessage = 'BrandType Does Not Exist';
                RETURN;
            END

            UPDATE InMem.BrandType
            SET
                BrandTypeCode = @_BrandTypeCode,
                BrandTypeNameEN = @_BrandTypeNameEN,
                IsCategoryApplicable = @_IsCategoryApplicable,
                UserNote = @_UserNote,
                UpdateDateTime = GETDATE(),
                UpdateUserID = @_UserID
            WHERE BrandTypeID = @_BrandTypeID;

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'UPDATE/UPDATE', @_UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID;

            SET @_StatusCode = 1;
            SET @_StatusMessage = 'Success';
            RETURN;
        END

        IF @_ActionType = 'UPSERT'
        BEGIN
            IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID OR BrandTypeCode = @_BrandTypeCode)
            BEGIN
                -- Same logic as UPDATE
                UPDATE InMem.BrandType
                SET
                    BrandTypeCode = @_BrandTypeCode,
                    BrandTypeNameEN = @_BrandTypeNameEN,
                    IsCategoryApplicable = @_IsCategoryApplicable,
                    UserNote = @_UserNote,
                    UpdateDateTime = GETDATE(),
                    UpdateUserID = @_UserID
                WHERE BrandTypeID = @_BrandTypeID OR BrandTypeCode = @_BrandTypeCode;

                INSERT INTO dbo.Audit_BrandType
                SELECT *, 'UPSERT/UPDATE', @_UserID, GETDATE()
                FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID OR BrandTypeCode = @_BrandTypeCode;
            END
            ELSE
            BEGIN
                -- Same logic as CREATE
                INSERT INTO InMem.BrandType (
                    BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable, UserNote,
                    IsActive, CreateDateTime, UpdateDateTime, CreateUserID, UpdateUserID
                ) VALUES (
                    @_BrandTypeCode, @_BrandTypeNameEN, ISNULL(@IsCategoryApplicable, 'N'), @_UserNote,
                    'Y', GETDATE(), GETDATE(), @_UserID, @_UserID
                );

                SET @_BrandTypeID = SCOPE_IDENTITY();

                INSERT INTO dbo.Audit_BrandType
                SELECT *, 'UPSERT/CREATE', @_UserID, GETDATE()
                FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID;
            END

            SET @_StatusCode = 1;
            SET @_StatusMessage = 'Success';
            RETURN;
        END

        IF @_ActionType = 'DELETE'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID)
            BEGIN
                SET @_StatusCode = 0;
                SET @_StatusMessage = 'BrandType Does Not Exist';
                RETURN;
            END

            -- Soft delete
            UPDATE InMem.BrandType
            SET
                IsActive = 'N',
                UpdateDateTime = GETDATE(),
                UpdateUserID = @_UserID
            WHERE BrandTypeID = @_BrandTypeID;

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'DELETE/DELETE', @_UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @_BrandTypeID;

            SET @_StatusCode = 1;
            SET @_StatusMessage = 'Success';
            RETURN;
        END
    END TRY
    BEGIN CATCH
        SET @_StatusCode = 0;
        SET @_StatusMessage = ERROR_MESSAGE();
    END CATCH
END
