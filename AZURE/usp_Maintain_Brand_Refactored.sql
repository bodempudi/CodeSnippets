
-- Refactored version of usp_Maintain_Brand
CREATE PROCEDURE dbo.usp_Maintain_Brand
    @I_ActionType VARCHAR(128),
    @I_BrandID BIGINT = NULL,
    @I_TenantCode VARCHAR(128),
    @I_TenantISO CHAR(3),
    @I_BrandTypeCode VARCHAR(32) = NULL,
    @I_BrandTypeID BIGINT = NULL,
    @I_BrandNameEN VARCHAR(256) = NULL,
    @I_BrandNameAR VARCHAR(256) = NULL,
    @I_CategoryID BIGINT = NULL,
    @I_CategoryNameEN VARCHAR(128) = NULL,
    @I_BrandLogoURL VARCHAR(512) = NULL,
    @I_UserNote VARCHAR(2048) = NULL,
    @I_UserID VARCHAR(2048),
    @StatusCode BIT OUTPUT,
    @StatusMessage VARCHAR(128) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @CurrentDateTime DATETIME = GETDATE(),
        @TenantID BIGINT,
        @BrandActiveStatusCode CHAR(1),
        @ErrorMessage VARCHAR(128)

    IF @I_ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT', 'UPSERT-CREATE', 'UPSERT-UPDATE')
    BEGIN
        SET @ErrorMessage = 'Invalid Action Type'
        GOTO ErrorHandler
    END

    IF ISNULL(@I_TenantCode, '') = '' OR ISNULL(@I_TenantISO, '') = '' OR ISNULL(@I_UserID, '') = ''
    BEGIN
        SET @ErrorMessage = 'Invalid Input: TenantCode or ISOCode or UserID is NULL or Empty'
        GOTO ErrorHandler
    END

    SELECT @TenantID = TenantID 
    FROM InMem.Tenant WITH (NOLOCK)
    WHERE TenantCode = @I_TenantCode AND TenantISO = @I_TenantISO

    IF @TenantID IS NULL
    BEGIN
        SET @ErrorMessage = 'No parent record found in InMem.Tenant table'
        GOTO ErrorHandler
    END

    IF NOT EXISTS (
        SELECT 1 FROM InMem.BrandType WITH (NOLOCK)
        WHERE BrandTypeCode = @I_BrandTypeCode OR BrandTypeID = @I_BrandTypeID
    ) AND @I_ActionType <> 'DELETE'
    BEGIN
        SET @ErrorMessage = 'No parent record found in InMem.BrandType table'
        GOTO ErrorHandler
    END

    SELECT @I_BrandTypeID = ISNULL(@I_BrandTypeID, BrandTypeID)
    FROM InMem.BrandType WITH (NOLOCK)
    WHERE BrandTypeCode = @I_BrandTypeCode

    IF NOT EXISTS (
        SELECT 1 FROM InMem.Category WITH (NOLOCK)
        WHERE (CategoryNameEN = @I_CategoryNameEN AND TenantID = @TenantID)
           OR CategoryID = @I_CategoryID
    ) AND @I_ActionType <> 'DELETE'
    BEGIN
        SET @ErrorMessage = 'No parent record found in InMem.Category table'
        GOTO ErrorHandler
    END

    SELECT @I_CategoryID = ISNULL(@I_CategoryID, CategoryID)
    FROM InMem.Category WITH (NOLOCK)
    WHERE CategoryNameEN = @I_CategoryNameEN AND TenantID = @TenantID

    IF @I_ActionType = 'UPSERT'
    BEGIN
        IF @I_BrandID IS NOT NULL
            SET @I_ActionType = 'UPSERT-UPDATE'
        ELSE
            SET @I_ActionType = 'UPSERT-CREATE'
    END

    BEGIN TRY
        BEGIN TRANSACTION

        IF @I_ActionType = 'DELETE'
        BEGIN
            UPDATE InMem.Brand
            SET IsActive = 'N',
                UpdateUserID = @I_UserID,
                UpdateDateTime = @CurrentDateTime
            WHERE BrandID = @I_BrandID
        END

        ELSE IF @I_ActionType IN ('CREATE', 'UPSERT-CREATE')
        BEGIN
            SELECT @BrandActiveStatusCode = IsActive
            FROM InMem.Brand WITH (NOLOCK)
            WHERE TenantID = @TenantID
              AND BrandNameEN = @I_BrandNameEN
              AND BrandTypeID = @I_BrandTypeID

            IF @BrandActiveStatusCode = 'Y'
            BEGIN
                SET @ErrorMessage = 'Brand already exists and is active'
                GOTO ErrorHandler
            END

            IF @BrandActiveStatusCode = 'N'
            BEGIN
                UPDATE InMem.Brand
                SET BrandNameEN = @I_BrandNameEN,
                    BrandNameAR = @I_BrandNameAR,
                    CategoryID = @I_CategoryID,
                    BrandLogoURL = @I_BrandLogoURL,
                    IsActive = 'Y',
                    UpdateUserID = @I_UserID,
                    UpdateDateTime = @CurrentDateTime
                WHERE TenantID = @TenantID
                  AND BrandNameEN = @I_BrandNameEN
                  AND BrandTypeID = @I_BrandTypeID
            END
            ELSE
            BEGIN
                INSERT INTO InMem.Brand (
                    TenantID, BrandNameEN, BrandTypeID, BrandNameAR,
                    CategoryID, BrandLogoURL, IsActive,
                    CreateUserID, CreateDateTime, UpdateUserID, UpdateDateTime
                )
                VALUES (
                    @TenantID, @I_BrandNameEN, @I_BrandTypeID, @I_BrandNameAR,
                    @I_CategoryID, @I_BrandLogoURL, 'Y',
                    @I_UserID, @CurrentDateTime, @I_UserID, @CurrentDateTime
                )
            END
        END

        ELSE IF @I_ActionType IN ('UPDATE', 'UPSERT-UPDATE')
        BEGIN
            IF @I_BrandID IS NULL
            BEGIN
                SET @ErrorMessage = 'BrandID is mandatory for update'
                GOTO ErrorHandler
            END

            UPDATE InMem.Brand
            SET BrandNameEN = @I_BrandNameEN,
                BrandNameAR = @I_BrandNameAR,
                CategoryID = @I_CategoryID,
                BrandLogoURL = @I_BrandLogoURL,
                UpdateUserID = @I_UserID,
                UpdateDateTime = @CurrentDateTime
            WHERE BrandID = @I_BrandID
        END

        INSERT INTO dbo.Audit_Brand (
            BrandID, TenantID, BrandNameEN, BrandTypeID,
            BrandNameAR, CategoryID, BrandLogoURL, IsActive,
            CreateUserID, CreateDateTime, UpdateUserID, UpdateDateTime,
            AuditDateTime, AuditUserID, ActionType
        )
        SELECT
            BrandID, TenantID, BrandNameEN, BrandTypeID,
            BrandNameAR, CategoryID, BrandLogoURL, IsActive,
            CreateUserID, CreateDateTime, UpdateUserID, UpdateDateTime,
            @CurrentDateTime, @I_UserID, @I_ActionType
        FROM InMem.Brand
        WHERE (@I_BrandID IS NOT NULL AND BrandID = @I_BrandID)
           OR (@I_BrandID IS NULL AND BrandNameEN = @I_BrandNameEN AND TenantID = @TenantID)

        COMMIT TRANSACTION

        SET @StatusCode = 0
        SET @StatusMessage = 'Success'
        RETURN
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        SET @StatusCode = 1
        SET @StatusMessage = ERROR_MESSAGE()
        RETURN
    END CATCH

ErrorHandler:
    SET @StatusCode = 1
    SET @StatusMessage = @ErrorMessage
    RETURN
END
