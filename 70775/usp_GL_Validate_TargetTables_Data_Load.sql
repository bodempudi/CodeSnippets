
USE EnterpriseFrameWork_ODS
GO

ALTER PROCEDURE dbo.usp_GL_Validate_TargetTables_Data_Load
    @I_ControlSessionID BIGINT,
    @I_ThreadNumber INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FailedTableList VARCHAR(MAX) = '';

    WITH AllTables AS
    (
        SELECT
            td.SourceCheckCount,
            td.StageCheckCount,
            td.TargetCheckCount,
            td.SourceCheckSum,
            td.StageCheckSum,
            td.TargetCheckSum,
            td.LoadModeType,
            td.SourceSchemaName,
            td.SourceTableName,
            td.ControlSessionID,
            td.ThreadNumber,
            td.StageLoadExecutionStatusCode,
            td.TargetLoadExecutionStatusCode,

            DerivedSourceCheckCount = 
                CASE WHEN td.IsControlCheckSumCheckCountApplicable = 'Y' THEN ISNULL(td.SourceCheckCount, -1) ELSE -1 END,
            DerivedStageCheckCount = 
                CASE WHEN td.IsControlCheckSumCheckCountApplicable = 'Y' THEN ISNULL(td.StageCheckCount, -1) ELSE -1 END,
            DerivedTargetCheckCount = 
                CASE WHEN td.IsControlCheckSumCheckCountApplicable = 'Y' THEN ISNULL(td.TargetCheckCount, -1) ELSE -1 END,
            DerivedSourceCheckSum = 
                CASE WHEN td.IsControlCheckSumCheckCountApplicable = 'Y' THEN ISNULL(td.SourceCheckSum, '') ELSE '' END,
            DerivedStageCheckSum = 
                CASE WHEN td.IsControlCheckSumCheckCountApplicable = 'Y' THEN ISNULL(td.StageCheckSum, '') ELSE '' END,
            DerivedTargetCheckSum = 
                CASE WHEN td.IsControlCheckSumCheckCountApplicable = 'Y' THEN ISNULL(td.TargetCheckSum, '') ELSE '' END

        FROM dbo.v_GL_GetLatestMasterTableDetail td WITH (NOLOCK)
        WHERE td.ControlSessionID = @I_ControlSessionID
          AND td.ThreadNumber = ISNULL(NULLIF(@I_ThreadNumber, 0), td.ThreadNumber)
    )

    SELECT 
        @FailedTableList =
            ISNULL(@FailedTableList, '') +
            '-- These are the list of tables, whose data load failed --' + CHAR(10) +
            td.SourceSchemaName + '.' + td.SourceTableName + CHAR(10) +
            'SourceCheckCount = ' + CONVERT(VARCHAR(100), td.SourceCheckCount) + CHAR(10) +
            CASE WHEN td.LoadModeType <> 'INSERT' 
                 THEN 'StageCheckCount = ' + CONVERT(VARCHAR(100), td.StageCheckCount) + CHAR(10)
                 ELSE ''
            END +
            'TargetCheckCount = ' + CONVERT(VARCHAR(100), td.TargetCheckCount) + CHAR(10) +
            'SourceCheckSum = ' + CONVERT(VARCHAR(100), td.SourceCheckSum) + CHAR(10) +
            CASE WHEN td.LoadModeType <> 'INSERT' 
                 THEN 'StageCheckSum = ' + CONVERT(VARCHAR(100), td.StageCheckSum) + CHAR(10)
                 ELSE ''
            END +
            'TargetCheckSum = ' + CONVERT(VARCHAR(100), td.TargetCheckSum) + CHAR(10)
    FROM AllTables td WITH (NOLOCK)
    WHERE td.ControlSessionID = @I_ControlSessionID
      AND td.ThreadNumber = ISNULL(NULLIF(@I_ThreadNumber, 0), td.ThreadNumber)
      AND (
            ISNULL(td.StageLoadExecutionStatusCode, '') NOT IN ('301-SUCCESS', '101-INITIATED')
            OR ISNULL(td.TargetLoadExecutionStatusCode, '') NOT IN ('301-SUCCESS', '101-INITIATED')
            OR td.DerivedSourceCheckCount <> td.DerivedTargetCheckCount
            OR td.DerivedSourceCheckSum   <> td.DerivedTargetCheckSum
            OR (
                td.LoadModeType <> 'INSERT' AND (
                    td.DerivedSourceCheckCount <> td.DerivedStageCheckCount
                    OR td.DerivedSourceCheckSum   <> td.DerivedStageCheckSum
                )
            )
        );

    SELECT FailedTableList = @FailedTableList;
END
