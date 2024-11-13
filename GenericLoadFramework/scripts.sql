drop table if exists #main;

select *
into #main
from
(
	select [name] = 'A',IsActive = 'Y'
	union all select 'B','Y'
	union all select 'C','Y'
	--union all select 'D','Y'
) a

drop table if exists #Sub;

select *
into #Sub
from
(
	select [name] = 'B',IsActive = 'Y'
	union all select 'C','Y'
	union all select 'D','Y'
) aa

select name = isnull(a.name,b.name),IsActive = case when b.IsActive is null then 'N'
when a.IsActive is null then 'Y' else a.IsActive end
from #main a
full join #Sub b on a.name = b.name

--select * from #main
