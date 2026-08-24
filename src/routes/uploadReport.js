const express = require("express");
const { uploadFileToJobFolder } = require("../sharepoint");

const router = express.Router();

// Matches SharePointService.uploadServiceReport()'s JSON body in the app.
router.post("/", async (req, res) => {
  const {
    jobId,
    photos = [],
    photoFileName,
    photoBase64,
    signatureBase64,
    serviceBy,
    serviceByEmail,
    remarks,
    callToAction,
    authorizedBy,
    jobType,
    customerNotOnSite,
    submittedAt,
  } = req.body;

  try {
    const uploaded = [];

    // Prefer the full `photos` array; fall back to the single legacy fields.
    const photoList = photos.length > 0
      ? photos
      : (photoBase64 ? [{ fileName: photoFileName || "photo.jpg", base64: photoBase64 }] : []);

    for (const photo of photoList) {
      const result = await uploadFileToJobFolder(jobId, photo.fileName, photo.base64);
      uploaded.push(result.webUrl);
    }

    if (signatureBase64) {
      const sigResult = await uploadFileToJobFolder(jobId, "signature.png", signatureBase64);
      uploaded.push(sigResult.webUrl);
    }

    // Also write a small JSON metadata file alongside the photos/signature
    // in the same per-job folder, so the report's details are recorded
    // even without a SharePoint list.
    const metadata = {
      jobId, serviceBy, serviceByEmail, remarks, callToAction,
      authorizedBy, jobType, customerNotOnSite, submittedAt,
    };
    const metadataResult = await uploadFileToJobFolder(
      jobId,
      "report.json",
      Buffer.from(JSON.stringify(metadata, null, 2)).toString("base64")
    );
    uploaded.push(metadataResult.webUrl);

    res.json({ success: true, uploaded });
  } catch (err) {
    console.error("uploadReport failed:", err.response?.data || err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;