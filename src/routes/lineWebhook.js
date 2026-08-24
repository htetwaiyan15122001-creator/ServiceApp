const express = require("express");
const { verifySignature } = require("../lineClient");
const { findItemByField, updateListItem } = require("../sharepoint");

const router = express.Router();

// LINE POSTs webhook events here (configure this URL in the LINE Developers
// Console → your channel → Messaging API → Webhook URL).
//
// Uses express.raw() (see server.js) instead of express.json() specifically
// for this route, because signature verification needs the exact raw bytes
// LINE signed — re-serializing a parsed JSON object can produce different
// bytes and make a valid signature look invalid.
router.post("/", async (req, res) => {
  const signature = req.headers["x-line-signature"];
  const rawBody = req.body; // Buffer, thanks to express.raw() in server.js

  let valid = false;
  try {
    valid = verifySignature(rawBody, signature);
  } catch (err) {
    console.error("LINE signature check failed to run:", err.message);
  }

  if (!valid) {
    return res.status(401).send("Invalid signature");
  }

  // Respond to LINE immediately — it expects a fast 200, retries otherwise.
  res.status(200).send("OK");

  let events = [];
  try {
    events = JSON.parse(rawBody.toString("utf8")).events || [];
  } catch (err) {
    console.error("Failed to parse LINE webhook body:", err.message);
    return;
  }

  for (const event of events) {
    const lineUserId = event.source?.userId;
    if (!lineUserId) continue;

    if (event.type === "message" && event.message?.type === "text") {
      // The customer's message text is expected to be the linking code from
      // the QR/tap-to-link flow (see registerLineCustomer.js). Codes are
      // always generated uppercase there, and SharePoint's field filter is
      // case-sensitive, so normalize here in case the customer edited the
      // pre-filled message or their LINE client altered casing.
      const code = event.message.text.trim().toUpperCase();
      try {
        const row = await findItemByField(process.env.SP_LINE_CUSTOMERS_LIST, "LineCode", code);
        if (!row) {
          console.log(`No LineCustomers row found for code "${code}" — ignoring.`);
          continue;
        }
        await updateListItem(process.env.SP_LINE_CUSTOMERS_LIST, row.id, {
          LineUserId: lineUserId,
        });
        console.log(`Linked code "${code}" to LINE user ${lineUserId}`);
      } catch (err) {
        console.error(`Failed to link code "${code}":`, err.message);
      }
    }
    // event.type === "follow" also fires when someone adds the OA as a
    // friend, but without a code in hand yet we can't link it to a customer
    // — that's why we ask them to send their code as a first message.
  }
});

module.exports = router;