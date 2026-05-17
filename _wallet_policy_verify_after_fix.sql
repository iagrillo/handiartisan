select policyname, cmd, roles, qual
from pg_policies
where schemaname='public' and tablename='wallets'
order by policyname;
