/**
 * Firebase Function: Paystack Webhook Handler
 * Handles Paystack webhook events securely.
 */
const functions = require("firebase-functions");
const express = require("express");
const bodyParser = require("body-parser");
const crypto = require("crypto");

const app = express();
app.use(bodyParser.json());

app.post("/paystack-webhook", (req, res) => {
  const secret = process.env.PAYSTACK_SECRET_KEY;
  const hash = crypto
      .createHmac("sha512", secret)
      .update(JSON.stringify(req.body))
      .digest("hex");

  if (hash !== req.headers["x-paystack-signature"]) {
    return res.status(401).send("Unauthorized");
  }

  // TODO: Add your event handling logic here
  res.sendStatus(200);
});

exports.paystackWebhook = functions.https.onRequest(app);
