# Payment Configuration Script
# Copy this file, fill in your credentials, and run the commands

# ============================================
# M-PESA CONFIGURATION (SANDBOX)
# ============================================
# Get these from: https://developer.safaricom.co.ke/

firebase functions:config:set mpesa.consumer_key="REPLACE_WITH_YOUR_CONSUMER_KEY"
firebase functions:config:set mpesa.consumer_secret="REPLACE_WITH_YOUR_CONSUMER_SECRET"
firebase functions:config:set mpesa.shortcode="174379"
firebase functions:config:set mpesa.passkey="REPLACE_WITH_SANDBOX_PASSKEY"
firebase functions:config:set mpesa.callback_url="https://us-central1-qejani-a4ed6.cloudfunctions.net/mpesaCallback"

# ============================================
# STRIPE CONFIGURATION (TEST MODE)
# ============================================
# Get these from: https://dashboard.stripe.com/test/apikeys

firebase functions:config:set stripe.secret_key="sk_test_REPLACE_WITH_YOUR_SECRET_KEY"
firebase functions:config:set stripe.webhook_secret="whsec_REPLACE_WITH_YOUR_WEBHOOK_SECRET"

# ============================================
# VERIFY CONFIGURATION
# ============================================
firebase functions:config:get

# ============================================
# DEPLOY FUNCTIONS
# ============================================
firebase deploy --only functions

# ============================================
# NOTES
# ============================================
# 1. Replace all "REPLACE_WITH_YOUR_..." placeholders with actual values
# 2. For M-Pesa sandbox passkey, check Daraja documentation
# 3. For Stripe webhook secret, create webhook endpoint first
# 4. Run these commands from your project's functions directory
