# HandiHub Production Launch Checklist

## 1. Database & Data
- [ ] All wallet balances zeroed (`wallets` table)
- [ ] All jobs reset to `pending` and amounts zeroed
- [ ] Test/legacy/demo data removed or reset as needed

## 2. Security
- [ ] RLS enabled on all sensitive tables (`wallets`, `jobs`, `transactions`, etc.)
- [ ] Only `service_role` can update/insert wallet and job balances
- [ ] No public/anon access to sensitive tables
- [ ] Withdrawal/transfer logic enforced server-side

## 3. Environment Variables
- [ ] Paystack keys set to **LIVE** (`sk_live_...`, `pk_live_...`)
- [ ] Supabase keys set to production values
- [ ] All environment variables set in Supabase, Vercel, and Edge Functions

## 4. Code & Deployment
- [ ] No test keys or debug endpoints in code
- [ ] All code and edge functions redeployed after env changes
- [ ] All legacy/unsafe scripts removed or blocked

## 5. Payments & Webhooks
- [ ] Paystack webhook endpoint deployed and tested
- [ ] Webhook logs monitored for errors
- [ ] Live payment tested end-to-end (from Paystack to wallet)

## 6. Bank Verification & Withdrawals
- [ ] Bank verification (Paystack) tested and working
- [ ] Withdrawal tested with real bank account

## 7. Monitoring & Support
- [ ] Error logging and alerting enabled (Supabase, Vercel, etc.)
- [ ] Support contact or escalation plan in place

## 8. Backup & Rollback
- [ ] Database backup taken before launch
- [ ] Rollback plan ready in case of critical issues

## 9. Final User Acceptance Test
- [ ] Test as a real user: register, fund wallet, book job, withdraw, etc.
- [ ] Confirm all balances and flows are correct

---
**If all boxes are checked, you are ready to go live!**
