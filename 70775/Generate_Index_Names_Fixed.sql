
-- =============================================
-- Script: Generate Unique Index Names for a Table
-- Purpose: Handle duplicates when columns are same but sort order differs
-- Features:
--   * Uses NormalizedKey (column names without ASC/DESC)
--   * Adds numeric suffix only for duplicates (different sort orders)
--   * Handles max length (124) by truncating + adding checksum hash
--   * Preserves readability with SortPattern
-- =============================================

DECLARE @IndexTargetTableName SYSNAME = 'TB_ONBOARDING_HISTORY';

;WITH IndexMeta AS
(
    SELECT 
        IndexTypeCode,
        IndexKey,            -- 'Column1 ASC, Column2 DESC'
        IndexDefinition,     -- 'ASC,DESC'
        NormalizedKey = REPLACE(REPLACE(IndexKey, 'ASC', ''), 'DESC', ''),
        SortPattern = REPLACE(REPLACE(IndexDefinition, ',', ''), ' ', ''), -- e.g., AAD
        MINLoadControlIndexID,
        ClusteredORNonClustered
    FROM YourMetadataTable -- Replace with actual metadata source
    WHERE TargetTableName = @IndexTargetTableName
),
NumberedIndexes AS
(
    SELECT 
        IndexTypeCode,
        IndexKey,
        IndexDefinition,
        NormalizedKey,
        SortPattern,
        ClusteredORNonClustered,
        MINLoadControlIndexID,
        RN = ROW_NUMBER() OVER (PARTITION BY NormalizedKey ORDER BY IndexDefinition),
        DuplicateCount = COUNT(*) OVER (PARTITION BY NormalizedKey)
    FROM IndexMeta
),
BaseNames AS
(
    SELECT
        IndexTypeCode,
        IndexKey,
        IndexDefinition,
        ClusteredORNonClustered,
        BaseName = IndexTypeCode + '_' + @IndexTargetTableName + '_' +
                   REPLACE(REPLACE(NormalizedKey, ',', '_'), ' ', '') + '_' + SortPattern,
        RN,
        DuplicateCount
    FROM NumberedIndexes
)
SELECT 
    FinalIndexName = CASE
        WHEN LEN(BaseName) > 124 THEN 
            LEFT(BaseName, 110) + '_' + CAST(ABS(CHECKSUM(BaseName)) AS VARCHAR(10))
        ELSE 
            CASE 
                WHEN DuplicateCount > 1 AND RN > 1 THEN BaseName + '_' + CAST(RN AS VARCHAR(5))
                ELSE BaseName
            END
    END,
    IndexTypeCode,
    ClusteredORNonClustered,
    IndexKey,
    IndexDefinition
FROM BaseNames;
