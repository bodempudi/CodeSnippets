
USE InMem;
GO

	---------------------------------------------------------------------------------------------------------------------------------------
	-- Procedure Name : usp_Maintain_Tenant
	-- Description    : CREATE, UPDATE, DELETE, UPSERT on InMem.Tenant with audit logging
	-- Developer      : Venkat Bodempudi
	-- Created Date   : 2025-05-26
	-- Notes          : Full formatting and validation rules applied as per specification
	---------------------------------------------------------------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.usp_Maintain_Tenant
(
	@I_ActionType                VARCHAR(128)
	, @I_TenantID                  BIGINT            = NULL
	, @I_TenantISOCountryCode      CHAR(2)           = NULL
	, @I_TenantCode                VARCHAR(128)      = NULL
	, @I_TenantNameEN              VARCHAR(128)      = NULL
	, @I_TenantNameAR              NVARCHAR(256)     = NULL
	, @I_DisplayCategoryPrecedence VARCHAR(512)      = NULL
	, @I_UserNote                  VARCHAR(2048)     = NULL
	, @I_UserID                    VARCHAR(20)
)
AS

	---------------------------------------------------------------------------------------------------------------------------------------
	-- Inline Test Execution Block
	---------------------------------------------------------------------------------------------------------------------------------------
	-- EXEC dbo.usp_Maintain_Tenant
	-- 	@I_ActionType = 'UPSERT',
	-- 	@I_TenantISOCountryCode = 'US',
	-- 	@I_TenantCode = 'TEN001',
	-- 	@I_TenantNameEN = 'Tenant ABC',
	-- 	@I_TenantNameAR = N'تينانت',
	-- 	@I_DisplayCategoryPrecedence = 'P1',
	-- 	@I_UserNote = 'Test note',
	-- 	@I_UserID = 'venkat';
	---------------------------------------------------------------------------------------------------------------------------------------

