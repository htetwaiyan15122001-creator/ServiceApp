const express = require("express");
const { pushMessage } = require("../lineClient");
const { findItemByField } = require("../sharepoint");

const router = express.Router();

// Matches SharePointService.sendSignatureLinkLine()'s JSON body in the app.
router.post("/", async (req, res) => {
  const { jobId, jobTitle, customerName } = req.body;

  if (!jobId || !customerName) {
    return res.status(400).json({
      success: false,
      error: "jobId and customerName are required",
    });
  }

  const listName = process.env.SP_LINE_CUSTOMERS_LIST;
  if (!listName) {
    return res.status(500).json({
      success: false,
      error: "Missing SP_LINE_CUSTOMERS_LIST in .env — set it to the SharePoint list's display name.",
    });
  }

  let customer;
  try {
    customer = await findItemByField(listName, "CustomerName", customerName);
  } catch (err) {
    console.error("sendSignatureLinkLine lookup failed:", err.message);
    return res.status(500).json({ success: false, error: err.message });
  }

  const lineUserId = customer?.fields?.LineUserId;
  if (!lineUserId) {
    return res.status(409).json({
      success: false,
      error: "not_linked",
      message:
        "This customer hasn't linked their LINE account yet. Register them and " +
        "have them scan the QR code first.",
    });
  }

  const base = process.env.SIGN_PAGE_BASE_URL || "";
  const link = `${base}?job=${encodeURIComponent(jobId)}&title=${encodeURIComponent(jobTitle || "")}`;

  try {
    // LINE auto-detects URLs in a plain text message and renders them as
    // a tappable link, so no buttons template is needed here.
    await pushMessage(
      lineUserId,
      `Please review and sign your service report for "${jobTitle || jobId}":\n${link}`
    );
    res.json({ success: true });
  } catch (err) {
    console.error("sendSignatureLinkLine failed:", err.response?.data || err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;