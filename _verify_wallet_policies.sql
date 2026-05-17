select policyname, permissive, roles, cmd
from pg_policies
where schemaname = 'public' and tablename = 'wallets'
order by policyname;
