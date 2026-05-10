INSERT /*+ APPEND */
INTO dinarWise_OLTP.MerchantOtherBrand
(
     MerchantOtherID
    ,MerchantOtherNameEN
    ,MerchantOtherNameAR
    ,SubMerchantOtherNameEN
    ,SubMerchantOtherNameAR

    ,MerchantOtherCategoryID
    ,MerchantOtherCategoryNameEN
    ,MerchantOtherCategoryNameAR
    ,MerchantOtherCategoryLogoURL

    ,MerchantOtherParentCategoryID
    ,MerchantOtherParentCategoryNameEN
    ,MerchantOtherParentCategoryNameAR
    ,MerchantOtherParentCategoryLogoURL

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
SELECT
     S.SourceMerchantOtherID + (S.CopyNo * 1000000) AS MerchantOtherID
    ,S.MerchantOtherNameEN
    ,S.MerchantOtherNameAR
    ,S.SubMerchantOtherNameEN
    ,S.SubMerchantOtherNameAR

    ,S.MerchantOtherCategoryID
    ,S.MerchantOtherCategoryNameEN
    ,S.MerchantOtherCategoryNameAR
    ,S.MerchantOtherCategoryLogoURL

    ,S.MerchantOtherParentCategoryID
    ,S.MerchantOtherParentCategoryNameEN
    ,S.MerchantOtherParentCategoryNameAR
    ,S.MerchantOtherParentCategoryLogoURL

    ,S.BrandID
    ,S.BrandNameEN
    ,S.BrandNameAR
    ,S.BrandLogoURL
    ,S.BrandTypeCode

    ,S.BrandCategoryID
    ,S.BrandCategoryNameEN
    ,S.BrandCategoryNameAR
    ,S.BrandCategoryLogoURL

    ,S.BrandParentCategoryID
    ,S.BrandParentCategoryNameEN
    ,S.BrandParentCategoryNameAR
    ,S.BrandParentCategoryLogoURL

    ,S.DisplayMerchantNameEN
    ,S.DisplayMerchantNameAR
    ,S.DisplayBrandNameEN
    ,S.DisplayBrandNameAR
    ,S.DisplayNameEN
    ,S.DisplayNameAR

    ,SYSTIMESTAMP
    ,SYSTIMESTAMP
FROM dinarWise_OLTP.STAGE_ONETIME_MERCHANTOTHERBRAND S
WHERE NOT EXISTS
(
    SELECT 1
    FROM dinarWise_OLTP.MerchantOtherBrand T
    WHERE T.MerchantOtherID = S.SourceMerchantOtherID + (S.CopyNo * 1000000)
);

COMMIT;
