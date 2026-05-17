select job_reference, status, estimate_status, amount_paid, estimate_materials_cost, estimate_labor_cost, estimate_total, updated_at
from jobs
order by updated_at desc nulls last
limit 20;
