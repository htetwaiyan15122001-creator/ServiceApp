/**
 * One-off script: bulk-imports a CSV of existing LINE friends (Username +
 * LineID) into the SharePoint "LineCustomers" list, so they show up as
 * already-linked customers without needing the QR/code linking flow.
 *
 * USAGE:
 *   1. Put the CSV at the project root as: Line_Usernames_and_IDs.csv
 *      (same folder as .env — i.e. D:\JUNG\ServiceApp\Line_Usernames_and_IDs.csv)
 *   2. From D:\JUNG\ServiceApp\src, run:  node importLineCustomers.js
 *
 * Safe to re-run: it checks each LineUserID against SharePoint first and
 * skips it if a row already exists, so running it twice won't create
 * duplicates.
 *
 * Dedupes by LineID within the CSV itself (some names appear more than once
 * with the same ID — keeps the first occurrence's name).
 */
const path = require("path");
const fs = require("fs");
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });

const { createListItem, findItemByField } = require("./sharepoint");

const CSV_PATH = path.join(__dirname, "..", "Line_Usernames_and_IDs.csv");
const LIST_NAME = process.env.SP_LINE_CUSTOMERS_LIST || "LineCustomers";

// Minimal CSV parser that handles quoted fields with doubled-quote escaping
// (e.g. """Ton""@Samos" -> `"Ton"@Samos`), since a couple of rows need it.
function parseCsvLine(line) {
  const result = [];
  let cur = "";
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (inQuotes) {
      if (c === '"') {
        if (line[i + 1] === '"') {
          cur += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cur += c;
      }
    } else {
      if (c === '"') inQuotes = true;
      else if (c === ",") {
        result.push(cur);
        cur = "";
      } else {
        cur += c;
      }
    }
  }
  result.push(cur);
  return result;
}

function loadRows() {
  const raw = fs.readFileSync(CSV_PATH, "utf8").replace(/^\uFEFF/, "");
  const lines = raw.split(/\r?\n/).filter((l) => l.trim().length > 0);
  const [, ...dataLines] = lines; // skip header row
  return dataLines
    .map(parseCsvLine)
    .map(([username, lineId]) => ({ username: (username || "").trim(), lineId: (lineId || "").trim() }))
    .filter((r) => r.lineId);
}

function dedupeByLineId(rows) {
  const seen = new Set();
  const unique = [];
  for (const row of rows) {
    if (!seen.has(row.lineId)) {
      seen.add(row.lineId);
      unique.push(row);
    }
  }
  return unique;
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  const rows = dedupeByLineId(loadRows());
  console.log(`Loaded ${rows.length} unique LINE customers to import.`);

  let created = 0;
  let skipped = 0;
  let failed = 0;

  for (let i = 0; i < rows.length; i++) {
    const { username, lineId } = rows[i];
    try {
      const existing = await findItemByField(LIST_NAME, "LineUserID", lineId);
      if (existing) {
        skipped++;
      } else {
        await createListItem(LIST_NAME, {
          Title: username || lineId,
          CustomerName: username || lineId,
          LineCode: "",
          LineUserID: lineId,
        });
        created++;
      }
    } catch (err) {
      failed++;
      console.error(`Failed on "${username}" (${lineId}):`, err.response?.data || err.message);
    }

    if ((i + 1) % 20 === 0 || i === rows.length - 1) {
      console.log(`Progress: ${i + 1}/${rows.length} — created ${created}, skipped ${skipped}, failed ${failed}`);
    }

    // Small delay to stay well under Graph's throttling limits.
    await sleep(150);
  }

  console.log("Done.");
  console.log(`Created: ${created}, already existed (skipped): ${skipped}, failed: ${failed}`);
}

main().catch((err) => {
  console.error("Import script crashed:", err);
  process.exit(1);
});
