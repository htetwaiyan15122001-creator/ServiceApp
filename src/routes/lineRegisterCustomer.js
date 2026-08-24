const express = require("express");
const crypto = require("crypto");
const { findItemByField, createListItem } = require("../sharepoint");

const router = express.Router();

/** Generates a short, human-typeable code, e.g. "K3F9QZ". */
function generateCode() {
  return crypto.randomBytes(4).toString("hex").toUpperCase().slice(0, 6);
}

// Matches SharePointService.registerLineCustomer()'s JSON body in the app.
router.post("/", async (req, res) => {
  const { customerName } = req.body;
  if (!customerName || !customerName.trim()) {
    return res.status(400).json({ error: "customerName is required" });
  }
  const name = customerName.trim();

  const oaId = process.env.LINE_OA_BASIC_ID;
  if (!oaId) {
    return res.status(500).json({
      error: "Missing LINE_OA_BASIC_ID in .env — find it in the LINE Official Account Manager under Settings > Account settings.",
    });
  }

  const listName = process.env.SP_LINE_CUSTOMERS_LIST;
  if (!listName) {
    return res.status(500).json({
      error: "Missing SP_LINE_CUSTOMERS_LIST in .env — set it to the SharePoint list's display name.",
    });
  }

  try {
    // If this exact customer already has a registration that hasn't
    // linked yet, reuse its code instead of creating a duplicate row —
    // otherwise retrying a bad scan would leave ambiguous duplicates.
    const existing = await findItemByField(listName, "CustomerName", name);
    let code;
    if (existing && !existing.fields.LineUserId) {
      code = existing.fields.LineCode;
    } else {
      code = generateCode();
      await createListItem(listName, {
        CustomerName: name,
        LineCode: code,
      });
    }

    // Deep link that opens a chat with the OA, with the code pre-filled as
    // the message — the customer only has to tap Send once LINE opens.
    const qrLink = `https://line.me/R/oaMessage/${encodeURIComponent(oaId)}/?${encodeURIComponent(code)}`;

    res.json({ code, qrLink });
  } catch (err) {
    console.error("registerLineCustomer failed:", err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;