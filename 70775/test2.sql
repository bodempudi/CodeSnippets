CREATE PROCEDURE dbo.usp_Maintain_BrandType
    @ActionType              VARCHAR(20),     -- CREATE / UPDATE / UPSERT / DELETE
    @BrandTypeID             BIGINT       = NULL,
    @BrandTypeCode           VARCHAR(32)   = NULL,
    @BrandTypeNameEN         VARCHAR(128)  = NULL,
    @IsCategoryApplicable    CHAR(1)       = NULL,
    @UserNote                VARCHAR(2048) = NULL,
    @UserID                  VARCHAR(20)   = NULL
AS
/*****************************************************************************************
    Name      : usp_Maintain_BrandType
    Purpose   : To Create / Update / Delete / Upsert data in BrandType table
    Author    : Venkat Bodempudi
    Date      : 22-May-2025

    EXEC dbo.usp_Maintain_BrandType
        @ActionType            = 'UPSERT',
        @BrandTypeID           = 1001,
        @BrandTypeCode         = 'MERCH',
        @BrandTypeNameEN       = 'Merchant Code for all Non-EMI registered Merchant Transaction',
        @IsCategoryApplicable  = 'N',
        @UserNote              = 'System',
        @UserID                = 'venkat';

******************************************************************************************
    Change History:
******************************************************************************************
    Date         Author              Description                         Status
    -----------  ------------------  ----------------------------------  ----------------
    22-May-2025  Venkat Bodempudi    Created                             Development Phase
*****************************************************************************************/
BEGIN
    ------------------------------------------------------
    -- Declare output/status variables
    ------------------------------------------------------
    DECLARE @CurrentDateTime DATETIME
    DECLARE @StatusCode BIT
    DECLARE @StatusMessage VARCHAR(256)

    SELECT @CurrentDateTime = GETDATE()

    ------------------------------------------------------
    -- Validation: ActionType
    ------------------------------------------------------
    IF @ActionType IS NULL OR LTRIM(RTRIM(@ActionType)) = ''
    BEGIN
        SELECT 
            @StatusCode    = CONVERT(BIT, 0),
            @StatusMessage = CONVERT(VARCHAR(128), 'ActionType is mandatory and cannot be empty.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    IF @ActionType NOT IN ('CREATE', 'UPDATE', 'UPSERT', 'DELETE')
    BEGIN
        SELECT 
            @StatusCode    = CONVERT(BIT, 0),
            @StatusMessage = CONVERT(VARCHAR(128), 'Invalid ActionType!')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    ------------------------------------------------------
    -- Validation: UserID
    ------------------------------------------------------
    IF @UserID IS NULL OR LTRIM(RTRIM(@UserID)) = ''
    BEGIN
        SELECT 
            @StatusCode    = CONVERT(BIT, 0),
            @StatusMessage = CONVERT(VARCHAR(128), 'UserID is mandatory and cannot be empty.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    ------------------------------------------------------
    -- Validation: BrandTypeCode / BrandTypeNameEN
    ------------------------------------------------------
    IF @ActionType IN ('CREATE', 'UPDATE', 'UPSERT')
    BEGIN
        IF @BrandTypeCode IS NULL OR LTRIM(RTRIM(@BrandTypeCode)) = ''
        BEGIN
            SELECT 
                @StatusCode    = CONVERT(BIT, 0),
                @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeCode is mandatory for CREATE/UPDATE/UPSERT.')
            SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
            RETURN
        END

        IF @BrandTypeNameEN IS NULL OR LTRIM(RTRIM(@BrandTypeNameEN)) = ''
        BEGIN
            SELECT 
                @StatusCode    = CONVERT(BIT, 0),
                @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeNameEN is mandatory for CREATE/UPDATE/UPSERT.')
            SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
            RETURN
        END
    END

    ------------------------------------------------------
    -- Validation: BrandTypeID for non-Create
    ------------------------------------------------------
    IF @ActionType IN ('UPDATE', 'DELETE', 'UPSERT')
    BEGIN
        IF @BrandTypeID IS NULL
        BEGIN
            SELECT 
                @StatusCode    = CONVERT(BIT, 0),
                @StatusMessage = CONVERT(VARCHAR(128), 'BrandTypeID is required for UPDATE, DELETE, and UPSERT.')
            SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
            RETURN
        END
    END

    ------------------------------------------------------
    -- UPSERT Resolution
    ------------------------------------------------------
    IF @ActionType = 'UPSERT'
    BEGIN
        IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID)
            SELECT @ActionType = 'UPDATE'

        IF NOT EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID)
            SELECT @ActionType = 'CREATE'
    END

    ------------------------------------------------------
    -- CREATE
    ------------------------------------------------------
    IF @ActionType = 'CREATE'
    BEGIN
        INSERT INTO InMem.BrandType (
            BrandTypeCode, BrandTypeNameEN, IsCategoryApplicable,
            UserNote, CreateUserID, CreateDateTime
        )
        VALUES (
            @BrandTypeCode, @BrandTypeNameEN, @IsCategoryApplicable,
            @UserNote, @UserID, @CurrentDateTime
        )

        SELECT 
            @StatusCode    = CONVERT(BIT, 1),
            @StatusMessage = CONVERT(VARCHAR(128), 'BrandType created successfully.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    ------------------------------------------------------
    -- UPDATE
    ------------------------------------------------------
    IF @ActionType = 'UPDATE'
    BEGIN
        UPDATE InMem.BrandType
        SET BrandTypeCode         = @BrandTypeCode,
            BrandTypeNameEN       = @BrandTypeNameEN,
            IsCategoryApplicable  = @IsCategoryApplicable,
            UserNote              = @UserNote,
            UpdateUserID          = @UserID,
            UpdateDateTime        = @CurrentDateTime
        WHERE BrandTypeID = @BrandTypeID

        SELECT 
            @StatusCode    = CONVERT(BIT, 1),
            @StatusMessage = CONVERT(VARCHAR(128), 'BrandType updated successfully.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END

    ------------------------------------------------------
    -- DELETE
    ------------------------------------------------------
    IF @ActionType = 'DELETE'
    BEGIN
        DELETE FROM InMem.BrandType
        WHERE BrandTypeID = @BrandTypeID

        SELECT 
            @StatusCode    = CONVERT(BIT, 1),
            @StatusMessage = CONVERT(VARCHAR(128), 'BrandType deleted successfully.')
        SELECT @StatusCode AS StatusCode, @StatusMessage AS StatusMessage
        RETURN
    END
END
