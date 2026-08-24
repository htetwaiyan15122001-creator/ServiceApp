const { graphFetch } = require("./graphAuth");

const SITE_ID = process.env.SP_SITE_ID;

// ---- Document library (file uploads) ----

let cachedDriveId = null;

/**
 * Resolves the drive (document library) ID for SP_PHOTOS_LIBRARY, once,
 * then caches it — document libraries show up as "drives" in Graph.
 */
async function getPhotosDriveId() {
  if (cachedDriveId) return cachedDriveId;

  const libraryName = process.env.SP_PHOTOS_LIBRARY;
  const data = await graphFetch(`/sites/${SITE_ID}/drives`);
  const drive = (data.value || []).find((d) => d.name === libraryName);

  if (!drive) {
    throw new Error(
      `No document library named "${libraryName}" found on this site. ` +
      `Check SP_PHOTOS_LIBRARY in .env matches the library's exact name.`
    );
  }

  cachedDriveId = drive.id;
  return cachedDriveId;
}

/**
 * Uploads a single file (given as base64) into a per-job folder in the
 * photos library, e.g. /ServiceReportPhotos/<jobId>/<fileName>.
 * Uses Graph's "simple upload" — fine up to 4MB per file, which covers
 * typical phone camera photos and signature PNGs. Larger files would need
 * an upload session instead (see Graph docs on large file uploads).
 */
async function uploadFileToJobFolder(jobId, fileName, base64Content) {
  const driveId = await getPhotosDriveId();
  const safeJobId = encodeURIComponent(jobId || "unfiled");
  const safeFileName = encodeURIComponent(fileName);
  const bytes = Buffer.from(base64Content, "base64");

  const result = await graphFetch(
    `/drives/${driveId}/root:/${safeJobId}/${safeFileName}:/content`,
    {
      method: "PUT",
      headers: { "Content-Type": "application/octet-stream" },
      body: bytes,
    }
  );

  return result; // includes id, webUrl, parentReference.driveId, etc.
}

/**
 * Downloads a previously-uploaded file's raw bytes and returns them as
 * base64 — used by /signature-status to hand the app back exactly the
 * PNG the customer drew, without ever storing that blob in a SharePoint
 * list column (plain-text list columns cap out around 64,000 characters,
 * which a signature image can realistically exceed).
 */
async function downloadFileAsBase64(driveId, itemId) {
  const token = await require("./graphAuth").getGraphToken();
  const res = await fetch(`https://graph.microsoft.com/v1.0/drives/${driveId}/items/${itemId}/content`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    throw new Error(`Failed to download file ${itemId}: ${res.status}`);
  }
  const buffer = Buffer.from(await res.arrayBuffer());
  return buffer.toString("base64");
}

/**
 * Downloads a file's raw bytes as base64 using its known per-job-folder
 * path, e.g. /ServiceReportPhotos/<jobId>/<fileName> — for cases like
 * signatures where the file name is deterministic and there's no list
 * column storing a driveId/itemId pointer to look it up by.
 */
async function downloadFileFromJobFolder(jobId, fileName) {
  const driveId = await getPhotosDriveId();
  const safeJobId = encodeURIComponent(jobId || "unfiled");
  const safeFileName = encodeURIComponent(fileName);
  const token = await require("./graphAuth").getGraphToken();

  const res = await fetch(
    `https://graph.microsoft.com/v1.0/drives/${driveId}/root:/${safeJobId}/${safeFileName}:/content`,
    { headers: { Authorization: `Bearer ${token}` } }
  );
  if (res.status === 404) return null; // not signed yet — no file there
  if (!res.ok) {
    throw new Error(`Failed to download ${safeJobId}/${safeFileName}: ${res.status}`);
  }
  const buffer = Buffer.from(await res.arrayBuffer());
  return buffer.toString("base64");
}

// ---- SharePoint lists (structured records) ----

const listIdCache = {};

/**
 * Resolves a list's ID by display name, once, then caches it.
 */
