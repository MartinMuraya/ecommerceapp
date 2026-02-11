const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const stripe = require("stripe")(functions.config().stripe.secret_key);

admin.initializeApp();

// M-Pesa Configuration (should be set via functions:config:set mpesa.consumer_key=... etc.)
const mpesaConfig = functions.config().mpesa;

// Helper to get M-Pesa Access Token
async function getMpesaAccessToken() {
  const consumerKey = mpesaConfig.consumer_key;
  const consumerSecret = mpesaConfig.consumer_secret;
  const url = "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials";
  const auth = "Basic " + Buffer.from(consumerKey + ":" + consumerSecret).toString("base64");

  try {
    const response = await axios.get(url, {
      headers: {
        Authorization: auth,
      },
    });
    return response.data.access_token;
  } catch (error) {
    console.error("Error getting M-Pesa access token:", error);
    throw new functions.https.HttpsError("internal", "Failed to authenticate with M-Pesa");
  }
}

exports.initiateMpesaPayment = functions.https.onCall(async (data, context) => {
  // 1. Validate Input
  if (!data.phoneNumber || !data.amount || !data.orderId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields: phoneNumber, amount, or orderId");
  }

  const { phoneNumber, amount, orderId } = data;

  // Clean phone number (ensure 254 format)
  const formattedPhone = phoneNumber.startsWith("0")
    ? "254" + phoneNumber.substring(1)
    : (phoneNumber.startsWith("+") ? phoneNumber.substring(1) : phoneNumber);

  // 2. Get Access Token
  const accessToken = await getMpesaAccessToken();

  // 3. Prepare STK Push Payload
  const timestamp = new Date().toISOString().replace(/[^0-9]/g, "").slice(0, 14);
  const passkey = mpesaConfig.passkey;
  const shortcode = mpesaConfig.shortcode;
  const password = Buffer.from(shortcode + passkey + timestamp).toString("base64");

  const callbackUrl = mpesaConfig.callback_url || `https://us-central1-${process.env.GCLOUD_PROJECT}.cloudfunctions.net/mpesaCallback`;

  const payload = {
    BusinessShortCode: shortcode,
    Password: password,
    Timestamp: timestamp,
    TransactionType: "CustomerPayBillOnline",
    Amount: Math.ceil(amount), // M-Pesa requires integer amount
    PartyA: formattedPhone,
    PartyB: shortcode,
    PhoneNumber: formattedPhone,
    CallBackURL: callbackUrl,
    AccountReference: orderId,
    TransactionDesc: `Payment for Order ${orderId}`,
  };

  try {
    const response = await axios.post(
      "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest",
      payload,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      }
    );

    // Store payment attempt in Firestore
    await admin.firestore().collection("payments").add({
      orderId: orderId,
      userId: context.auth ? context.auth.uid : "anonymous",
      amount: amount,
      provider: "mpesa",
      phoneNumber: formattedPhone,
      status: "pending",
      merchantRequestId: response.data.MerchantRequestID,
      checkoutRequestId: response.data.CheckoutRequestID,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: "STK Push initiated", data: response.data };
  } catch (error) {
    console.error("M-Pesa STK Push Error:", error.response ? error.response.data : error.message);
    throw new functions.https.HttpsError("internal", "Failed to initiate M-Pesa payment");
  }
});

exports.createStripePaymentIntent = functions.https.onCall(async (data, context) => {
  if (!data.amount || !data.currency) {
    throw new functions.https.HttpsError("invalid-argument", "Missing amount or currency");
  }

  const { amount, currency } = data;

  // Stripe amount is in smallest currency unit (e.g., cents)
  // For KES, it is a zero-decimal currency in some contexts but usually handled as minor units if supported, 
  // currently Stripe supports KES.
  // Assuming amount passed is in major units (e.g. 100.00), convert to minor units (10000).
  const amountInSmallestUnit = Math.round(amount * 100);

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountInSmallestUnit,
      currency: currency,
      automatic_payment_methods: { enabled: true },
    });

    return { clientSecret: paymentIntent.client_secret };
  } catch (error) {
    console.error("Stripe Error:", error);
    throw new functions.https.HttpsError("internal", "Failed to create PaymentIntent");
  }
});


// Placeholder function for M-Pesa Callback
exports.mpesaCallback = functions.https.onRequest(async (req, res) => {
  console.log("M-Pesa Callback received", JSON.stringify(req.body));

  const body = req.body.Body.stkCallback;
  const checkoutRequestId = body.CheckoutRequestID;
  const resultCode = body.ResultCode;

  if (resultCode === 0) {
    // Payment Successful
    const metadata = body.CallbackMetadata.Item;
    const mpesaReceiptNumber = metadata.find(i => i.Name === "MpesaReceiptNumber").Value;
    const amount = metadata.find(i => i.Name === "Amount").Value;

    // Update payment record in Firestore
    const paymentsSnapshot = await admin.firestore().collection("payments")
      .where("checkoutRequestId", "==", checkoutRequestId)
      .limit(1)
      .get();

    if (!paymentsSnapshot.empty) {
      const paymentDoc = paymentsSnapshot.docs[0];
      await paymentDoc.ref.update({
        status: "completed",
        transactionId: mpesaReceiptNumber,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        rawCallback: req.body
      });

      // Update Order status
      const orderId = paymentDoc.data().orderId;
      // Depending on structure, update order collection
      const ordersSnapshot = await admin.firestore().collection("orders").where("id", "==", orderId).limit(1).get();
      if (!ordersSnapshot.empty) {
        await ordersSnapshot.docs[0].ref.update({
          status: "paid",
          paymentMethod: "mpesa",
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }
  } else {
    // Payment Failed/Cancelled
    const paymentsSnapshot = await admin.firestore().collection("payments")
      .where("checkoutRequestId", "==", checkoutRequestId)
      .limit(1)
      .get();

    if (!paymentsSnapshot.empty) {
      await paymentsSnapshot.docs[0].ref.update({
        status: "failed",
        failureReason: body.ResultDesc,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        rawCallback: req.body
      });
    }
  }

  res.status(200).json({ result: "success" });
});

// Placeholder function for Stripe Webhook
exports.stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const endpointSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error(`Webhook Error: ${err.message}`);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle the event
  switch (event.type) {
    case "payment_intent.succeeded":
      const paymentIntentSucceeded = event.data.object;
      console.log("PaymentIntent was successful!", paymentIntentSucceeded);
      // Fulfill the order...
      break;
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.status(200).send();
});
