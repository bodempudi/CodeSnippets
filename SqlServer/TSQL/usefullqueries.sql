--findout where specific word is used across the database
SELECT DISTINCT
       o.name AS Object_Name,
       o.type_desc
  FROM sys.sql_modules m
       INNER JOIN
       sys.objects o
         ON m.object_id = o.object_id
 WHERE m.definition Like '%market_abbr%';
