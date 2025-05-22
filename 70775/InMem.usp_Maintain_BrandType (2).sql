
CREATE PROCEDURE InMem.usp_Maintain_BrandType
(
    @I_ActionType VARCHAR(128),  -- CREATE, UPDATE, DELETE, UPSERT
    @I_BrandTypeID BIGINT = NULL,
    @I_BrandTypeCode VARCHAR(32) = NULL,
    @I_BrandTypeNameEN VARCHAR(128) = NULL,
    @I_IsCategoryApplicable CHAR(1) = NULL,
    @I_UserNote VARCHAR(2048) = NULL,
    @I_UserID VARCHAR(20),
    @I_StatusCode BIT OUTPUT,
    @I_StatusMessage VARCHAR(128) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @I_ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT')
        BEGIN
            SET @I_StatusCode = 0;
            SET @I_StatusMessage = 'Invalid ActionType';
            RETURN;
        END

        IF @I_ActionType = 'CREATE'
        BEGIN
            IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID OR BrandTypeCode = @I_BrandTypeCode)
            BEGIN
                IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID OR BrandTypeCode = @I_BrandTypeCode AND IsActive = 'Y')
                BEGIN
                    SET @I_StatusCode = 0;
                    SET @I_StatusMessage = 'BrandType Already Exists';
                    RETURN;
                END
                ELSE
                BEGIN
                    -- Soft-deleted: Update as new record
                    UPDATE InMem.BrandType
                    SET
                        BrandTypeCode = @I_BrandTypeCode,
                        BrandTypeNameEN = @I_BrandTypeNameEN,
                        IsCategoryApplicable = ISNULL(@IsCategoryApplicable, 'N'),
                        UserNote = @I_UserNote,
                        IsActive = 'Y',
                        CreateDateTime = GETDATE(),
                        UpdateDateTime = GETDATE(),
                        CreateUserID = @I_UserID,
                        UpdateUserID = @I_UserID
                    WHERE BrandTypeID = @I_BrandTypeID OR BrandTypeCode = @I_BrandTypeCode;
                END
            END
            ELSE
            BEGIN
                INSERT INTO InMem.BrandType (
                    BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable, UserNote,
                    IsActive, CreateDateTime, UpdateDateTime, CreateUserID, UpdateUserID
                ) VALUES (
                    @I_BrandTypeCode, @I_BrandTypeNameEN, ISNULL(@IsCategoryApplicable, 'N'), @I_UserNote,
                    'Y', GETDATE(), GETDATE(), @I_UserID, @I_UserID
                );

                SET @I_BrandTypeID = SCOPE_IDENTITY();
            END

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'CREATE/UPDATE', @I_UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID;

            SET @I_StatusCode = 1;
            SET @I_StatusMessage = 'Success';
            RETURN;
        END

        IF @I_ActionType = 'UPDATE'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID)
            BEGIN
                SET @I_StatusCode = 0;
                SET @I_StatusMessage = 'BrandType Does Not Exist';
                RETURN;
            END

            UPDATE InMem.BrandType
            SET
                BrandTypeCode = @I_BrandTypeCode,
                BrandTypeNameEN = @I_BrandTypeNameEN,
                IsCategoryApplicable = @I_IsCategoryApplicable,
                UserNote = @I_UserNote,
                UpdateDateTime = GETDATE(),
                UpdateUserID = @I_UserID
            WHERE BrandTypeID = @I_BrandTypeID;

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'UPDATE/UPDATE', @I_UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID;

            SET @I_StatusCode = 1;
            SET @I_StatusMessage = 'Success';
            RETURN;
        END

        IF @I_ActionType = 'UPSERT'
        BEGIN
            IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID OR BrandTypeCode = @I_BrandTypeCode)
            BEGIN
                -- Same logic as UPDATE
                UPDATE InMem.BrandType
                SET
                    BrandTypeCode = @I_BrandTypeCode,
                    BrandTypeNameEN = @I_BrandTypeNameEN,
                    IsCategoryApplicable = @I_IsCategoryApplicable,
                    UserNote = @I_UserNote,
                    UpdateDateTime = GETDATE(),
                    UpdateUserID = @I_UserID
                WHERE BrandTypeID = @I_BrandTypeID OR BrandTypeCode = @I_BrandTypeCode;

                INSERT INTO dbo.Audit_BrandType
                SELECT *, 'UPSERT/UPDATE', @I_UserID, GETDATE()
                FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID OR BrandTypeCode = @I_BrandTypeCode;
            END
            ELSE
            BEGIN
                -- Same logic as CREATE
                INSERT INTO InMem.BrandType (
                    BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable, UserNote,
                    IsActive, CreateDateTime, UpdateDateTime, CreateUserID, UpdateUserID
                ) VALUES (
                    @I_BrandTypeCode, @I_BrandTypeNameEN, ISNULL(@IsCategoryApplicable, 'N'), @I_UserNote,
                    'Y', GETDATE(), GETDATE(), @I_UserID, @I_UserID
                );

                SET @I_BrandTypeID = SCOPE_IDENTITY();

                INSERT INTO dbo.Audit_BrandType
                SELECT *, 'UPSERT/CREATE', @I_UserID, GETDATE()
                FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID;
            END

            SET @I_StatusCode = 1;
            SET @I_StatusMessage = 'Success';
            RETURN;
        END

        IF @I_ActionType = 'DELETE'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID)
            BEGIN
                SET @I_StatusCode = 0;
                SET @I_StatusMessage = 'BrandType Does Not Exist';
                RETURN;
            END

            -- Soft delete
            UPDATE InMem.BrandType
            SET
                IsActive = 'N',
                UpdateDateTime = GETDATE(),
                UpdateUserID = @I_UserID
            WHERE BrandTypeID = @I_BrandTypeID;

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'DELETE/DELETE', @I_UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @I_BrandTypeID;

            SET @I_StatusCode = 1;
            SET @I_StatusMessage = 'Success';
            RETURN;
        END
    END TRY
    BEGIN CATCH
        SET @I_StatusCode = 0;
        SET @I_StatusMessage = ERROR_MESSAGE();
    END CATCH
END
