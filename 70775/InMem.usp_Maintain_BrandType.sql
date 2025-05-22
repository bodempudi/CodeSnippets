
CREATE PROCEDURE InMem.usp_Maintain_BrandType
(
    @ActionType VARCHAR(128),  -- CREATE, UPDATE, DELETE, UPSERT
    @BrandTypeID BIGINT = NULL,
    @BrandTypeCode VARCHAR(32) = NULL,
    @BrandTypeNameEN VARCHAR(128) = NULL,
    @IsCategoryApplicable CHAR(1) = NULL,
    @UserNote VARCHAR(2048) = NULL,
    @UserID VARCHAR(20),
    @StatusCode BIT OUTPUT,
    @StatusMessage VARCHAR(128) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT')
        BEGIN
            SET @StatusCode = 0;
            SET @StatusMessage = 'Invalid ActionType';
            RETURN;
        END

        IF @ActionType = 'CREATE'
        BEGIN
            IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID OR BrandTypeCode = @BrandTypeCode)
            BEGIN
                IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID OR BrandTypeCode = @BrandTypeCode AND IsActive = 'Y')
                BEGIN
                    SET @StatusCode = 0;
                    SET @StatusMessage = 'BrandType Already Exists';
                    RETURN;
                END
                ELSE
                BEGIN
                    -- Soft-deleted: Update as new record
                    UPDATE InMem.BrandType
                    SET
                        BrandTypeCode = @BrandTypeCode,
                        BrandTypeNameEN = @BrandTypeNameEN,
                        IsCategoryApplicable = ISNULL(@IsCategoryApplicable, 'N'),
                        UserNote = @UserNote,
                        IsActive = 'Y',
                        CreateDateTime = GETDATE(),
                        UpdateDateTime = GETDATE(),
                        CreateUserID = @UserID,
                        UpdateUserID = @UserID
                    WHERE BrandTypeID = @BrandTypeID OR BrandTypeCode = @BrandTypeCode;
                END
            END
            ELSE
            BEGIN
                INSERT INTO InMem.BrandType (
                    BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable, UserNote,
                    IsActive, CreateDateTime, UpdateDateTime, CreateUserID, UpdateUserID
                ) VALUES (
                    @BrandTypeCode, @BrandTypeNameEN, ISNULL(@IsCategoryApplicable, 'N'), @UserNote,
                    'Y', GETDATE(), GETDATE(), @UserID, @UserID
                );

                SET @BrandTypeID = SCOPE_IDENTITY();
            END

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'CREATE/UPDATE', @UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID;

            SET @StatusCode = 1;
            SET @StatusMessage = 'Success';
            RETURN;
        END

        IF @ActionType = 'UPDATE'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID)
            BEGIN
                SET @StatusCode = 0;
                SET @StatusMessage = 'BrandType Does Not Exist';
                RETURN;
            END

            UPDATE InMem.BrandType
            SET
                BrandTypeCode = @BrandTypeCode,
                BrandTypeNameEN = @BrandTypeNameEN,
                IsCategoryApplicable = @IsCategoryApplicable,
                UserNote = @UserNote,
                UpdateDateTime = GETDATE(),
                UpdateUserID = @UserID
            WHERE BrandTypeID = @BrandTypeID;

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'UPDATE/UPDATE', @UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID;

            SET @StatusCode = 1;
            SET @StatusMessage = 'Success';
            RETURN;
        END

        IF @ActionType = 'UPSERT'
        BEGIN
            IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID OR BrandTypeCode = @BrandTypeCode)
            BEGIN
                -- Same logic as UPDATE
                UPDATE InMem.BrandType
                SET
                    BrandTypeCode = @BrandTypeCode,
                    BrandTypeNameEN = @BrandTypeNameEN,
                    IsCategoryApplicable = @IsCategoryApplicable,
                    UserNote = @UserNote,
                    UpdateDateTime = GETDATE(),
                    UpdateUserID = @UserID
                WHERE BrandTypeID = @BrandTypeID OR BrandTypeCode = @BrandTypeCode;

                INSERT INTO dbo.Audit_BrandType
                SELECT *, 'UPSERT/UPDATE', @UserID, GETDATE()
                FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID OR BrandTypeCode = @BrandTypeCode;
            END
            ELSE
            BEGIN
                -- Same logic as CREATE
                INSERT INTO InMem.BrandType (
                    BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable, UserNote,
                    IsActive, CreateDateTime, UpdateDateTime, CreateUserID, UpdateUserID
                ) VALUES (
                    @BrandTypeCode, @BrandTypeNameEN, ISNULL(@IsCategoryApplicable, 'N'), @UserNote,
                    'Y', GETDATE(), GETDATE(), @UserID, @UserID
                );

                SET @BrandTypeID = SCOPE_IDENTITY();

                INSERT INTO dbo.Audit_BrandType
                SELECT *, 'UPSERT/CREATE', @UserID, GETDATE()
                FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID;
            END

            SET @StatusCode = 1;
            SET @StatusMessage = 'Success';
            RETURN;
        END

        IF @ActionType = 'DELETE'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID)
            BEGIN
                SET @StatusCode = 0;
                SET @StatusMessage = 'BrandType Does Not Exist';
                RETURN;
            END

            -- Soft delete
            UPDATE InMem.BrandType
            SET
                IsActive = 'N',
                UpdateDateTime = GETDATE(),
                UpdateUserID = @UserID
            WHERE BrandTypeID = @BrandTypeID;

            INSERT INTO dbo.Audit_BrandType
            SELECT *, 'DELETE/DELETE', @UserID, GETDATE()
            FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID;

            SET @StatusCode = 1;
            SET @StatusMessage = 'Success';
            RETURN;
        END
    END TRY
    BEGIN CATCH
        SET @StatusCode = 0;
        SET @StatusMessage = ERROR_MESSAGE();
    END CATCH
END
