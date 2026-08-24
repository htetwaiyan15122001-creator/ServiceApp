const path = require("path");
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });
const express = require("express");
const cors = require("cors");

const uploadReport = require("./routes/uploadReport");
const signatureLink = require("./routes/signatureLink");
const signatureLinkLine = require("./routes/signatureLinkLine");
const signatureStatus = require("./routes/signatureStatus");
const receiveSignature = require("./routes/receiveSignature");
const lineWebhook = require("./routes/lineWebhook");
const lineRegisterCustomer = require("./routes/lineRegisterCustomer");
const lineCustomers = require("./routes/lineCustomers");
const userRole = require("./routes/userRole");

const app = express();

app.use(cors());

// IMPORTANT: mounted BEFORE express.json() below. LINE's webhook signature
// is computed over the exact raw bytes of the request body — once
// express.json() parses and Express re-serializes a body, you can no longer
// reproduce those exact bytes, so signature verification would always fail.
// express.raw() here keeps this one route's body as an untouched Buffer.
app.use("/line/webhook", express.raw({ type: "*/*", limit: "5mb" }));

// Photos/signatures are base64 in the JSON body, so allow a generous limit.
app.use(express.json({ limit: "25mb" }));

// Simple shared-secret check so random internet traffic can't hit these
// endpoints. sign.html is public-facing (no login), so it's intentionally
// left open — its only "write" ability is submitting one signature per job.
function requireApiKey(req, res, next) {
  const expected = process.env.API_KEY;
  if (!expected) return next(); // no key configured — allow (dev mode)
  if (req.headers["x-api-key"] !== expected) {
    return res.status(401).json({ success: false, error: "Invalid or missing API key" });
  }
  next();
}

app.get("/health", (req, res) => res.json({ ok: true }));

app.use("/upload-report", requireApiKey, uploadReport);
// Original email-based flow — left in place in case you want it back later.
app.use("/send-signature-link", requireApiKey, signatureLink);
// Active flow: sends the signing link via LINE instead of email.
app.use("/send-signature-link-line", requireApiKey, signatureLinkLine);
app.use("/line/register-customer", requireApiKey, lineRegisterCustomer);
app.use("/line/customers", requireApiKey, lineCustomers);
app.use("/signature-status", requireApiKey, signatureStatus);
app.use("/user-role", requireApiKey, userRole);
// No API key here — sign.html is a public page with no login of its own.
app.use("/receive-signature", receiveSignature);
// No API key here either — LINE calls this directly; protected by the
// x-line-signature check inside the route instead.
app.use("/line/webhook", lineWebhook);

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`ServicePro SharePoint backend listening on port ${port}`);
});