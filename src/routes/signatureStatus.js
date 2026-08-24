const express = require("express");
const { findItemByField, downloadFileFromJobFolder } = require("../sharepoint");

const router = express.Router();

// Matches SharePointService.checkSignatureStatus()'s JSON body in the app.
router.post("/", async (req, res) => {
  const { jobId } = req.body;
  if (!jobId) return res.status(400).json({ signed: false, error: "jobId is required" });

  const listName = process.env.SP_SIGNATURES_LIST;
  if (!listName) {
    return res.status(500).json({
      signed: false,
      error: "Missing SP_SIGNATURES_LIST in .env — set it to the SharePoint list's display name.",
    });
  }

  try {
    const item = await findItemByField(listName, "JobID", jobId);
    if (!item || !item.fields.Signed) {
      return res.json({ signed: false });
    }

    const signatureBase64 = await downloadFileFromJobFolder(jobId, `${jobId}_signature.png`);
    if (!signatureBase64) {
      return res.json({ signed: false });
    }

    res.json({ signed: true, signatureBase64 });
  } catch (err) {
    console.error("signatureStatus failed:", err.message);
    res.status(500).json({ signed: false, error: err.message });
  }
});

module.exports = router;