import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { fetchNormalizeSource } from "../../../packages/core/src/index.ts";

test("fetchNormalizeSource rejects source URLs with embedded credentials", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "https://user:pass@example.com/private",
        runsDir
      }),
    /embedded credentials/
  );
});

test("fetchNormalizeSource rejects localhost and private IPv4 hosts", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://127.0.0.1/private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://localhost/private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );
});

test("fetchNormalizeSource rejects loopback IPv6 hosts", async () => {
  const runsDir = await mkdtemp(join(tmpdir(), "missless-fetch-sec-"));

  await assert.rejects(
    () =>
      fetchNormalizeSource({
        sourceUrl: "http://[::1]/private",
        runsDir
      }),
    /localhost, private, link-local, and single-label hosts/
  );
});
