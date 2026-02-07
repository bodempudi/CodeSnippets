--You can not alter memory optimized user defined table type.
--Simple datatypes, not even nvarchar(max) is supported.

--When we are creating InMem tables, schema = SCHEMA_AND_DATA
--ask this question, when everything is stored in memory, why memory optimized file group is required?
/*

1. Take same system categorization procedure with transaction elements as an input.
2. Get transaction category procedure with MO table type and normal table type
3. Take only local mercant scenario
4. Heal merchant and get transaction category
5. return response to system procedure.
r
*/

CREATE TABLE dbo.Merchant
(
    MerchantID       BIGINT IDENTITY(1,1) NOT NULL,
    MerchantNumber   VARCHAR(128) NOT NULL,
    MerchantName     VARCHAR(512) NOT NULL,
    CategoryID       BIGINT NOT NULL,
    IsActive         CHAR(1) NOT NULL DEFAULT 'Y', -- Y = Active, N = Inactive
    CreateDateTime   DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    CreateUserID     VARCHAR(20) NOT NULL,
    UpdateDateTime   DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdateUserID     VARCHAR(20) NOT NULL,

    CONSTRAINT PK_Merchant PRIMARY KEY NONCLUSTERED (MerchantID)
)
WITH
(
    MEMORY_OPTIMIZED = ON,
    DURABILITY = SCHEMA_AND_DATA
);
GO
