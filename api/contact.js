// Vercel serverless function: sends the contact form through Resend. Secrets stay in environment variables.
const hits = new Map();   // simple per-instance rate limit (5 messages / hour / IP)

module.exports = async (req, res) => {
  if (req.method !== "POST") return res.status(405).json({ ok: false, error: "method" });
  const b = typeof req.body === "string" ? JSON.parse(req.body || "{}") : (req.body || {});
  if (b.website) return res.status(200).json({ ok: true });                 // honeypot: bots fill this in

  const ip = (req.headers["x-forwarded-for"] || "").split(",")[0].trim() || "x";
  const now = Date.now(), recent = (hits.get(ip) || []).filter(t => now - t < 3600000);
  if (recent.length >= 5) return res.status(429).json({ ok: false, error: "rate" });

  const name = String(b.name || "").trim(), email = String(b.email || "").trim();
  const subject = String(b.subject || "").trim(), message = String(b.message || "").trim();
  if (name.length < 2 || name.length > 80 || subject.length < 2 || subject.length > 120 ||
      message.length < 5 || message.length > 4000 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 120)
    return res.status(400).json({ ok: false, error: "invalid" });

  const key = process.env.RESEND_API_KEY, to = process.env.CONTACT_TO_EMAIL;
  if (!key || !to) return res.status(503).json({ ok: false, error: "not_configured" });

  try {
    const r = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: "Bearer " + key, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: process.env.CONTACT_FROM || "Website <onboarding@resend.dev>",
        to: [to], reply_to: email, subject: "[Website] " + subject,
        text: "From: " + name + " <" + email + ">\n\n" + message
      })
    });
    if (!r.ok) return res.status(502).json({ ok: false, error: "send_failed" });
    hits.set(ip, recent.concat(now));
    return res.status(200).json({ ok: true });
  } catch {
    return res.status(502).json({ ok: false, error: "send_failed" });
  }
};
