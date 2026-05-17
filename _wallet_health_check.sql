select count(*) as wallets_count,
       sum(case when coalesce(available_balance,0) > 0 then 1 else 0 end) as wallets_with_available,
       sum(case when coalesce(pending_balance,0) > 0 then 1 else 0 end) as wallets_with_pending
from wallets;

select policyname, cmd, roles, qual, with_check
from pg_policies
where schemaname='public' and tablename='wallets'
order by policyname;
