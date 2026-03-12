const sourceUrl = process.env.MISSLESS_TEST_SOURCE_URL;
const scenario = process.env.MISSLESS_TEST_FETCH_SCENARIO;

if (sourceUrl !== undefined && scenario !== undefined) {
  const originalFetch = globalThis.fetch.bind(globalThis);

  globalThis.fetch = async (input, init) => {
    const request = new Request(input, init);

    if (request.url !== sourceUrl) {
      return originalFetch(input, init);
    }

    switch (scenario) {
      case "happy-path":
        return new Response(null, {
          status: 200
        });
      case "fallback-direct-origin": {
        const accept = request.headers.get("accept") ?? "";

        if (!accept.includes("text/html")) {
          return new Response(null, {
            status: 200
          });
        }

        return new Response(
          [
            "<!doctype html>",
            "<html>",
            "<head><title>Fallback Article</title></head>",
            "<body>",
            "<article>",
            "<h1>Fallback Article</h1>",
            "<p>Recovered from origin.</p>",
            "</article>",
            "</body>",
            "</html>"
          ].join(""),
          {
            status: 200,
            headers: {
              "content-type": "text/html; charset=utf-8"
            }
          }
        );
      }
      case "redirect-preflight-blocked":
        return new Response(null, {
          status: 302,
          headers: {
            location: "http://127.0.0.1/private"
          }
        });
      default:
        return originalFetch(input, init);
    }
  };
}
