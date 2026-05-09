;WITH Multiplier
AS
(
    SELECT 0 AS CopyNo
    UNION ALL SELECT 1
    UNION ALL SELECT 2
    UNION ALL SELECT 3
),
BaseMerchant
AS
(
    SELECT
         M.MerchantID
        ,M.MerchantNameEN
        ,M.MerchantNameAR
        ,M.SubMerchantNameEN
        ,M.SubMerchantNameAR
        ,M.BrandID
        ,M.CategoryID
        ,ROW_NUMBER() OVER (ORDER BY M.MerchantID) AS RN
    FROM InMem.Merchant M
    WHERE M.TennantID = 3
      AND M.IsActive = 'Y'
)
SELECT TOP (1000000)
     1000000 + ROW_NUMBER() OVER (ORDER BY X.CopyNo, BM.MerchantID) AS MerchantID

    ,LEFT(ISNULL(BM.MerchantNameEN, 'Merchant') + ' ' + CAST(X.CopyNo AS VARCHAR(10)), 128) AS MerchantNameEN
    ,LEFT(ISNULL(BM.MerchantNameAR, N'تاجر') + N' ' + CAST(X.CopyNo AS NVARCHAR(10)), 256) AS MerchantNameAR

    ,BM.SubMerchantNameEN
    ,BM.SubMerchantNameAR

    ,CASE WHEN BM.RN % 3 = 0 THEN BM.CategoryID ELSE NULL END AS MerchantCategoryID
    ,CASE WHEN BM.RN % 3 = 1 THEN B.CategoryID  ELSE NULL END AS BrandCategoryID
    ,CASE WHEN BM.RN % 3 = 2 THEN NULL          ELSE BM.BrandID END AS BrandID

    ,SYSDATETIME() AS CreateDateTime
    ,SYSDATETIME() AS UpdateDateTime
FROM BaseMerchant BM
CROSS JOIN Multiplier X
LEFT JOIN InMem.Brand B
    ON B.BrandID = BM.BrandID
   AND B.TennantID = 3
   AND B.IsActive = 'Y'
ORDER BY X.CopyNo, BM.MerchantID;
