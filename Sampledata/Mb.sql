;WITH Multiplier
AS
(
    SELECT 0 AS CopyNo
    UNION ALL
    SELECT 1
    UNION ALL
    SELECT 2
    UNION ALL
    SELECT 3
),
BaseMerchant
AS
(
    SELECT
         M.*
        ,ROW_NUMBER() OVER (ORDER BY M.MerchantID) AS RN
    FROM InMem.Merchant M
    WHERE M.TennantID = 3
      AND M.IsActive = 'Y'
)
SELECT TOP (1000000)

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
          ' + CAST(1000000 + ROW_NUMBER() OVER (ORDER BY BM.CopyNo, BM.MerchantID) AS VARCHAR(20)) + '

         ,''' + REPLACE(LEFT(ISNULL(BM.MerchantNameEN, 'Test Merchant') + ' ' + CAST(BM.CopyNo AS VARCHAR(10)), 128), '''', '''''') + '''

         ,N''' + REPLACE(LEFT(ISNULL(BM.MerchantNameAR, N'تاجر تجريبي'), 256), '''', '''''') + '''

         ,' + CASE
                 WHEN BM.SubMerchantNameEN IS NULL THEN 'NULL'
                 ELSE '''' + REPLACE(LEFT(BM.SubMerchantNameEN,128),'''','''''') + ''''
              END + '

         ,' + CASE
                 WHEN BM.SubMerchantNameAR IS NULL THEN 'NULL'
                 ELSE 'N''' + REPLACE(LEFT(BM.SubMerchantNameAR,256),'''','''''') + ''''
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 0
                      AND MC.CategoryID IS NOT NULL
                 THEN CAST(MC.CategoryID AS VARCHAR(20))
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 0
                      AND MC.CategoryNameEN IS NOT NULL
                 THEN '''' + REPLACE(MC.CategoryNameEN,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 0
                      AND MC.CategoryNameAR IS NOT NULL
                 THEN 'N''' + REPLACE(MC.CategoryNameAR,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 0
                      AND MC.CategoryLogoURL IS NOT NULL
                 THEN '''' + REPLACE(MC.CategoryLogoURL,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 0
                      AND MCP.CategoryID IS NOT NULL
                 THEN CAST(MCP.CategoryID AS VARCHAR(20))
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 0
                      AND MCP.CategoryNameEN IS NOT NULL
                 THEN '''' + REPLACE(MCP.CategoryNameEN,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 0
                      AND MCP.CategoryNameAR IS NOT NULL
                 THEN 'N''' + REPLACE(MCP.CategoryNameAR,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 0
                      AND MCP.CategoryLogoURL IS NOT NULL
                 THEN '''' + REPLACE(MCP.CategoryLogoURL,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN B.BrandID IS NULL THEN 'NULL'
                 ELSE CAST(B.BrandID AS VARCHAR(20))
              END + '

         ,' + CASE
                 WHEN B.BrandNameEN IS NULL THEN 'NULL'
                 ELSE '''' + REPLACE(B.BrandNameEN,'''','''''') + ''''
              END + '

         ,' + CASE
                 WHEN B.BrandNameAR IS NULL THEN 'NULL'
                 ELSE 'N''' + REPLACE(B.BrandNameAR,'''','''''') + ''''
              END + '

         ,' + CASE
                 WHEN B.BrandLogoURL IS NULL THEN 'NULL'
                 ELSE '''' + REPLACE(B.BrandLogoURL,'''','''''') + ''''
              END + '

         ,' + CASE
                 WHEN B.BrandTypeCode IS NULL THEN 'NULL'
                 ELSE '''' + REPLACE(B.BrandTypeCode,'''','''''') + ''''
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 1
                      AND BC.CategoryID IS NOT NULL
                 THEN CAST(BC.CategoryID AS VARCHAR(20))
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 1
                      AND BC.CategoryNameEN IS NOT NULL
                 THEN '''' + REPLACE(BC.CategoryNameEN,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 1
                      AND BC.CategoryNameAR IS NOT NULL
                 THEN 'N''' + REPLACE(BC.CategoryNameAR,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 1
                      AND BC.CategoryLogoURL IS NOT NULL
                 THEN '''' + REPLACE(BC.CategoryLogoURL,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 1
                      AND BCP.CategoryID IS NOT NULL
                 THEN CAST(BCP.CategoryID AS VARCHAR(20))
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 1
                      AND BCP.CategoryNameEN IS NOT NULL
                 THEN '''' + REPLACE(BCP.CategoryNameEN,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 1
                      AND BCP.CategoryNameAR IS NOT NULL
                 THEN 'N''' + REPLACE(BCP.CategoryNameAR,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,' + CASE
                 WHEN BM.RN % 3 = 1
                      AND BCP.CategoryLogoURL IS NOT NULL
                 THEN '''' + REPLACE(BCP.CategoryLogoURL,'''','''''') + ''''
                 ELSE 'NULL'
              END + '

         ,N''' + REPLACE(LEFT(BM.MerchantNameEN,1024),'''','''''') + '''

         ,N''' + REPLACE(LEFT(BM.MerchantNameAR,1024),'''','''''') + '''

         ,' + CASE
                 WHEN B.BrandNameEN IS NULL THEN 'NULL'
                 ELSE 'N''' + REPLACE(LEFT(B.BrandNameEN,1024),'''','''''') + ''''
              END + '

         ,' + CASE
                 WHEN B.BrandNameAR IS NULL THEN 'NULL'
                 ELSE 'N''' + REPLACE(LEFT(B.BrandNameAR,1024),'''','''''') + ''''
              END + '

         ,N''' + REPLACE(LEFT(COALESCE(B.BrandNameEN,BM.MerchantNameEN),1024),'''','''''') + '''

         ,N''' + REPLACE(LEFT(COALESCE(B.BrandNameAR,BM.MerchantNameAR),1024),'''','''''') + '''

         ,SYSTIMESTAMP
         ,SYSTIMESTAMP
     );

'
FROM BaseMerchant BM
CROSS JOIN Multiplier
LEFT JOIN InMem.Brand B
    ON B.BrandID = BM.BrandID
LEFT JOIN InMem.Category MC
    ON MC.CategoryID = BM.CategoryID
LEFT JOIN InMem.Category MCP
    ON MCP.CategoryID = MC.ParentCategoryID
LEFT JOIN InMem.Category BC
    ON BC.CategoryID = B.CategoryID
LEFT JOIN InMem.Category BCP
    ON BCP.CategoryID = BC.ParentCategoryID
ORDER BY BM.CopyNo, BM.MerchantID;
