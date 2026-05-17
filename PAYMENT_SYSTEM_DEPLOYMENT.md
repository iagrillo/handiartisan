# HandiHub Paystack Escrow + Wallet System
## Deployment Instructions

---

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Database Setup](#database-setup)
3. [Supabase Edge Functions](#supabase-edge-functions)
4. [Paystack Configuration](#paystack-configuration)
5. [Flutter Integration](#flutter-integration)
6. [Testing](#testing)
7. [Going Live](#going-live)

---

## 1. Prerequisites

### Required Accounts
- **Supabase Account**: [https://supabase.com](https://supabase.com)
- **Paystack Account**: [https://paystack.com](https://paystack.com)

### Environment Variables Needed
```
# Supabase (already configured)
SUPABASE_URL=https://awbqkptzknhlvxfboklf.supabase.co
SUPABASE_ANON_KEY=your_anon_key

# Paystack (get from Paystack Dashboard)
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxxxxx  (for TEST mode)
PAYSTACK_SECRET_KEY=sk_live_xxxxxxxxxxxxx  (for LIVE mode)

# Supabase Service Role Key (get from Supabase Settings > API)
SUPABASE_SERVICE_ROLE_KEY=eyJxxxxxxxxxxxxx
```

---

## 2. Database Setup

### Step 1: Run the Payment Schema
1. Open **Supabase Dashboard** → **SQL Editor**
2. Copy contents from [`payment_schema.sql`](./payment_schema.sql)
3. Run the SQL to create:
   - `jobs` table
   - `wallets` table
   - `transactions` table
   - Auto-create wallet trigger
   - Real-time publications
   - RLS policies

### Step 2: Verify Tables Created
Run this to check:
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';
```

---

## 3. Supabase Edge Functions

### Deploy Edge Functions
Run these commands in your terminal:

```bash
# Install Supabase CLI if not installed
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
cd handiartisan
supabase link --project-ref awbqkptzknhlvxfboklf

# Deploy all Edge Functions
supabase functions deploy initializeTransaction
supabase functions deploy webhookHandler
supabase functions deploy transferPayout
supabase functions deploy refundTransaction
supabase functions deploy createSubaccount
```

### Configure Environment Variables
1. Go to **Supabase Dashboard** → **Edge Functions** → **Settings**
2. Add these secrets:
   - `PAYSTACK_SECRET_KEY`: Your Paystack secret key
   - `SUPABASE_SERVICE_ROLE_KEY`: Your service role key

### Configure Webhook URL
1. Go to **Paystack Dashboard** → **Settings** → **Webhooks**
2. Add this URL:
   ```
   https://awbqkptzknhlvxfboklf.supabase.co/functions/v1/webhookHandler
   ```
3. Select **"charge.success"** event

---

## 4. Paystack Configuration

### Test Mode Setup
1. Login to **Paystack Dashboard**
2. Go to **Settings** → **API Keys & Webhooks**
3. Copy your **Test Secret Key**
4. Add to Supabase Edge Function secrets

### Live Mode Setup
1. Request **Live API Keys** from Paystack (requires business verification)
2. Copy your **Live Secret Key**
3. Update Supabase Edge Function secrets
4. Update webhook URL for live

### Bank Codes (for subaccounts)
The system supports these Nigerian banks:
- Access Bank (044)
- Citibank (023)
- Diamond Bank (063)
- Ecobank (050)
- Fidelity Bank (070)
- First Bank (011)
- GTBank (058)
- Heritage Bank (030)
- Keystone Bank (082)
- Polaris Bank (076)
- Providus Bank (101)
- Stanbic IBTC (221)
- Standard Chartered (068)
- Sterling Bank (232)
- Union Bank (032)
- UBA (033)
- Unity Bank (215)
- Wema Bank (035)
- Zenith Bank (057)

---

## 5. Flutter Integration

### Add Dependencies
Make sure `pubspec.yaml` includes:
```yaml
dependencies:
  supabase_flutter: ^2.12.0
  http: ^1.0.0
  url_launcher: ^6.2.5
```

### Import Payment Service
In your Dart files:
```dart
import '../services/payment_service.dart';
import '../features/payment/outcall_book_button.dart';
```

### Using Outcall Book Button
```dart
// In artisan profile page
OutcallBookButton(
  artisan: artisan,
  customerEmail: 'customer@email.com',
  customerName: 'John Doe',
  customerPhone: '08012345678',
  onPaymentSuccess: () {
    // Navigate to success page or show dialog
  },
  onPaymentFailure: () {
    // Show error message
  },
)
```

### Using Wallet Page
The wallet page is already configured at `/wallet` route:
```dart
// In main.dart
'/wallet': (context) => const WalletPage(),
```

---

## 6. Testing

### Test Payment Flow

1. **Initialize Payment** (Flutter)
   - Click "Book Outcall - ₦3,000"
   - Enter customer details
   - Click "Pay & Book"

2. **Paystack Checkout** (Test Mode)
   - Use test card: `5060666666666666666`
   - Any future date
   - Any CVV: `123`
   - OTP: `123456`

3. **Webhook Processing**
   - Payment success triggers `charge.success` webhook
   - Job status changes to `paid`
   - Artisan pending balance increases by ₦2,000
   - Transaction recorded

4. **Complete Job** (Flutter Wallet Page)
   - Go to Wallet page
   - Find pending job
   - Click "Mark Complete"
   - Funds transferred (minus ₦1,000 commission)

### Test Scenarios

| Scenario | Action | Expected Result |
|----------|--------|-----------------|
| Successful payment | Use test card | Job = PAID, Wallet +₦2,000 |
| Complete job | Click "Mark Complete" | Transfer ₦2,000, deduct commission |
| Cancel job | Click "Cancel" | Refund ₦3,000 to customer |
| Failed job | Click "Fail" | Refund ₦3,000 to customer |
| Duplicate webhook | Re-send webhook | Idempotent - no duplicate processing |

---

## 7. Going Live

### Pre-Launch Checklist
- [ ] Test payment flow with test cards
- [ ] Verify webhook processing
- [ ] Test real-time wallet updates
- [ ] Add bank details for test artisan
- [ ] Test complete job flow with payouts
- [ ] Test refund flow

### Switch to Live Mode
1. **Paystack**:
   - Verify business account
   - Get live API keys
   - Update webhook URL to live

2. **Supabase**:
   - Update `PAYSTACK_SECRET_KEY` to live key
   - Redeploy Edge Functions if needed

3. **Flutter App**:
   - No code changes needed (API handles both modes)
   - Just update environment in production

---

## 📊 Payment Flow Summary

```
Customer Pays ₦3,000
       │
       ▼
┌──────────────────┐
│  Paystack API    │
│ (Charge Card)    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐     ┌──────────────────┐
│ Webhook Handler  │────▶│ Job = PAID       │
│ (charge.success) │     │ +₦2,000 escrow   │
└──────────────────┘     └──────────────────┘
                                  │
                                  ▼
                        ┌──────────────────┐
                        │ Artisan Wallet   │
                        │ pending_balance  │
                        └──────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    ▼                           ▼
            ┌───────────────┐           ┌───────────────┐
            │ Job Complete  │           │ Job Failed/   │
            │ Transfer ₦2k  │           │ Cancelled     │
            │ -₦1k commission           │ Refund ₦3k   │
            └───────────────┘           └───────────────┘
```

---

## 🔧 Troubleshooting

### Common Issues

1. **Webhook not firing**
   - Check Paystack webhook URL is correct
   - Verify signature verification in webhook handler
   - Check Supabase function logs

2. **Payment fails**
   - Verify Paystack keys are correct
   - Check API call is from allowed IP
   - Verify transaction initialization

3. **Wallet not updating**
   - Check RLS policies allow writes
   - Verify wallet row exists for artisan
   - Check Supabase function logs

4. **Transfer fails**
   - Verify artisan bank details are set
   - Check Paystack account has sufficient balance
   - Verify subaccount is created

### View Logs
```bash
# Supabase Edge Function logs
supabase functions logs webhookHandler
supabase functions logs initializeTransaction
```

---

## 📝 API Reference

### Edge Functions

| Function | Purpose | Endpoint |
|----------|---------|----------|
| initializeTransaction | Create payment | `/initializeTransaction` |
| webhookHandler | Process Paystack webhooks | `/webhookHandler` |
| transferPayout | Transfer to artisan / Refund | `/transferPayout` |
| refundTransaction | Full refund only | `/refundTransaction` |
| createSubaccount | Create artisan bank account | `/createSubaccount` |

### Database Tables

| Table | Description |
|-------|-------------|
| jobs | Job bookings and status |
| wallets | Artisan wallet balances |
| transactions | All payment transactions |

---

## ✅ Production Checklist

- [ ] SQL schema deployed
- [ ] All 5 Edge Functions deployed
- [ ] Environment variables configured
- [ ] Paystack webhook configured
- [ ] Test payment flow works
- [ ] Real-time updates working
- [ ] Wallet page displays correctly
- [ ] Outcall book button functional
- [ ] Production API keys configured
- [ ] Live testing completed
