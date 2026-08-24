const express = require("express");
const { listAllItems } = require("../sharepoint");

const router = express.Router();

// Matches SharePointService.fetchLineCustomers() in the app.
router.get("/", async (req, res) => {
  const listName = process.env.SP_LINE_CUSTOMERS_LIST;
  if (!listName) {
    return res.status(500).json({
      error: "Missing SP_LINE_CUSTOMERS_LIST in .env — set it to the SharePoint list's display name.",
    });
  }

  try {
    const items = await listAllItems(listName);
    const customers = items.map((item) => ({
      customerName: item.fields.CustomerName || "",
      code: item.fields.LineCode || "",
      linked: !!item.fields.LineUserId,
    }));
    res.json({ customers });
  } catch (err) {
    console.error("lineCustomers failed:", err.message);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;