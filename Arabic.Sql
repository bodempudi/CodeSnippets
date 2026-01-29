DECLARE @Text NVARCHAR(200) = N'لديك {0} رسائل جديدة';
DECLARE @Number INT = 5;

SELECT REPLACE(
       @Text,
       '{0}',
       NCHAR(8206) + CAST(@Number AS NVARCHAR(10)) + NCHAR(8206)
);