async function getListId(listName) {
  if (listIdCache[listName]) return listIdCache[listName];

  const data = await graphFetch(
    `/sites/${SITE_ID}/lists?$filter=displayName eq '${listName}'`
  );
  const list = (data.value || [])[0];

  if (!list) {
    throw new Error(`No SharePoint list named "${listName}" found on this site.`);
  }

  listIdCache[listName] = list.id;
  return list.id;
}

/**
 * Creates a new item in the given list with the given field values.
 * `fields` keys must match the list's internal column names exactly
 * (see README for the exact columns each list needs).
 */
async function createListItem(listName, fields) {
  const listId = await getListId(listName);
  return graphFetch(`/sites/${SITE_ID}/lists/${listId}/items`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ fields }),
  });
}

/**
 * Finds the first item in a list whose given field matches a value.
 * Generic version of findItemByJobId — used for looking up rows by any
 * single field (e.g. LineCode, CustomerName).
 */
async function findItemByField(listName, fieldName, value) {
  const listId = await getListId(listName);
  const data = await graphFetch(
    `/sites/${SITE_ID}/lists/${listId}/items?$filter=fields/${fieldName} eq '${value}'&$expand=fields`,
    { headers: { Prefer: "HonorNonIndexedQueriesWarningMayFailRandomly" } }
  );
  return (data.value || [])[0] || null;
}

/**
 * Returns every item in a list, with fields expanded. Fine for small
 * reference lists (e.g. saved LINE customers) — for large lists you'd want
 * paging instead, since Graph caps each page at 200 items by default.
 */
async function listAllItems(listName) {
  const listId = await getListId(listName);
  const data = await graphFetch(`/sites/${SITE_ID}/lists/${listId}/items?$expand=fields`);
  return data.value || [];
}

/**
 * Finds the first item in a list whose JobId field matches. Adds the
 * "honor non-indexed queries" header since JobId won't be indexed by
 * default on a small/new list — fine at this scale, but if the list
 * grows large, add an index on the JobId column in SharePoint's list
 * settings for reliable performance.
 */
async function findItemByJobId(listName, jobId) {
  const listId = await getListId(listName);
  const data = await graphFetch(
    `/sites/${SITE_ID}/lists/${listId}/items?$filter=fields/JobId eq '${jobId}'&$expand=fields`,
    { headers: { Prefer: "HonorNonIndexedQueriesWarningMayFailRandomly" } }
  );
  return (data.value || [])[0] || null;
}

/**
 * Updates the field values of an existing list item.
 */
async function updateListItem(listName, itemId, fields) {
  const listId = await getListId(listName);
  return graphFetch(`/sites/${SITE_ID}/lists/${listId}/items/${itemId}/fields`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(fields),
  });
}

/**
 * Creates the item if none exists for this jobId yet, otherwise updates
 * the existing one. Used by /receive-signature so a customer can't
 * accidentally create duplicate rows if they double-tap submit.
 */
async function upsertItemByJobId(listName, jobId, fields) {
  const existing = await findItemByJobId(listName, jobId);
  if (existing) {
    await updateListItem(listName, existing.id, fields);
    return existing.id;
  }
  const created = await createListItem(listName, { JobId: jobId, ...fields });
  return created.id;
}

// ---- Mail ----

/**
 * Sends an email as MAIL_SENDER_UPN via Graph. Requires the app
 * registration to have the Mail.Send Application permission, granted
 * with admin consent, scoped (ideally) to just that mailbox.
 */
async function sendMail({ to, subject, htmlBody }) {
  const sender = process.env.MAIL_SENDER_UPN;
  await graphFetch(`/users/${sender}/sendMail`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        subject,
        body: { contentType: "HTML", content: htmlBody },
        toRecipients: [{ emailAddress: { address: to } }],
      },
      saveToSentItems: true,
    }),
  });
}

module.exports = {
  getPhotosDriveId,
  uploadFileToJobFolder,
  downloadFileAsBase64,
  downloadFileFromJobFolder,
  createListItem,
  findItemByJobId,
  findItemByField,
  listAllItems,
  updateListItem,
  upsertItemByJobId,
  sendMail,
};