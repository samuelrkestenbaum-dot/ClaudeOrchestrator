#!/usr/bin/env node
// EXP-0013 sealed arm orders + commitment.
//
//   generate — draw the balanced arm order (exactly 2 of the 4 measured pairs
//              run lean_rules first, the other 2 lean_skills first; the 2-subset
//              is drawn with crypto.randomBytes), write the orders + salts to a
//              sealed store OUTSIDE the repository, and write only the
//              COMMITMENT (sha256 over salt|canonical-orders) into the repo.
//   verify   — recompute the commitment from the sealed store and compare to
//              the committed hash; report tamper/absence honestly.
//
// The sealed store lives outside the repo so no push can ever ship it. It
// dies with the container: if it is absent at spend time, the ONLY honest
// move is a fresh draw + fresh commitment BEFORE any worker launch, disclosed
// in the run record — never a reconstructed mapping.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, "..");
export const SEALED_DIR = process.env.EXP0013_SEALED_DIR || "/home/user/.exp0013-sealed";
export const COMMIT_FILE = path.join(ROOT, "corpus", "ARM-ORDER-COMMITMENT.json");

export const PAIRS = ["S1.p2", "S1.p3", "S2.p2", "S2.p3"];
const A = "lean_rules", B = "lean_skills";

export function drawOrders(randomByte = () => crypto.randomBytes(1)[0]) {
  // Choose which 2 of the 4 pairs run lean_rules first: one of C(4,2)=6 subsets,
  // drawn uniformly by rejection sampling on a single byte.
  const subsets = [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]];
  let b;
  do { b = randomByte(); } while (b >= 252); // 252 = 6*42 — uniform over 0..251
  const first = new Set(subsets[b % 6]);
  const orders = {};
  PAIRS.forEach((p, i) => {
    const [seq, pos] = p.split(".p");
    ((orders[seq] ??= {})[Number(pos)] = first.has(i) ? [A, B] : [B, A]);
  });
  return orders;
}

export function canonical(orders) {
  return JSON.stringify(Object.keys(orders).sort().map((s) => [s, Object.keys(orders[s]).sort().map((p) => [p, orders[s][p]])]));
}

export function commitment(salt, orders) { return sha(`${salt}|${canonical(orders)}`); }

export function generate({ sealedDir = SEALED_DIR, commitFile = COMMIT_FILE } = {}) {
  if (fs.existsSync(path.join(sealedDir, "orders.json")))
    return { ok: false, reason: "SEALED_ORDERS_ALREADY_EXIST — refuse to overwrite a live seal; delete deliberately first" };
  const orders = drawOrders();
  const orderSalt = crypto.randomBytes(32).toString("hex");
  const blindingSalt = crypto.randomBytes(32).toString("hex");
  fs.mkdirSync(sealedDir, { recursive: true, mode: 0o700 });
  fs.writeFileSync(path.join(sealedDir, "orders.json"),
    JSON.stringify({ artifact: "exp0013_sealed_orders", orders, order_salt: orderSalt, blinding_salt: blindingSalt }, null, 2) + "\n",
    { mode: 0o600 });
  const abCount = PAIRS.filter((p) => { const [s, pos] = p.split(".p"); return orders[s][Number(pos)][0] === A; }).length;
  fs.writeFileSync(commitFile, JSON.stringify({
    artifact: "exp0013_arm_order_commitment",
    scheme: "sha256(order_salt | canonical(orders)); order_salt and orders sealed OUTSIDE the repository",
    sealed_store: "outside repo (path intentionally environment-local); dies with the container — absence at spend time forces a fresh disclosed draw + fresh commitment BEFORE any launch",
    balance: `${abCount} pairs lean_rules-first / ${PAIRS.length - abCount} pairs lean_skills-first (enforced by construction)`,
    pairs: PAIRS,
    commitment: commitment(orderSalt, orders),
  }, null, 2) + "\n");
  return { ok: true, balance: [abCount, PAIRS.length - abCount] };
}

export function verify({ sealedDir = SEALED_DIR, commitFile = COMMIT_FILE } = {}) {
  if (!fs.existsSync(commitFile)) return { ok: false, reason: "NO_COMMITMENT_FILE" };
  const c = JSON.parse(fs.readFileSync(commitFile, "utf8"));
  const sealedPath = path.join(sealedDir, "orders.json");
  if (!fs.existsSync(sealedPath)) return { ok: false, reason: "SEALED_STORE_ABSENT — container reclaimed or never generated; a fresh disclosed draw is required before spend" };
  const s = JSON.parse(fs.readFileSync(sealedPath, "utf8"));
  const now = commitment(s.order_salt, s.orders);
  if (now !== c.commitment) return { ok: false, reason: "COMMITMENT_MISMATCH — sealed orders do not match the committed hash" };
  const abCount = PAIRS.filter((p) => { const [seq, pos] = p.split(".p"); return s.orders[seq]?.[Number(pos)]?.[0] === A; }).length;
  if (abCount !== 2) return { ok: false, reason: `BALANCE_VIOLATION: ${abCount}/4 lean_rules-first` };
  return { ok: true, orders: s.orders, blinding_salt: s.blinding_salt };
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
  const mode = process.argv[2];
  if (mode === "generate") { const r = generate(); console.log(JSON.stringify(r)); process.exit(r.ok ? 0 : 1); }
  else if (mode === "verify") { const r = verify(); console.log(JSON.stringify({ ok: r.ok, reason: r.reason ?? null })); process.exit(r.ok ? 0 : 1); }
  else { console.log("usage: seal-orders.mjs generate|verify"); process.exit(1); }
}
