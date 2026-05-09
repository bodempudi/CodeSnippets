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
     ' + CAST(SourceMerchantID + (CopyNo * 1000000) AS VARCHAR(50)) + '

    ,N''' + REPLACE(ISNULL(MerchantNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(MerchantNameAR,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(SubMerchantNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(SubMerchantNameAR,''),'''','''''') + '''

    ,' + ISNULL(CAST(MerchantCategoryID AS VARCHAR(50)),'NULL') + '
    ,N''' + REPLACE(ISNULL(MerchantCategoryNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(MerchantCategoryNameAR,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(MerchantCategoryLogoURL,''),'''','''''') + '''

    ,' + ISNULL(CAST(MerchantParentCategoryID AS VARCHAR(50)),'NULL') + '
    ,N''' + REPLACE(ISNULL(MerchantParentCategoryNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(MerchantParentCategoryNameAR,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(MerchantParentCategoryLogoURL,''),'''','''''') + '''

    ,' + ISNULL(CAST(BrandID AS VARCHAR(50)),'NULL') + '
    ,N''' + REPLACE(ISNULL(BrandNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(BrandNameAR,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(BrandLogoURL,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(BrandTypeCode,''),'''','''''') + '''

    ,' + ISNULL(CAST(BrandCategoryID AS VARCHAR(50)),'NULL') + '
    ,N''' + REPLACE(ISNULL(BrandCategoryNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(BrandCategoryNameAR,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(BrandCategoryLogoURL,''),'''','''''') + '''

    ,' + ISNULL(CAST(BrandParentCategoryID AS VARCHAR(50)),'NULL') + '
    ,N''' + REPLACE(ISNULL(BrandParentCategoryNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(BrandParentCategoryNameAR,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(BrandParentCategoryLogoURL,''),'''','''''') + '''

    ,N''' + REPLACE(ISNULL(DisplayMerchantNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(DisplayMerchantNameAR,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(DisplayBrandNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(DisplayBrandNameAR,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(DisplayNameEN,''),'''','''''') + '''
    ,N''' + REPLACE(ISNULL(DisplayNameAR,''),'''','''''') + '''

    ,SYSTIMESTAMP
    ,SYSTIMESTAMP
);'
FROM dbo.Export_MerchantBrand_Prepared
WHERE CopyNo = 0;
