declare @tags varchar(5000) = 'Orange,Apple,Mango';
--select SUBSTRING( @tags, 0, charindex(',',@tags)),  SUBSTRING( @tags, charindex(',',@tags), charindex(',',@tags))
declare @query nVARCHAR(MAX) = 'SELECT '
declare @i int = 0
WHIlE(charindex(',',@tags)>1)
Begin
SET @i = @i + 1;
SET @query =  @query + 'SUBSTRING(''' + @tags + ''', 0, charindex('','',''' + @tags + ''')) COL' + Cast(@i as varchar(10)) + ','
SET @tags = RIGHT(@tags, LEN(@tags) - charindex(',',@tags))

--Select @tags

end
SET @query =  @query + '''' + @tags + '''COL' + Cast(@i + 1 as varchar(10)) ;

exec sp_executesql @query 
