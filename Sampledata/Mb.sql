;WITH N
AS
(
    SELECT TOP (1000000)
           ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RN
    FROM sys.all_objects A
    CROSS JOIN sys.all_objects B
    CROSS JOIN sys.all_objects C
),
M
AS
(
    SELECT
         M.*
        ,ROW_NUMBER() OVER (ORDER BY M.MerchantID) AS BaseRN
        ,COUNT(*) OVER () AS BaseCount
    FROM InMem.Merchant M
    WHERE M.TennantID = 3
      AND M.IsActive = 'Y'
),
B
AS
(
    SELECT
         B.*
        ,ROW_NUMBER() OVER (ORDER BY B.BrandID) AS BrandRN
        ,COUNT(*) OVER () AS BrandCount
    FROM InMem.Brand B
    WHERE B.TennantID = 3
      AND B.IsActive = 'Y'
)
SELECT
'INSERT INTO dinarWise_OLTP.MerchantBrand
(
     MerchantID
    ,MerchantNameEN
    ,MerchantNameAR
    ,SubMerchantNameEN
    ,SubMerchantNameAR
    ,MerchantCategoryID
    ,MerchantCategoryNameEN
    ,MerchantCategoryNameAR
    ,MerchantCategoryLogoURL
    ,MerchantParentCategoryID
    ,MerchantParentCategoryNameEN
    ,MerchantParentCategoryNameAR
    ,MerchantParentCategoryLogoURL
    ,BrandID
    ,BrandNameEN
    ,BrandNameAR
    ,BrandLogoURL
    ,BrandTypeCode
    ,BrandCategoryID
    ,BrandCategoryNameEN
    ,BrandCategoryNameAR
    ,BrandCategoryLogoURL
    ,BrandParentCategoryID
    ,BrandParentCategoryNameEN
    ,BrandParentCategoryNameAR
    ,BrandParentCategoryLogoURL
    ,DisplayMerchantNameEN
    ,DisplayMerchantNameAR
    ,DisplayBrandNameEN
    ,DisplayBrandNameAR
    ,DisplayNameEN
    ,DisplayNameAR
    ,CreateDateTime
    ,UpdateDateTime
)
VALUES
(
     ' + CAST(1000000 + N.RN AS VARCHAR(20)) + '
    ,''' + REPLACE(LEFT(ISNULL(M.MerchantNameEN, 'Test Merchant') + ' ' + CAST(N.RN AS VARCHAR(20)), 128), '''', '''''') + '''
    ,N''' + REPLACE(LEFT(ISNULL(M.MerchantNameAR, N'تاجر تجريبي') + N' ' + CAST(N.RN AS NVARCHAR(20)), 256), '''', '''''') + '''
    ,' + CASE WHEN M.SubMerchantNameEN IS NULL THEN 'NULL' ELSE '''' + REPLACE(LEFT(M.SubMerchantNameEN, 128), '''', '''''') + '''' END + '
    ,' + CASE WHEN M.SubMerchantNameAR IS NULL THEN 'NULL' ELSE 'N''' + REPLACE(LEFT(M.SubMerchantNameAR, 256), '''', '''''') + '''' END + '

    ,' + CASE
            WHEN N.RN % 3 = 0 AND M.CategoryID IS NOT NULL THEN CAST(M.CategoryID AS VARCHAR(20))
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 0 AND MC.CategoryNameEN IS NOT NULL THEN '''' + REPLACE(MC.CategoryNameEN, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 0 AND MC.CategoryNameAR IS NOT NULL THEN 'N''' + REPLACE(MC.CategoryNameAR, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 0 AND MC.CategoryLogoURL IS NOT NULL THEN '''' + REPLACE(MC.CategoryLogoURL, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 0 AND MCP.CategoryID IS NOT NULL THEN CAST(MCP.CategoryID AS VARCHAR(20))
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 0 AND MCP.CategoryNameEN IS NOT NULL THEN '''' + REPLACE(MCP.CategoryNameEN, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 0 AND MCP.CategoryNameAR IS NOT NULL THEN 'N''' + REPLACE(MCP.CategoryNameAR, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 0 AND MCP.CategoryLogoURL IS NOT NULL THEN '''' + REPLACE(MCP.CategoryLogoURL, '''', '''''') + ''''
            ELSE 'NULL'
         END + '

    ,' + CASE
            WHEN N.RN % 3 = 1 AND B.BrandID IS NOT NULL THEN CAST(B.BrandID AS VARCHAR(20))
            WHEN N.RN % 3 = 0 AND M.BrandID IS NOT NULL THEN CAST(M.BrandID AS VARCHAR(20))
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 IN (0,1) AND B.BrandNameEN IS NOT NULL THEN '''' + REPLACE(B.BrandNameEN, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 IN (0,1) AND B.BrandNameAR IS NOT NULL THEN 'N''' + REPLACE(B.BrandNameAR, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 IN (0,1) AND B.BrandLogoURL IS NOT NULL THEN '''' + REPLACE(B.BrandLogoURL, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 IN (0,1) AND B.BrandTypeCode IS NOT NULL THEN '''' + REPLACE(B.BrandTypeCode, '''', '''''') + ''''
            ELSE 'NULL'
         END + '

    ,' + CASE
            WHEN N.RN % 3 = 1 AND B.CategoryID IS NOT NULL THEN CAST(B.CategoryID AS VARCHAR(20))
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 1 AND BC.CategoryNameEN IS NOT NULL THEN '''' + REPLACE(BC.CategoryNameEN, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 1 AND BC.CategoryNameAR IS NOT NULL THEN 'N''' + REPLACE(BC.CategoryNameAR, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 1 AND BC.CategoryLogoURL IS NOT NULL THEN '''' + REPLACE(BC.CategoryLogoURL, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 1 AND BCP.CategoryID IS NOT NULL THEN CAST(BCP.CategoryID AS VARCHAR(20))
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 1 AND BCP.CategoryNameEN IS NOT NULL THEN '''' + REPLACE(BCP.CategoryNameEN, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 1 AND BCP.CategoryNameAR IS NOT NULL THEN 'N''' + REPLACE(BCP.CategoryNameAR, '''', '''''') + ''''
            ELSE 'NULL'
         END + '
    ,' + CASE
            WHEN N.RN % 3 = 1 AND BCP.CategoryLogoURL IS NOT NULL THEN '''' + REPLACE(BCP.CategoryLogoURL, '''', '''''') + ''''
            ELSE 'NULL'
         END + '

    ,N''' + REPLACE(LEFT(ISNULL(M.MerchantNameEN, 'Test Merchant') + ' ' + CAST(N.RN AS VARCHAR(20)), 1024), '''', '''''') + '''
    ,N''' + REPLACE(LEFT(ISNULL(M.MerchantNameAR, N'تاجر تجريبي') + N' ' + CAST(N.RN AS NVARCHAR(20)), 1024), '''', '''''') + '''
    ,' + CASE WHEN B.BrandNameEN IS NULL THEN 'NULL' ELSE 'N''' + REPLACE(LEFT(B.BrandNameEN, 1024), '''', '''''') + '''' END + '
    ,' + CASE WHEN B.BrandNameAR IS NULL THEN 'NULL' ELSE 'N''' + REPLACE(LEFT(B.BrandNameAR, 1024), '''', '''''') + '''' END + '
    ,N''' + REPLACE(LEFT(COALESCE(B.BrandNameEN, M.MerchantNameEN, 'Test Merchant') + ' ' + CAST(N.RN AS VARCHAR(20)), 1024), '''', '''''') + '''
    ,N''' + REPLACE(LEFT(COALESCE(B.BrandNameAR, M.MerchantNameAR, N'تاجر تجريبي') + N' ' + CAST(N.RN AS NVARCHAR(20)), 1024), '''', '''''') + '''
    ,SYSTIMESTAMP
    ,SYSTIMESTAMP
);

'
FROM N
INNER JOIN M
    ON M.BaseRN = ((N.RN - 1) % M.BaseCount) + 1
LEFT JOIN B
    ON B.BrandRN = ((N.RN - 1) % NULLIF(B.BrandCount, 0)) + 1
LEFT JOIN InMem.Category MC
    ON MC.CategoryID = M.CategoryID
LEFT JOIN InMem.Category MCP
    ON MCP.CategoryID = MC.ParentCategoryID
LEFT JOIN InMem.Category BC
    ON BC.CategoryID = B.CategoryID
LEFT JOIN InMem.Category BCP
    ON BCP.CategoryID = BC.ParentCategoryID
ORDER BY N.RN;