BEGIN
	DECLARE
		@CurrentDateTime   DATETIME     = GETDATE(),
		@AuditActionType   VARCHAR(128),
		@ResolvedTenantID  BIGINT

	---------------------------------------------------------------------------------------------------------------------------------------
	-- Validation
	---------------------------------------------------------------------------------------------------------------------------------------
	IF (
		   @I_ActionType IS NULL
		OR LTRIM(RTRIM(@I_ActionType)) = ''
		OR @I_ActionType NOT IN ('CREATE', 'UPDATE', 'DELETE', 'UPSERT')
	)
	BEGIN
		SELECT
			StatusCode = CONVERT(BIT, 1),
			StatusMessage = CONVERT(VARCHAR(128), 'Invalid or missing ActionType')
		RETURN
	END

	IF (@I_UserID IS NULL OR LTRIM(RTRIM(@I_UserID)) = '')
	BEGIN
		SELECT
			StatusCode = CONVERT(BIT, 1),
			StatusMessage = CONVERT(VARCHAR(128), 'UserID is mandatory')
		RETURN
	END

	IF @I_ActionType = 'UPSERT'
	BEGIN
		---------------------------------------------------------------------------------------------------------------------------------------
		-- UPSERT Specific Validation
		---------------------------------------------------------------------------------------------------------------------------------------
		IF (
			   @I_TenantISOCountryCode IS NULL OR LTRIM(RTRIM(@I_TenantISOCountryCode)) = ''
			OR @I_TenantCode IS NULL OR LTRIM(RTRIM(@I_TenantCode)) = ''
			OR @I_DisplayCategoryPrecedence IS NULL OR LTRIM(RTRIM(@I_DisplayCategoryPrecedence)) = ''
		)
		BEGIN
			SELECT
				StatusCode = CONVERT(BIT, 1),
				StatusMessage = CONVERT(VARCHAR(128), 'Mandatory fields missing for UPSERT')
			RETURN
		END

		IF EXISTS (
			SELECT 1
			FROM InMem.Tenant WITH (NOLOCK)
			WHERE TenantISOCountryCode = @I_TenantISOCountryCode
			AND TenantCode = @I_TenantCode
		)
		BEGIN
			SELECT @I_ActionType = 'UPDATE-UPSERT'
		END
		ELSE
		BEGIN
			SELECT @I_ActionType = 'CREATE-UPSERT'
		END
	END

	BEGIN TRY
		BEGIN TRANSACTION

		---------------------------------------------------------------------------------------------------------------------------------------
		-- CREATE / CREATE-UPSERT
		---------------------------------------------------------------------------------------------------------------------------------------
		IF @I_ActionType IN ('CREATE', 'CREATE-UPSERT')
		BEGIN
			IF EXISTS (
				SELECT 1
				FROM InMem.Tenant WITH (NOLOCK)
				WHERE TenantISOCountryCode = @I_TenantISOCountryCode
				AND TenantCode = @I_TenantCode
			)
			BEGIN
				SELECT
					StatusCode = CONVERT(BIT, 1),
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

			SELECT @AuditActionType = @I_ActionType
		END

		---------------------------------------------------------------------------------------------------------------------------------------
		-- UPDATE / UPDATE-UPSERT
		---------------------------------------------------------------------------------------------------------------------------------------
		IF @I_ActionType IN ('UPDATE', 'UPDATE-UPSERT')
		BEGIN
			IF @I_ActionType = 'UPDATE'
			AND NOT EXISTS (
				SELECT 1
				FROM InMem.Tenant WITH (NOLOCK)
				WHERE TenantID = @I_TenantID
			)
			BEGIN
				SELECT
					StatusCode = CONVERT(BIT, 1),
					StatusMessage = CONVERT(VARCHAR(128), 'Tenant not found for UPDATE')
				RETURN
			END

			UPDATE InMem.Tenant
			SET
				TenantNameEN = @I_TenantNameEN
				, TenantNameAR = @I_TenantNameAR
				, DisplayCategoryPrecedence = @I_DisplayCategoryPrecedence
				, UserNote = @I_UserNote
				, UpdateUserID = @I_UserID
				, UpdateDateTime = @CurrentDateTime
			WHERE
				(@I_ActionType = 'UPDATE' AND TenantID = @I_TenantID)
				OR
				(@I_ActionType = 'UPDATE-UPSERT'
				 AND TenantISOCountryCode = @I_TenantISOCountryCode
				 AND TenantCode = @I_TenantCode)

			SELECT @AuditActionType = @I_ActionType
		END

		---------------------------------------------------------------------------------------------------------------------------------------
		-- DELETE
		---------------------------------------------------------------------------------------------------------------------------------------
		IF @I_ActionType = 'DELETE'
		BEGIN
			IF NOT EXISTS (
				SELECT 1
				FROM InMem.Tenant WITH (NOLOCK)
				WHERE TenantID = @I_TenantID
			)
			BEGIN
				SELECT
					StatusCode = CONVERT(BIT, 1),
					StatusMessage = CONVERT(VARCHAR(128), 'Tenant not found for DELETE')
				RETURN
			END

			UPDATE InMem.Tenant
			SET
				IsActive = 'N'
				, UpdateUserID = @I_UserID
				, UpdateDateTime = @CurrentDateTime
			WHERE
				TenantID = @I_TenantID

			SELECT @AuditActionType = 'DELETE'
		END

		---------------------------------------------------------------------------------------------------------------------------------------
		-- AUDIT
		---------------------------------------------------------------------------------------------------------------------------------------
		INSERT INTO dbo.Audit_Tennant
		(
			AuditDateTime
			, AuditUserID
			, ActionType
			, TenantID
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
		)
		SELECT
			@CurrentDateTime
			, @I_UserID
			, @AuditActionType
			, TenantID
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
		FROM
			InMem.Tenant WITH (NOLOCK)
		WHERE
			TenantISOCountryCode = @I_TenantISOCountryCode
		AND
			TenantCode = @I_TenantCode

		COMMIT

		SELECT
			StatusCode = CONVERT(BIT, 0),
			StatusMessage = CONVERT(VARCHAR(128), 'SUCCESS')

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK
		SELECT
			StatusCode = CONVERT(BIT, 1),
			StatusMessage = CONVERT(VARCHAR(128), ERROR_MESSAGE())
	END CATCH
END
GO
