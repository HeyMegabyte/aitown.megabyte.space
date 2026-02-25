import { Container } from "@cloudflare/containers";
import { env } from "cloudflare:workers";


interface Env {
  readonly APP: DurableObjectNamespace;
  readonly APP_DOMAIN: string;
  readonly [key: string]: unknown;
}

export class App extends Container<Env> {
  override defaultPort = 8080;
  override sleepAfter = "30m";
  override enableInternet = true;

  // Pass environment variables to the Docker container
  override envVars = {
    "PUBLIC_URL": (env as unknown as Env).PUBLIC_URL || "",
    "HOSTNAME": (env as unknown as Env).HOSTNAME || "",
    "PORT": (env as unknown as Env).PORT || "",
    "APP_DOMAIN": (env as unknown as Env).APP_DOMAIN || "",
    "SECRET_KEY": (env as unknown as Env).SECRET_KEY || "",
  };

  override onStart(): void {
    console.log("[container] AI Town container started");
  }

  override onStop(): void {
    console.log("[container] AI Town container stopped (sleeping)");
  }

  override onError(error: unknown): void {
    const msg = error instanceof Error ? error.message : String(error);
    console.error("[container] AI Town container error:", msg);
  }

  override async fetch(request: Request): Promise<Response> {
    // Retry loop: wait for the container to boot and serve the real app.
    // Avoids showing a loading page — the first request blocks until the app responds.
    // CF returns 500/502/503 while the container starts (~17s each), so 3 attempts ≈ 50s.
    const maxAttempts = 3;
    let lastResp: Response | undefined;
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const resp = await super.fetch(request);
        // Any 5xx means container infra is still starting — retry
        if (resp.status < 500) {
          return resp;
        }
        lastResp = resp;
        if (attempt === maxAttempts) return resp;
      } catch {
        if (attempt === maxAttempts) {
          return new Response(SPINNING_UP_HTML, {
            status: 503,
            headers: { "Content-Type": "text/html; charset=utf-8", "Retry-After": "5" },
          });
        }
      }
      await new Promise(r => setTimeout(r, 2000));
    }
    return lastResp ?? new Response(SPINNING_UP_HTML, {
      status: 503,
      headers: { "Content-Type": "text/html; charset=utf-8", "Retry-After": "5" },
    });
  }
}

const SPINNING_UP_HTML = `<!DOCTYPE html><html><head><meta charset="utf-8"><title>AI Town — Starting</title>
<meta http-equiv="refresh" content="5"><style>*{margin:0;padding:0;box-sizing:border-box}body{background:#0a0a0f;color:#fff;font-family:Inter,system-ui,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh}
.card{text-align:center;padding:48px;background:rgba(255,255,255,0.04);border:1px solid rgba(255,255,255,0.08);border-radius:20px;backdrop-filter:blur(20px);max-width:400px}
h1{font-size:20px;font-weight:700;margin-bottom:8px}p{color:rgba(255,255,255,0.5);font-size:14px}
.spinner{width:32px;height:32px;border:3px solid rgba(0,229,255,0.2);border-top-color:#00e5ff;border-radius:50%;animation:spin .8s linear infinite;margin:0 auto 16px}
@keyframes spin{to{transform:rotate(360deg)}}</style></head>
<body><div class="card"><div class="spinner"></div><h1>AI Town</h1><p>Container is starting up. This page will auto-refresh.</p></div></body></html>`;

export default {
  async fetch(request: Request, workerEnv: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/__health") {
      return Response.json({ status: "ok", service: "AI Town", timestamp: new Date().toISOString() });
    }

    try {
      const id = workerEnv.APP.idFromName("ai-town");
      const stub = workerEnv.APP.get(id);
      return await stub.fetch(request);
    } catch {
      // DO/stub-level failure — return fallback page
      return new Response(SPINNING_UP_HTML, {
        status: 503,
        headers: { "Content-Type": "text/html; charset=utf-8", "Retry-After": "5" },
      });
    }
  },
};
