const express = require("express");
const { sendMail } = require("../sharepoint");

const router = express.Router();

// Matches SharePointService.sendSignatureLink()'s JSON body in the app.
router.post("/", async (req, res) => {
  const { jobId, jobTitle, customerEmail } = req.body;

  if (!jobId || !customerEmail) {
    return res.status(400).json({ success: false, error: "jobId and customerEmail are required" });
  }

  const base = process.env.SIGN_PAGE_BASE_URL || "";
  const link = `${base}?job=${encodeURIComponent(jobId)}&title=${encodeURIComponent(jobTitle || "")}`;

  try {
    await sendMail({
      to: customerEmail,
      subject: `Please sign your service report — ${jobTitle || jobId}`,
      htmlBody: `
        <p>Hi,</p>
        <p>Please review and sign off on the completed service report for <b>${jobTitle || jobId}</b>:</p>
        <p><a href="${link}">${link}</a></p>
        <p>Thank you.</p>
      `,
    });
    res.json({ success: true });
  } catch (err) {
    console.error("signatureLink failed:", err.response?.data || err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;