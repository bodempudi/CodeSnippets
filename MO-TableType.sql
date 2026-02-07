--You can not alter memory optimized user defined table type.
--Simple datatypes, not even nvarchar(max) is supported.

--When we are creating InMem tables, schema = SCHEMA_AND_DATA
--ask this question, when everything is stored in memory, why memory optimized file group is required?
CREATE TABLE dbo.Merchant
(
  MerchantID IDENTITY BIGINT,
  MerchantNumber VARCHAR(128),
  MerchantName VARCHAR(512),
  CategoryID BIGINT,
  CREATEDateTime DATETIME,
  CreateUserID VARCHAR(20),
  UpdateDatetime DATETIME,
  UpdateUserID VARCHAR(20)
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA);
