const express = require("express");
const { findItemByField, listAllItems } = require("../sharepoint");

const router = express.Router();

// Normalizes whatever's in the Role column (e.g. "Engineer Manger" — a
// typo in SharePoint for "Manager") into the lowercase strings the app's
// UserRole enum expects: "engineer" | "manager" | "sales".
function normalizeRole(raw) {
  const r = (raw || "").toLowerCase();
  if (r.includes("manager") || r.includes("manger")) return "manager";
  if (r.includes("sales")) return "sales";
  return "engineer";
}

// Matches SharePointService.fetchUserRole()'s JSON body: { email }.
// Also doubles as the login gate — an email not found in UserRoles
// returns an error and the app blocks sign-in.
router.post("/", async (req, res) => {
  const { email } = req.body;

  if (!email || !email.trim()) {
    return res.status(400).json({ success: false, error: "Email is required" });
  }

  const listName = process.env.SP_USER_ROLES_LIST || "UserRoles";

  try {
    let item = await findItemByField(listName, "Email", email.trim());

    // SharePoint's eq filter is usually case-insensitive, but fall back to
    // a full scan + manual compare just in case, so a typed-in email with
    // different casing than the stored value still matches.
    if (!item) {
      const all = await listAllItems(listName);
      item = all.find(
        (i) => (i.fields.Email || "").trim().toLowerCase() === email.trim().toLowerCase()
      ) || null;
    }

    if (!item) {
      return res.status(404).json({ success: false, error: "This email isn't set up in UserRoles yet." });
    }

    res.json({
      success: true,
      role: normalizeRole(item.fields.Role),
      name: item.fields.Name || "",
    });
  } catch (err) {
    console.error("userRole lookup failed:", err.response?.data || err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;