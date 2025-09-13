USE EnterpriseFramework_ODS;
GO

DROP VIEW IF EXISTS dbo.vw_Configurations_Resultset;
GO

DROP TABLE IF EXISTS dbo.Configurations;
GO

CREATE TABLE dbo.Configurations
(
    ID                          int IDENTITY(1,1) NOT NULL,
    ResultSetName               varchar(500)      NOT NULL,
    ResultSetHeaders            nvarchar(max)     NOT NULL,
    ResultSetValues             nvarchar(max)     NOT NULL,
    ResultSetColumnsDelimiter   nvarchar(50)      NULL,
    ResultSetColumnsDatatypes   nvarchar(max)     NULL,
    CONSTRAINT PK_Configurations_ID PRIMARY KEY CLUSTERED (ID)
);
GO

/*

we can create index if required
CREATE INDEX IX_Configurations_ResultSetName ON dbo.Configurations(ResultSetName, ID);
GO

*/
 
CREATE OR ALTER VIEW dbo.vw_Configurations_Resultset
AS
WITH Base AS 
(
    SELECT
        RowID = c.ID,
        c.ResultSetName,
        c.ResultSetHeaders,
        c.ResultSetValues,
        Delimiter = ISNULL(NULLIF(c.ResultSetColumnsDelimiter, N''), N'~||~')  -- default to ~||~, in case of single column, no delimiter
    FROM dbo.Configurations AS c
),
Hdr AS 
(  
	-- headers ALWAYS split on ~||~
    SELECT
        b.ResultSetName
		, b.RowID
		,Ordinal = TRY_CONVERT(int, h.[key])
        ,HeaderName = LTRIM(RTRIM(h.[value]))
    FROM Base AS b
    CROSS APPLY OPENJSON
	(
        N'["' + REPLACE(STRING_ESCAPE(b.ResultSetHeaders, N'json'), N'~||~', N'","') + N'"]'
    ) AS h
),
Val AS 
(  -- values split on row delimiter (defaults to ~||~)
    SELECT
        b.ResultSetName
		,b.RowID
		,Ordinal = TRY_CONVERT(int, v.[key])
		,[Value] = LTRIM(RTRIM(v.[value]))
    FROM Base AS b
    CROSS APPLY OPENJSON
	(
        N'["' + REPLACE(STRING_ESCAPE(b.ResultSetValues, N'json'), b.Delimiter, N'","') + N'"]'
		--Delimited JSON Conversion after " based text qualifier
    ) AS v
)
SELECT 
	Hdr.ResultSetName
	,Hdr.RowID
	,Hdr.Ordinal
	,Hdr.HeaderName
	,Val.[Value]
FROM Hdr
	LEFT JOIN Val
		ON  Val.ResultSetName = Hdr.ResultSetName
		AND Val.RowID         = Hdr.RowID
		AND Val.Ordinal       = Hdr.Ordinal;
GO
--Generic View Completed.
-----------------------------------------------------------------------------------------------------------
--Now seed the configurations table

INSERT INTO dbo.Configurations
( ResultSetName, ResultSetHeaders, ResultSetValues, ResultSetColumnsDelimiter, ResultSetColumnsDatatypes )
VALUES
(N'IsActiveY',N'yescode',N'y',N'~||~',N'nvarchar(10)');
GO

INSERT INTO dbo.Configurations
( ResultSetName,ResultSetHeaders,ResultSetValues,ResultSetColumnsDelimiter,ResultSetColumnsDatatypes )
VALUES
(N'ExecutionStatusCodes',N'InProgress~||~Success',N'101-InProgress~||~202-Success',N'~||~',N'int~||~int' );
GO

INSERT INTO dbo.Configurations
(ResultSetName,ResultSetHeaders,ResultSetValues,ResultSetColumnsDelimiter,ResultSetColumnsDatatypes)
VALUES
(N'TransactionNumberPromoCodeChannel',N'TransactionNumber~||~PromoCode~||~Channel',N'1001~||~AP~||~Web',N'~||~',N'int~||~nvarchar(20)~||~nvarchar(20)'),
(N'TransactionNumberPromoCodeChannel',N'TransactionNumber~||~PromoCode~||~Channel',N'1002~||~BX~||~Branch',N'~||~',N'int~||~nvarchar(20)~||~nvarchar(20)'),
(N'TransactionNumberPromoCodeChannel',N'TransactionNumber~||~PromoCode~||~Channel',N'1003~||~CZ~||~Mobile',N'~||~',N'int~||~nvarchar(20)~||~nvarchar(20)');
GO
----------------------------------------------------------------------------------------------------------------------
--Let's Check view data
SELECT 
	* 
FROM dbo.vw_Configurations_Resultset
WHERE 
	ResultSetName IN (N'IsActiveY', N'ExecutionStatusCodes', N'TransactionPromoCodeChannel');
----------------------------------------------------------------------------------------------------------------------
;WITH IsActiveY AS
(
    SELECT 
		TOP (1)
        RowID
		,ActiveCode = TRY_CONVERT(char(1),[Value])
    FROM dbo.vw_Configurations_Resultset
    WHERE 
		ResultSetName = N'IsActiveY' 
		AND Ordinal = 0
    ORDER BY RowID
)
SELECT * FROM IsActiveY;  
go
----------------------------------------------------------------------------------------------------------------------- 
;WITH kv AS 
(
  SELECT 
	RowID
	,Ordinal
	,[Value]
  FROM dbo.vw_Configurations_Resultset
  WHERE 
	ResultSetName = N'ExecutionStatusCodes'
),
FinalExecutionStatusCodes AS 
(
	SELECT
		RowID
		,InProgress = 
			MAX
			(
				CASE 
					WHEN Ordinal = 0 
						THEN TRY_CONVERT(VARCHAR(128), [Value]) 
				END
			) -- here max and group by required for pivoting purpose.
		,Success = 
			MAX
			(
				CASE 
					WHEN Ordinal = 1 
						THEN TRY_CONVERT(VARCHAR(128), [Value]) 
				END
			)
  FROM kv
  GROUP BY RowID
)
SELECT * FROM FinalExecutionStatusCodes;
GO
----------------------------------------------------------------------------------------------------------------------------------
;WITH kv AS 
(
	SELECT 
		RowID
		,Ordinal
		,[Value]
	FROM dbo.vw_Configurations_Resultset
	WHERE 
		ResultSetName = N'TransactionNumberPromoCodeChannel'
),
RequiredTransactionPromoCodeChannel AS 
(
	SELECT
		RowID
		,TransactionNumber = 
			MAX
			(
				CASE 
					WHEN Ordinal = 0 
						THEN TRY_CONVERT(int,[Value]) 
				END
			)
		,PromoCode = 
			MAX
			(
				CASE 
					WHEN Ordinal = 1 
						THEN [Value]  
				END
			)
		,Channel = 
			MAX
			(
				CASE 
					WHEN Ordinal = 2 
						THEN [Value]  
				END
			)
  FROM kv
  GROUP BY 
	RowID
)
SELECT * FROM RequiredTransactionPromoCodeChannel;
GO
-----------------------------------------------------------------------------------------------------------------------------------------------
 
