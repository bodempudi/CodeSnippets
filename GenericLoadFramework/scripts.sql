
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

update a
set a.IsActive = ISNULL(b.IsActive,'N')
,a.IsActive = ISNULL(a.IsActive,'Y')
from #main a
full join #Sub b on a.name=b.name
