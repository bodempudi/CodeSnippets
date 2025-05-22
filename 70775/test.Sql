CREATE PROCEDURE dbo.usp_Maintain_BrandType
    @ActionType              VARCHAR(20),     -- CREATE / UPDATE / UPSERT / DELETE
    @BrandTypeID             BIGINT       = NULL,   -- Mandatory only for UPDATE or DELETE
    @BrandTypeCode           VARCHAR(32)   = NULL,   -- Mandatory only for CREATE / UPDATE / UPSERT
    @BrandTypeNameEN         VARCHAR(128)  = NULL,   -- Mandatory only for CREATE / UPDATE / UPSERT
    @IsCategoryApplicable    CHAR(1)       = NULL,   -- Optional, default = N
    @UserNote                VARCHAR(2048) = NULL,   -- Optional
    @UserID                  VARCHAR(20)   = NULL    -- Mandatory
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
    ------------------------------------------------------------------------------
    -- Declare local variables
    ------------------------------------------------------------------------------
    DECLARE @CurrentDateTime DATETIME = GETDATE();
    DECLARE @ErrorMessage    VARCHAR(512);

    ------------------------------------------------------------------------------
    -- Mandatory Parameter Validations
    ------------------------------------------------------------------------------
    IF @ActionType IS NULL OR LTRIM(RTRIM(@ActionType)) = ''
    BEGIN
        SET @ErrorMessage = 'ActionType is mandatory and cannot be empty.';
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END

    IF @UserID IS NULL OR LTRIM(RTRIM(@UserID)) = ''
    BEGIN
        SET @ErrorMessage = 'UserID is mandatory and cannot be empty.';
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END

    IF @ActionType IN ('CREATE', 'UPDATE', 'UPSERT')
    BEGIN
        IF @BrandTypeCode IS NULL OR LTRIM(RTRIM(@BrandTypeCode)) = ''
        BEGIN
            SET @ErrorMessage = 'BrandTypeCode is mandatory for CREATE/UPDATE/UPSERT.';
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END

        IF @BrandTypeNameEN IS NULL OR LTRIM(RTRIM(@BrandTypeNameEN)) = ''
        BEGIN
            SET @ErrorMessage = 'BrandTypeNameEN is mandatory for CREATE/UPDATE/UPSERT.';
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END
    END

    IF @ActionType IN ('UPDATE', 'DELETE', 'UPSERT')
    BEGIN
        IF @BrandTypeID IS NULL
        BEGIN
            SET @ErrorMessage = 'BrandTypeID is mandatory for UPDATE/DELETE/UPSERT.';
            RAISERROR(@ErrorMessage, 16, 1);
            RETURN;
        END
    END

    ------------------------------------------------------------------------------
    -- Resolve ActionType if UPSERT (convert to CREATE or UPDATE)
    ------------------------------------------------------------------------------
    IF @ActionType = 'UPSERT'
    BEGIN
        IF EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID)
            SET @ActionType = 'UPDATE';

        IF NOT EXISTS (SELECT 1 FROM InMem.BrandType WHERE BrandTypeID = @BrandTypeID)
            SET @ActionType = 'CREATE';
    END

    ------------------------------------------------------------------------------
    -- Perform CREATE Operation
    ------------------------------------------------------------------------------
    IF @ActionType = 'CREATE'
    BEGIN
        INSERT INTO InMem.BrandType (
            BrandTypeCode,
            BrandTypeNameEN,
            IsCategoryApplicable,
            UserNote,
            CreateUserID,
            CreateDateTime
        )
        VALUES (
            @BrandTypeCode,
            @BrandTypeNameEN,
            @IsCategoryApplicable,
            @UserNote,
            @UserID,
            @CurrentDateTime
        );
        RETURN;
    END

    ------------------------------------------------------------------------------
    -- Perform UPDATE Operation
    ------------------------------------------------------------------------------
    IF @ActionType = 'UPDATE'
    BEGIN
        UPDATE InMem.BrandType
        SET BrandTypeCode         = @BrandTypeCode,
            BrandTypeNameEN       = @BrandTypeNameEN,
            IsCategoryApplicable  = @IsCategoryApplicable,
            UserNote              = @UserNote,
            UpdateUserID          = @UserID,
            UpdateDateTime        = @CurrentDateTime
        WHERE BrandTypeID = @BrandTypeID;
        RETURN;
    END

    ------------------------------------------------------------------------------
    -- Perform DELETE Operation
    ------------------------------------------------------------------------------
    IF @ActionType = 'DELETE'
    BEGIN
        DELETE FROM InMem.BrandType
        WHERE BrandTypeID = @BrandTypeID;
        RETURN;
    END

    ------------------------------------------------------------------------------
    -- Invalid ActionType
    ------------------------------------------------------------------------------
    IF @ActionType NOT IN ('CREATE', 'UPDATE', 'UPSERT', 'DELETE')
    BEGIN
        SET @ErrorMessage = 'Invalid ActionType. Use CREATE, UPDATE, UPSERT, or DELETE.';
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END
END
