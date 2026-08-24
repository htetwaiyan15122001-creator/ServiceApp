const axios = require("axios");
const crypto = require("crypto");

const LINE_API_BASE = "https://api.line.me/v2/bot";

/**
 * Pushes a text message to a specific LINE user.
 * `to` must be a LINE userId obtained from a webhook event (see lineWebhook.js) —
 * LINE does not allow pushing messages to arbitrary phone numbers/emails.
 */
async function pushMessage(to, text) {
  const token = process.env.LINE_CHANNEL_ACCESS_TOKEN;
  if (!token) throw new Error("Missing LINE_CHANNEL_ACCESS_TOKEN — check your .env file.");

  await axios.post(
    `${LINE_API_BASE}/message/push`,
    { to, messages: [{ type: "text", text }] },
    { headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } }
  );
}

/**
 * Pushes a message with a single tappable button (LINE "buttons" template)
 * — used for the "Sign Now" signing-link message, so the URL is hidden
 * behind a button instead of shown as raw text.
 */
async function pushButtonMessage(to, { text, buttonLabel, buttonUrl }) {
  const token = process.env.LINE_CHANNEL_ACCESS_TOKEN;
  if (!token) throw new Error("Missing LINE_CHANNEL_ACCESS_TOKEN — check your .env file.");

  await axios.post(
    `${LINE_API_BASE}/message/push`,
    {
      to,
      messages: [
        {
          type: "template",
          altText: text,
          template: {
            type: "buttons",
            text: text.slice(0, 160), // LINE's buttons template text limit
            actions: [{ type: "uri", label: buttonLabel.slice(0, 20), uri: buttonUrl }],
          },
        },
      ],
    },
    { headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" } }
  );
}

/**
 * Verifies that an incoming webhook request really came from LINE, using the
 * channel secret. LINE signs the raw request body with HMAC-SHA256 and sends
 * the result (base64) in the x-line-signature header.
 */
function verifySignature(rawBody, signatureHeader) {
  const channelSecret = process.env.LINE_CHANNEL_SECRET;
  if (!channelSecret) throw new Error("Missing LINE_CHANNEL_SECRET — check your .env file.");

  const expected = crypto
    .createHmac("SHA256", channelSecret)
    .update(rawBody)
    .digest("base64");

  return expected === signatureHeader;
}

module.exports = { pushMessage, pushButtonMessage, verifySignature };
