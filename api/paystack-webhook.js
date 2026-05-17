const crypto = require("crypto");

module.exports = (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  let body = "";
  req.on("data", chunk => {
    body += chunk;
  });
  req.on("end", () => {
    const secret = process.env.PAYSTACK_SECRET_KEY;
    const hash = crypto
      .createHmac("sha512", secret)
      .update(body)
      .digest("hex");
    if (hash !== req.headers["x-paystack-signature"]) {
      return res.status(401).send("Unauthorized");
    }
    // TODO: Add your event handling logic here
    res.status(200).send("OK");
  });
};