# Wallet SQL / RLS Audit (Production Readiness)

Date: 2026-04-03

## Canonical production script

- ✅ `fix_wallet_trigger.sql`
  - Strict wallet RLS
  - No public/anon wallet reads
  - No direct client wallet writes
  - Trigger hardening (`SECURITY DEFINER`, `search_path`)
  - Idempotent unique constraint handling

## Quarantined unsafe legacy scripts

These now include a guard block that raises an exception to prevent accidental execution in production:

- ❌ `fix_wallet_policies.sql`
  - Created wallet policies with `USING (true)` / `WITH CHECK (true)`
- ❌ `fix_wallet_complete.sql`
  - Granted broad authenticated wallet access (`FOR ALL ... USING (true)`)
- ❌ `fix_wallets_rls.sql`
  - Allowed direct user wallet updates

## Additional files to treat as migration-history only

These scripts may still contain legacy assumptions and should not be blindly re-run in production:

- `secure_rls_policies.sql`
- `cleanup_weak_policies.sql`
- `deploy_database.sql`
- `fix_rls_complete.sql`

## Recommended operational rule

Only execute wallet policy migrations from:

1. `fix_wallet_trigger.sql` (current baseline)
2. Explicitly reviewed follow-up migrations created after this audit

Avoid running older wallet scripts ad hoc in Supabase SQL Editor.
