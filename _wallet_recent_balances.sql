select artisan_id, available_balance, pending_balance, total_earned, updated_at
from wallets
order by updated_at desc nulls last
limit 10;
