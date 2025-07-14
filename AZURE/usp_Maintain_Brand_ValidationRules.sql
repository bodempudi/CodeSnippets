
-- Validation Rules for usp_Maintain_Brand Stored Procedure

/*
--------------------------------------------------------------------------------------
| Parameter             | Type            | Mandatory | Notes                         |
|-----------------------|-----------------|-----------|-------------------------------|
| @I_ActionType         | varchar(128)    | Yes       | CREATE, UPDATE, DELETE, UPSERT|
|                                       |           | UPSERT for ETL only           |
| @I_BrandID            | bigint          | Conditionally | Required for UPDATE, DELETE, UPSERT-UPDATE |
| @I_TenantISO          | char(2)         | Yes       | Always mandatory              |
| @I_TenantCode         | varchar(128)    | Yes       | Always mandatory              |
| @I_BrandTypeID        | bigint          | Yes/No    | Mandatory for CREATE/UPSERT   |
| @I_BrandTypeCode      | varchar(32)     | Yes/No    | Optional unless BrandTypeID is NULL |
| @I_BrandNameEN        | varchar(128)    | Yes/No    | Required for CREATE/UPDATE    |
| @I_BrandNameAR        | nvarchar(256)   | No        | Optional                      |
| @I_CategoryID         | bigint          | No        | Optional but validate if given|
| @I_CategoryNameEN     | varchar(128)    | No        | Optional but validate if given|
| @I_BrandLogoURL       | varchar(512)    | Yes/No    | Optional                      |
| @I_UserNote           | varchar(2048)   | No        | Optional                      |
| @I_UserID             | varchar(20)     | Yes       | Always mandatory              |
--------------------------------------------------------------------------------------
*/

-- Sample Validation Implementation Snippets:

-- 1. Validate ActionType
IF @I_ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT', 'UPSERT-CREATE', 'UPSERT-UPDATE')
BEGIN
    SET @StatusCode = 1
    SET @StatusMessage = 'Invalid Action Type'
    RETURN
END

-- 2. Validate Mandatory Inputs
IF ISNULL(@I_TenantCode, '') = '' OR ISNULL(@I_TenantISO, '') = '' OR ISNULL(@I_UserID, '') = ''
BEGIN
    SET @StatusCode = 1
    SET @StatusMessage = 'Missing TenantCode, ISOCode or UserID'
    RETURN
END

-- 3. Derive BrandTypeID if only BrandTypeCode is provided
IF @I_BrandTypeID IS NULL AND @I_BrandTypeCode IS NOT NULL
BEGIN
    SELECT @I_BrandTypeID = BrandTypeID
    FROM InMem.BrandType WITH (NOLOCK)
    WHERE BrandTypeCode = @I_BrandTypeCode
END

-- 4. Derive CategoryID if only CategoryNameEN is provided
IF @I_CategoryID IS NULL AND @I_CategoryNameEN IS NOT NULL
BEGIN
    SELECT @I_CategoryID = CategoryID
    FROM InMem.Category WITH (NOLOCK)
    WHERE CategoryNameEN = @I_CategoryNameEN AND TenantID = @TenantID
END

-- 5. Validate for CREATE or UPSERT-CREATE
IF @I_ActionType IN ('CREATE', 'UPSERT-CREATE')
BEGIN
    IF ISNULL(@I_BrandNameEN, '') = ''
    BEGIN
        SET @StatusCode = 1
        SET @StatusMessage = 'BrandNameEN is mandatory for creation'
        RETURN
    END

    IF @I_BrandTypeID IS NULL
    BEGIN
        SET @StatusCode = 1
        SET @StatusMessage = 'BrandTypeID is mandatory for creation'
        RETURN
    END
END

-- 6. Validate for UPDATE or UPSERT-UPDATE
IF @I_ActionType IN ('UPDATE', 'UPSERT-UPDATE')
BEGIN
    IF @I_BrandID IS NULL
    BEGIN
        SET @StatusCode = 1
        SET @StatusMessage = 'BrandID is mandatory for update'
        RETURN
    END
END

-- 7. Validate DELETE
IF @I_ActionType = 'DELETE' AND @I_BrandID IS NULL
BEGIN
    SET @StatusCode = 1
    SET @StatusMessage = 'BrandID is required for delete'
    RETURN
END

-- 8. Convert UPSERT to specific mode
IF @I_ActionType = 'UPSERT'
BEGIN
    IF @I_BrandID IS NOT NULL
        SET @I_ActionType = 'UPSERT-UPDATE'
    ELSE
        SET @I_ActionType = 'UPSERT-CREATE'
END

-- 9. Restrict UPSERT for Channel (if required via context/flag)
-- Add check to restrict channel users if applicable

-- 10. Validate existence of Tenant, Category, BrandType if IDs present
-- Already implemented in SP with EXISTS / JOIN queries

-- Final note: Insert audit log for every operation.
