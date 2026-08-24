const express = require("express");
const { uploadFileToJobFolder, createListItem, updateListItem, findItemByField } = require("../sharepoint");

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
    const photoUrls = [];
    let signatureUrl = "";

    // Prefer the full `photos` array; fall back to the single legacy fields.
    const photoList = photos.length > 0
      ? photos
      : (photoBase64 ? [{ fileName: photoFileName || "photo.jpg", base64: photoBase64 }] : []);

    for (const photo of photoList) {
      const result = await uploadFileToJobFolder(jobId, photo.fileName, photo.base64);
      uploaded.push(result.webUrl);
      photoUrls.push(result.webUrl);
    }

    if (signatureBase64) {
      const sigResult = await uploadFileToJobFolder(jobId, "signature.png", signatureBase64);
      uploaded.push(sigResult.webUrl);
      signatureUrl = sigResult.webUrl;
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

    // Write the report as a real row in the Submitform list too, so it
    // shows up as structured data instead of only living as files.
    const reportsList = process.env.SP_REPORTS_LIST;
    if (reportsList) {
      await createListItem(reportsList, {
        Title: `Report - ${jobId || "unfiled"}`,
        JobID: jobId || "",
        ServiceBy: serviceBy || "",
        Remarks: remarks || "",
        CalltoAction: callToAction || "",
        AuthorizedBy: authorizedBy || "",
        JobType: jobType || "",
        CustomerNotOnSite: !!customerNotOnSite,
        Signature: signatureUrl,
        Photo: photoUrls.join(", "),
      });
    }

    // If the customer signed on-site (as opposed to via the remote LINE/
    // email link, which goes through /receive-signature instead), record
    // that in Signature_List too so both signing paths end up there.
    const signaturesList = process.env.SP_SIGNATURES_LIST;
    if (signaturesList && signatureUrl) {
      const sigFields = {
        Signed: true,
        SignatureUrl: signatureUrl,
      };
      const existingSig = await findItemByField(signaturesList, "JobID", jobId || "");
      if (existingSig) {
        await updateListItem(signaturesList, existingSig.id, sigFields);
      } else {
        await createListItem(signaturesList, {
          Title: `Signature - ${jobId || "unfiled"}`,
          JobID: jobId || "",
          ...sigFields,
        });
      }
    }

    res.json({ success: true, uploaded });
  } catch (err) {
    console.error("uploadReport failed:", err.response?.data || err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;