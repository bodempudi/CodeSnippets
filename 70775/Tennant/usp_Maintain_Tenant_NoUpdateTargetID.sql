
USE InMem;
GO

---------------------------------------------------------------------------------------------------------------------------------------
-- Procedure Name : usp_Maintain_Tenant
-- Description    : CREATE, UPDATE, DELETE, UPSERT on InMem.Tenant with audit logging
-- Developer      : Venkat Bodempudi
-- Created Date   : 2025-05-26
-- Notes          : StatusCode = 0 (SUCCESS), 1 (FAILURE); All SELECTs use WITH (NOLOCK)
--                  UPSERT logic managed without EffectiveAction or UpdateTargetID
---------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.usp_Maintain_Tenant
(
    @I_ActionType                VARCHAR(128),
    @I_TenantID                  BIGINT            = NULL,
    @I_TenantISOCountryCode      CHAR(2)           = NULL,
    @I_TenantCode                VARCHAR(128)      = NULL,
    @I_TenantNameEN              VARCHAR(128)      = NULL,
    @I_TenantNameAR              NVARCHAR(256)     = NULL,
    @I_DisplayCategoryPrecedence VARCHAR(512)      = NULL,
    @I_UserNote                  VARCHAR(2048)     = NULL,
    @I_UserID                    VARCHAR(20)
)
AS

---------------------------------------------------------------------------------------------------------------------------------------
-- Inline Test Execution Block
---------------------------------------------------------------------------------------------------------------------------------------
-- EXEC dbo.usp_Maintain_Tenant
--     @I_ActionType                = 'CREATE',
--     @I_TenantISOCountryCode      = 'US',
--     @I_TenantCode                = 'TEN001',
--     @I_TenantNameEN              = 'Tenant ABC',
--     @I_TenantNameAR              = N'تينانت أي بي سي',
--     @I_DisplayCategoryPrecedence = 'P1',
--     @I_UserNote                  = 'Initial load',
--     @I_UserID                    = 'venkat';
---------------------------------------------------------------------------------------------------------------------------------------

