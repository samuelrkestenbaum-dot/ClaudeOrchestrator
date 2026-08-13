#!/usr/bin/env node
// SEALED-MAPPING ESCROW (AMENDMENT v3 — mapping durability without reveal).
//
// Audit finding this answers: the sealed order/blinding store lives only in
// this container. The audit ALSO established (executed evidence: cell
// records and delivery receipts carry arm identity) that post-launch
// analyzability does NOT depend on the sealed store — what dies with the
// container is the ability to PROVE the precommitment. This module makes
// that proof durable: the sealed store is encrypted (scrypt KDF ->
// AES-256-GCM) into a ciphertext file that is safe to COMMIT AND PUSH; the
// passphrase is the owner's and only the owner's. Nothing here transmits
// anything anywhere; wrong key and tampered ciphertext are typed refusals
// (GCM authentication), tested against SYNTHETIC mappings only.
//
// Custody statement (honest): this code cannot guarantee availability — the
// owner must store the passphrase outside this container. Until the owner
// confirms custody, escrow durability is OFFERED, not GUARANTEED, and the
// spend-authorization template names the handoff as a prerequisite.
import fs from "node:fs";
import crypto from "node:crypto";

export function escrowCreate({ sealedPath, passphrase, outFile }) {
  if (!passphrase || passphrase.length < 12) return { ok: false, reason: "ESCROW_PASSPHRASE_TOO_SHORT" };
  const plain = fs.readFileSync(sealedPath);
  const salt = crypto.randomBytes(16);
  const key = crypto.scryptSync(passphrase, salt, 32, { N: 16384, r: 8, p: 1 });
  const iv = crypto.randomBytes(12);
  const c = crypto.createCipheriv("aes-256-gcm", key, iv);
  const ct = Buffer.concat([c.update(plain), c.final()]);
  fs.writeFileSync(outFile, JSON.stringify({
    artifact: "exp0013_mapping_escrow", kdf: "scrypt/16384/8/1", cipher: "aes-256-gcm",
    salt: salt.toString("hex"), iv: iv.toString("hex"), tag: c.getAuthTag().toString("hex"),
    ct: ct.toString("base64"),
    note: "ciphertext only — safe to commit; passphrase is owner-held and never stored",
  }, null, 2) + "\n");
  return { ok: true };
}

export function escrowRecover({ escrowFile, passphrase, outPath }) {
  let e;
  try { e = JSON.parse(fs.readFileSync(escrowFile, "utf8")); } catch { return { ok: false, reason: "ESCROW_FILE_MALFORMED" }; }
  try {
    const key = crypto.scryptSync(passphrase, Buffer.from(e.salt, "hex"), 32, { N: 16384, r: 8, p: 1 });
    const d = crypto.createDecipheriv("aes-256-gcm", key, Buffer.from(e.iv, "hex"));
    d.setAuthTag(Buffer.from(e.tag, "hex"));
    const plain = Buffer.concat([d.update(Buffer.from(e.ct, "base64")), d.final()]);
    if (outPath) fs.writeFileSync(outPath, plain, { mode: 0o600 });
    return { ok: true, bytes: plain.length };
  } catch {
    return { ok: false, reason: "ESCROW_WRONG_KEY_OR_TAMPERED" };
  }
}
