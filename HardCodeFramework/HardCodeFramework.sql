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
        Delim = ISNULL(NULLIF(c.ResultSetColumnsDelimiter, N''), N'~||~')  -- default to ~||~, in case of single column, no delimiter
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
        N'["' + REPLACE(STRING_ESCAPE(b.ResultSetValues, N'json'), b.Delim, N'","') + N'"]'
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


--Seeding single column result set data
INSERT INTO dbo.Configurations
( ResultSetName, ResultSetHeaders, ResultSetValues, ResultSetColumnsDelimiter, ResultSetColumnsDatatypes )
VALUES
(N'IsActiveY',N'yescode',N'y',N'~||~',N'nvarchar(10)');
GO

;WITH IsActiveY AS
(
    SELECT 
		TOP (1)
        ActiveCode = TRY_CONVERT(char(1),[Value])
    FROM dbo.vw_Configurations_Resultset
    WHERE 
		ResultSetName = N'IsActiveY' 
		AND Ordinal = 0
    ORDER BY RowID
)
SELECT * FROM IsActiveY;  
go
 
INSERT INTO dbo.Configurations
( ResultSetName,ResultSetHeaders,ResultSetValues,ResultSetColumnsDelimiter,ResultSetColumnsDatatypes )
VALUES
(N'ExecutionStatusCodes',N'inprogress~||~success',N'101~||~202',N'~||~',N'int~||~int' );
GO

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
						THEN TRY_CONVERT(int, [Value]) 
				END
			) -- here max and group by required for pivoting purpose.
		,Success = 
			MAX
			(
				CASE 
					WHEN Ordinal = 1 
						THEN TRY_CONVERT(int, [Value]) 
				END
			)
  FROM kv
  GROUP BY RowID
)
SELECT * FROM FinalExecutionStatusCodes;
GO

INSERT INTO dbo.Configurations
(ResultSetName,ResultSetHeaders,ResultSetValues,ResultSetColumnsDelimiter,ResultSetColumnsDatatypes)
VALUES
(N'TransactionPromoCodeChannel',N'transactionnumber~||~promocode~||~channel',N'1001~||~ap~||~web',N'~||~',N'int~||~nvarchar(20)~||~nvarchar(20)'),
(N'TransactionPromoCodeChannel',N'transactionnumber~||~promocode~||~channel',N'1002~||~bx~||~branch',N'~||~',N'int~||~nvarchar(20)~||~nvarchar(20)'),
(N'TransactionPromoCodeChannel',N'transactionnumber~||~promocode~||~channel',N'1003~||~cz~||~mobile',N'~||~',N'int~||~nvarchar(20)~||~nvarchar(20)');
GO

;WITH kv AS 
(
	SELECT 
		RowID
		,Ordinal
		,[Value]
	FROM dbo.vw_Configurations_Resultset
	WHERE 
		ResultSetName = N'TransactionPromoCodeChannel'
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

 
