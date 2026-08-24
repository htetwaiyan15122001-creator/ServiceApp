const axios = require("axios");

const GRAPH_BASE = "https://graph.microsoft.com/v1.0";

let cachedToken = null;
let cachedExpiry = 0; // epoch ms

/**
 * Gets an app-only (client credentials) access token for Microsoft Graph.
 * Caches it in memory and only re-requests once it's close to expiring,
 * so we're not hitting the token endpoint on every request.
 */
async function getGraphToken() {
  const now = Date.now();
  if (cachedToken && now < cachedExpiry - 60_000) {
    return cachedToken;
  }

  const tenantId = process.env.AZURE_TENANT_ID;
  const clientId = process.env.AZURE_CLIENT_ID;
  const clientSecret = process.env.AZURE_CLIENT_SECRET;

  if (!tenantId || !clientId || !clientSecret) {
    throw new Error(
      "Missing AZURE_TENANT_ID / AZURE_CLIENT_ID / AZURE_CLIENT_SECRET — check your .env file."
    );
  }

  const url = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`;
  const body = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    scope: "https://graph.microsoft.com/.default",
    grant_type: "client_credentials",
  });

  const response = await axios.post(url, body, {
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });

  cachedToken = response.data.access_token;
  cachedExpiry = now + response.data.expires_in * 1000;
  return cachedToken;
}

/**
 * Authenticated fetch against Microsoft Graph. `path` can be a path
 * relative to the Graph v1.0 root (e.g. "/sites/xyz/lists") or a full URL.
 * Returns the parsed JSON body. This is what every function in
 * sharepoint.js is built on top of.
 */
async function graphFetch(path, options = {}) {
  const token = await getGraphToken();
  const url = path.startsWith("http") ? path : `${GRAPH_BASE}${path}`;

  const response = await axios({
    url,
    method: options.method || "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    },
    data: options.body,
    // Let 4xx responses come back as normal data instead of throwing, so
    // callers can inspect status codes themselves if they need to.
    validateStatus: () => true,
  });

  if (response.status >= 400) {
    const detail = typeof response.data === "object" ? JSON.stringify(response.data) : response.data;
    throw new Error(`Graph API error ${response.status} for ${options.method || "GET"} ${url}: ${detail}`);
  }

  return response.data;
}

module.exports = { getGraphToken, graphFetch };