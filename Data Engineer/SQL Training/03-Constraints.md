## Constraints in SQL Server

Constraints in SQL Server defines several rules on your table. Rules are nothing but your business specifi rules.

Constraints brings the data integrity or domain integrity to your database. It means that once you define constraints on your table as per your business, you are assured that the data in the table is
valid as per business.

Constraints can be defined at either column level or at table level.

Primary Key - this is going to be used to uniquely identify each record in a table, it wont allow nulls and duplicates

NOT NULL - it will not allow null values, which means column always should have a value.

Unique - values in this column should not be duplicate and a single null value is allowed. More than one null value is not allowed.

FOREIGN KEY - This constraint is going to be used define parent and child relationships between tables in database. Technically this is used to maintain referrential integrity in database. You can do on delete cascade and on update cascade as well. on delete cascade is nothing but what should happen in case of parent value is changed is deleted, whether child values also should changed or not can also be defined.

DEFAULT - This constraint is going to be used to have default values for a column.

CHECK - This contraint is going to be used to make sure the values in the column satisfies a particular condition.

All the syntaxes can be find in internet just make understand of these concepts.
