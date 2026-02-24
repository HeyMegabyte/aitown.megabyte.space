// Pure Node.js reverse proxy — routes /api/* to Convex, /* to Vite frontend
// No external dependencies required
import { createServer, request as httpRequest } from "http";
import { Socket } from "net";

const CONVEX_PORT = 3210;
const VITE_PORT = 5173;
const LISTEN_PORT = 8080;

function getTarget(url) {
  if (url.startsWith("/api/") || url === "/version") return CONVEX_PORT;
  return VITE_PORT;
}

const server = createServer((req, res) => {
  const target = getTarget(req.url);
  const options = {
    hostname: "127.0.0.1",
    port: target,
    path: req.url,
    method: req.method,
    headers: { ...req.headers, host: req.headers.host },
  };

  const proxy = httpRequest(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxy.on("error", () => {
    if (!res.headersSent) {
      res.writeHead(502, { "Content-Type": "text/plain" });
      res.end("Bad Gateway — backend not ready");
    }
  });

  req.pipe(proxy);
});

// Handle WebSocket upgrades (Convex real-time sync + Vite HMR)
server.on("upgrade", (req, socket, head) => {
  const target = getTarget(req.url);

  const conn = new Socket();
  conn.connect(target, "127.0.0.1", () => {
    const reqLine = `${req.method} ${req.url} HTTP/${req.httpVersion}\r\n`;
    const headers = Object.entries(req.headers)
      .map(([k, v]) => `${k}: ${v}`)
      .join("\r\n");
    conn.write(reqLine + headers + "\r\n\r\n");
    if (head.length) conn.write(head);
    conn.pipe(socket);
    socket.pipe(conn);
  });

  conn.on("error", () => socket.destroy());
  socket.on("error", () => conn.destroy());
});

server.listen(LISTEN_PORT, "0.0.0.0", () => {
  console.log(`[proxy] AI Town proxy listening on port ${LISTEN_PORT}`);
  console.log(`[proxy] /api/* -> Convex :${CONVEX_PORT}`);
  console.log(`[proxy] /*     -> Vite   :${VITE_PORT}`);
});
