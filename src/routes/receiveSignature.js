const express = require("express");
const { uploadFileToJobFolder, findItemByField, createListItem, updateListItem } = require("../sharepoint");

const router = express.Router();

// Matches the fetch() body in sign.html's submit handler.
router.post("/", async (req, res) => {
  const { jobId, signatureBase64, signedAt, rating, comment } = req.body;

  if (!jobId || !signatureBase64) {
    return res.status(400).json({ success: false, error: "jobId and signatureBase64 are required" });
  }

  const listName = process.env.SP_SIGNATURES_LIST;
  if (!listName) {
    return res.status(500).json({
      success: false,
      error: "Missing SP_SIGNATURES_LIST in .env — set it to the SharePoint list's display name.",
    });
  }

  try {
    // Upload the signature PNG into the job's folder in the photos
    // library — same per-job-folder convention as service report photos.
    const uploaded = await uploadFileToJobFolder(jobId, `${jobId}_signature.png`, signatureBase64);

    const fields = {
      Signed: true,
      SignatureUrl: uploaded.webUrl,
      Rating: rating != null ? String(rating) : "",
      Comment: comment || "",
    };

    // Upsert by JobID so a double-tap submit updates the existing row
    // instead of creating a duplicate.
    const existing = await findItemByField(listName, "JobID", jobId);
    if (existing) {
      await updateListItem(listName, existing.id, fields);
    } else {
      await createListItem(listName, { JobID: jobId, ...fields });
    }

    res.json({ success: true });
  } catch (err) {
    console.error("receiveSignature failed:", err.response?.data || err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;