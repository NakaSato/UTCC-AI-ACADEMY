module.exports = async function handler(request, response) {
  if (request.method !== "GET") {
    response.setHeader("Allow", "GET");
    return response.status(405).json({ error: "Method not allowed" });
  }

  const cronSecret = process.env.CRON_SECRET;
  const authorization = request.headers.authorization;

  if (!cronSecret || authorization !== `Bearer ${cronSecret}`) {
    return response.status(401).json({ error: "Unauthorized" });
  }

  const deployHookUrl = process.env.VERCEL_DEPLOY_HOOK_URL;

  if (!deployHookUrl) {
    return response.status(503).json({ error: "Deploy hook is not configured" });
  }

  const deployment = await fetch(deployHookUrl, { method: "POST" });

  if (!deployment.ok) {
    return response.status(502).json({ error: "Vercel rejected the deploy hook" });
  }

  return response.status(202).json({ accepted: true });
};
