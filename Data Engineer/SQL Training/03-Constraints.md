## Constraints in SQL Server

Constraints in SQL Server defines several rules on your table. Rules are nothing but your business specifi rules.

Constraints brings the data integrity or domain integrity to your database. It means that once you define constraints on your table as per your business, you are assured that the data in the table is
valid as per business.

Constraints can be defined at either column level or at table level.

** Primary Key **- this is going to be used to uniquely identify each record in a table, it wont allow nulls and duplicates. The correct word about primary key is entity integrity. Entity is nothing but a table, so primary key brings the data integrity in a particular table. It means no duplicates in a column and column always will have a value in it. Candidate key is nothing but a primary key, primary key can be 
defined on more than one column. When we define primary key on more than one column, we have to do this at table level.

Below is the example code:
--Basic Table Creation Syntax
CREATE TABLE dbo.SampleApplicationPrimaryKeyAtTableLevel(
ApplicationID INT IDENTITY ,
ApplicationName VARCHAR(50),
AddedDate DATETIME,
constraint SampleApplicationPrimaryKeyAtTableLevel_ApplicationID_ApplicationName PRIMARY KEY(ApplicationId,ApplicationName)
);

Please take a look at the naming convention that i have followed. Naming conventions are very important when you write your code. Every team will have some naming coventions, please follow the same.


NOT NULL - it will not allow null values, which means column always should have a value.

Unique - values in this column should not be duplicate and a single null value is allowed. More than one null value is not allowed.

** FOREIGN KEY **- This constraint is going to be used define parent and child relationships between tables in database. Technically this is used to maintain referrential integrity in database. You can do on delete cascade and on update cascade as well. on delete cascade is nothing but what should happen in case of parent value is changed is deleted, whether child values also should changed or not can also be defined.

Ex: Orders and OrderDetails tables are the best example for defining Primary Key and Foreign Key relationships. Without order there will not be any order details, in such cases the referential integrity is maintained between Orders and OrderDetails using Primary Key and Foreign Key Constraints.

DEFAULT - This constraint is going to be used to have default values for a column.

CHECK - This contraint is going to be used to make sure the values in the column satisfies a particular condition.

All the syntaxes can be find in internet just make understand of these concepts.

## Normalization
Normalization is a formal mathematical process to guarantee that each entity will be represented by a single relation. In a normalized database, you avoid anomalies during data modification and keep redundancy to a minimum without sacrificing completeness.
