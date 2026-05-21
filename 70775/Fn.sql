CREATE FUNCTION dbo.ufn_GetCategorizationPathDescription
(
    @I_CategoryPath VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

    DECLARE
        @V_CategoryPathDescription VARCHAR(MAX);

    ;WITH PathData
    AS
    (
        SELECT
            SequenceNumber =
                TRY_CONVERT(INT,value)
        FROM STRING_SPLIT(@I_CategoryPath,'|')
    )
    SELECT
        @V_CategoryPathDescription =
            STRING_AGG
            (
                lb.LogicalBlockName
                ,' --> '
            )
            WITHIN GROUP
            (
                ORDER BY pd.SequenceNumber
            )
    FROM PathData pd
    INNER JOIN dbo.CategorizationLogicalBlock lb
        ON pd.SequenceNumber = lb.LogicalBlockSequenceNumber;

    RETURN @V_CategoryPathDescription;

END
GO
