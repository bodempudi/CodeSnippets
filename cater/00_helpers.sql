SET NOCOUNT ON;
GO
/*==================================================================================================
PFM Categorization Helpers (v3)
==================================================================================================*/

CREATE OR ALTER PROCEDURE dbo.usp_Categorization_PathAppendMerchant
(
      @I_Path          NVARCHAR(MAX) = NULL
    , @I_Step          NVARCHAR(200)
    , @I_Key           NVARCHAR(4000) = NULL
    , @I_Hit           CHAR(1)         = 'N'
    , @I_CategoryID    BIGINT          = NULL
    , @I_Reason        NVARCHAR(2000)  = NULL
    , @I_IsHealed      CHAR(1)         = 'N'
    , @O_Path          NVARCHAR(MAX)   OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @V NVARCHAR(MAX) =
        CONCAT(
            N'[', @I_Step,
            CASE WHEN @I_Key IS NULL THEN N'' ELSE CONCAT(N'|Key=', @I_Key) END,
            CONCAT(N'|Hit=', @I_Hit),
            CASE WHEN @I_CategoryID IS NULL THEN N'' ELSE CONCAT(N'|Cat=', CONVERT(NVARCHAR(30), @I_CategoryID)) END,
            CASE WHEN @I_IsHealed = 'Y' THEN N'|Heal=Y' ELSE N'' END,
            CASE WHEN @I_Reason IS NULL THEN N'' ELSE CONCAT(N'|', @I_Reason) END,
            N'];'
        );

    SET @O_Path = COALESCE(@I_Path, N'') + @V;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Categorization_PathAppendCategory
(
      @I_Path          NVARCHAR(MAX) = NULL
    , @I_Step          NVARCHAR(200)
    , @I_Key           NVARCHAR(4000) = NULL
    , @I_Hit           CHAR(1)         = 'N'
    , @I_CategoryID    BIGINT          = NULL
    , @I_Reason        NVARCHAR(2000)  = NULL
    , @I_IsHealed      CHAR(1)         = 'N'
    , @O_Path          NVARCHAR(MAX)   OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @V NVARCHAR(MAX) =
        CONCAT(
            N'[', @I_Step,
            CASE WHEN @I_Key IS NULL THEN N'' ELSE CONCAT(N'|Key=', @I_Key) END,
            CONCAT(N'|Hit=', @I_Hit),
            CASE WHEN @I_CategoryID IS NULL THEN N'' ELSE CONCAT(N'|Cat=', CONVERT(NVARCHAR(30), @I_CategoryID)) END,
            CASE WHEN @I_IsHealed = 'Y' THEN N'|Heal=Y' ELSE N'' END,
            CASE WHEN @I_Reason IS NULL THEN N'' ELSE CONCAT(N'|', @I_Reason) END,
            N'];'
        );

    SET @O_Path = COALESCE(@I_Path, N'') + @V;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_Categorization_RegexIsMatch
(
      @I_Pattern            NVARCHAR(4000)
    , @I_Input              NVARCHAR(4000)
    , @I_IsCaseSensitive    CHAR(1) = 'N'
)
RETURNS BIT
AS
BEGIN
    DECLARE @V_Flags VARCHAR(30) = CASE WHEN COALESCE(@I_IsCaseSensitive,'N')='Y' THEN 'c' ELSE 'i' END;
    RETURN IIF(REGEXP_LIKE(@I_Input, @I_Pattern, @V_Flags) = 1, 1, 0);
END;
GO