BEGIN

	---------------------------------------------------------------------------------------------------------------------------------------
	-- Declare Variables
	---------------------------------------------------------------------------------------------------------------------------------------

	DECLARE
		@CurrentDateTime   DATETIME     = GETDATE(),
		@AuditActionType   VARCHAR(128)

	---------------------------------------------------------------------------------------------------------------------------------------
	-- Validate Inputs
	---------------------------------------------------------------------------------------------------------------------------------------

	IF (
		   @I_ActionType IS NULL
		OR LTRIM(RTRIM(@I_ActionType)) = ''
		OR @I_ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT')
	)
	BEGIN
		SELECT
			  StatusCode    = CONVERT(BIT, 1),
			  StatusMessage = CONVERT(VARCHAR(128), 'Invalid or missing ActionType')
		RETURN
	END

	IF (@I_UserID IS NULL OR LTRIM(RTRIM(@I_UserID)) = '')
	BEGIN
		SELECT
			  StatusCode    = CONVERT(BIT, 1),
			  StatusMessage = CONVERT(VARCHAR(128), 'UserID is mandatory')
		RETURN
	END

	---------------------------------------------------------------------------------------------------------------------------------------
	-- Begin TRY-CATCH Block
	---------------------------------------------------------------------------------------------------------------------------------------

	BEGIN TRY
		BEGIN TRANSACTION

		---------------------------------------------------------------------------------------------------------------------------------------
		-- UPSERT
		---------------------------------------------------------------------------------------------------------------------------------------

		IF @I_ActionType = 'UPSERT'
		BEGIN

			IF (
				   @I_TenantISOCountryCode IS NULL OR LTRIM(RTRIM(@I_TenantISOCountryCode)) = ''
				OR @I_TenantCode IS NULL OR LTRIM(RTRIM(@I_TenantCode)) = ''
			)
			BEGIN
				SELECT
					  StatusCode    = CONVERT(BIT, 1),
					  StatusMessage = CONVERT(VARCHAR(128), 'Mandatory fields missing for UPSERT')
				RETURN
			END

			IF EXISTS (
				SELECT 1 FROM InMem.Tenant WITH (NOLOCK)
				WHERE TenantISOCountryCode = @I_TenantISOCountryCode
				  AND TenantCode = @I_TenantCode
			)
			BEGIN
				-- Update
				UPDATE InMem.Tenant
				SET
					  TenantNameEN              = @I_TenantNameEN
					, TenantNameAR              = @I_TenantNameAR
					, DisplayCategoryPrecedence = @I_DisplayCategoryPrecedence
					, UserNote                  = @I_UserNote
					, UpdateUserID              = @I_UserID
					, UpdateDateTime            = @CurrentDateTime
				WHERE
					  TenantISOCountryCode = @I_TenantISOCountryCode
				  AND TenantCode = @I_TenantCode

				SELECT @AuditActionType = 'UPDATE-UPSERT'
			END
			ELSE
			BEGIN
				-- Insert
				INSERT INTO InMem.Tenant
				(
					  TenantISOCountryCode
					, TenantCode
					, TenantNameEN
					, TenantNameAR
					, DisplayCategoryPrecedence
					, IsActive
					, UserNote
					, CreateUserID
					, CreateDateTime
					, UpdateUserID
					, UpdateDateTime
				)
				SELECT
					  @I_TenantISOCountryCode
					, @I_TenantCode
					, @I_TenantNameEN
					, @I_TenantNameAR
					, @I_DisplayCategoryPrecedence
					, 'Y'
					, @I_UserNote
					, @I_UserID
					, @CurrentDateTime
					, @I_UserID
					, @CurrentDateTime

				SELECT @AuditActionType = 'CREATE-UPSERT'
			END
		END

		---------------------------------------------------------------------------------------------------------------------------------------
		-- CREATE
		---------------------------------------------------------------------------------------------------------------------------------------

		IF @I_ActionType = 'CREATE'
		BEGIN
			IF (
				   @I_TenantISOCountryCode IS NULL OR LTRIM(RTRIM(@I_TenantISOCountryCode)) = ''
				OR @I_TenantCode IS NULL OR LTRIM(RTRIM(@I_TenantCode)) = ''
			)
			BEGIN
				SELECT
					  StatusCode    = CONVERT(BIT, 1),
					  StatusMessage = CONVERT(VARCHAR(128), 'Mandatory fields missing for CREATE')
				RETURN
			END

			IF EXISTS (
				SELECT 1 FROM InMem.Tenant WITH (NOLOCK)
				WHERE TenantISOCountryCode = @I_TenantISOCountryCode
				  AND TenantCode = @I_TenantCode
			)
			BEGIN
				SELECT
					  StatusCode    = CONVERT(BIT, 1),
					  StatusMessage = CONVERT(VARCHAR(128), 'Tenant already exists')
				RETURN
			END

			INSERT INTO InMem.Tenant
			(
				  TenantISOCountryCode
				, TenantCode
				, TenantNameEN
				, TenantNameAR
				, DisplayCategoryPrecedence
				, IsActive
				, UserNote
				, CreateUserID
				, CreateDateTime
				, UpdateUserID
				, UpdateDateTime
			)
			SELECT
				  @I_TenantISOCountryCode
				, @I_TenantCode
				, @I_TenantNameEN
				, @I_TenantNameAR
				, @I_DisplayCategoryPrecedence
				, 'Y'
				, @I_UserNote
				, @I_UserID
				, @CurrentDateTime
				, @I_UserID
				, @CurrentDateTime

			SELECT @AuditActionType = 'CREATE'
		END

		---------------------------------------------------------------------------------------------------------------------------------------
		-- UPDATE
		---------------------------------------------------------------------------------------------------------------------------------------

		IF @I_ActionType = 'UPDATE'
		BEGIN
			IF @I_TenantID IS NULL
			BEGIN
				SELECT
					  StatusCode    = CONVERT(BIT, 1),
					  StatusMessage = CONVERT(VARCHAR(128), 'TenantID is required for UPDATE')
				RETURN
			END

			IF NOT EXISTS (
				SELECT 1 FROM InMem.Tenant WITH (NOLOCK)
				WHERE TenantID = @I_TenantID
			)
			BEGIN
				SELECT
					  StatusCode    = CONVERT(BIT, 1),
					  StatusMessage = CONVERT(VARCHAR(128), 'Tenant not found for UPDATE')
				RETURN
			END

			UPDATE InMem.Tenant
			SET
				  TenantNameEN              = @I_TenantNameEN
				, TenantNameAR              = @I_TenantNameAR
				, DisplayCategoryPrecedence = @I_DisplayCategoryPrecedence
				, UserNote                  = @I_UserNote
				, UpdateUserID              = @I_UserID
				, UpdateDateTime            = @CurrentDateTime
			WHERE
				TenantID = @I_TenantID

			SELECT @AuditActionType = 'UPDATE'
		END

		---------------------------------------------------------------------------------------------------------------------------------------
		-- DELETE
		---------------------------------------------------------------------------------------------------------------------------------------

		IF @I_ActionType = 'DELETE'
		BEGIN
			IF @I_TenantID IS NULL
			BEGIN
				SELECT
					  StatusCode    = CONVERT(BIT, 1),
					  StatusMessage = CONVERT(VARCHAR(128), 'TenantID is required for DELETE')
				RETURN
			END

			IF NOT EXISTS (
				SELECT 1 FROM InMem.Tenant WITH (NOLOCK)
				WHERE TenantID = @I_TenantID
			)
			BEGIN
				SELECT
					  StatusCode    = CONVERT(BIT, 1),
					  StatusMessage = CONVERT(VARCHAR(128), 'Tenant not found for DELETE')
				RETURN
			END

			UPDATE InMem.Tenant
			SET
				  IsActive       = 'N'
				, UpdateUserID   = @I_UserID
				, UpdateDateTime = @CurrentDateTime
			WHERE
				TenantID = @I_TenantID

			SELECT @AuditActionType = 'DELETE'
		END

		---------------------------------------------------------------------------------------------------------------------------------------
		-- AUDIT INSERT
		---------------------------------------------------------------------------------------------------------------------------------------

		INSERT INTO dbo.Audit_Tennant
		(
			  TenantID
			, TenantISOCountryCode
			, TenantCode
			, TenantNameEN
			, TenantNameAR
			, DisplayCategoryPrecedence
			, IsActive
			, UserNote
			, CreateUserID
			, CreateDateTime
			, UpdateUserID
			, UpdateDateTime
			, AuditDateTime
			, AuditUserID
			, ActionType
		)
		SELECT
			  TenantID
			, TenantISOCountryCode
			, TenantCode
			, TenantNameEN
			, TenantNameAR
			, DisplayCategoryPrecedence
			, IsActive
			, UserNote
			, CreateUserID
			, CreateDateTime
			, UpdateUserID
			, UpdateDateTime
			, @CurrentDateTime
			, @I_UserID
			, @AuditActionType
		FROM
			InMem.Tenant WITH (NOLOCK)
		WHERE
			TenantISOCountryCode = @I_TenantISOCountryCode
		AND
			TenantCode = @I_TenantCode

		COMMIT

		SELECT
			  StatusCode    = CONVERT(BIT, 0),
			  StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK
		SELECT
			  StatusCode    = CONVERT(BIT, 1),
			  StatusMessage = CONVERT(VARCHAR(128), ERROR_MESSAGE())
	END CATCH
END
GO
