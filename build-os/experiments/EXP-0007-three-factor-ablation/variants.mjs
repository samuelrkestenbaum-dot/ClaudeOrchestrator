// EXP-0007 — the substrate variants, as ENUMERATED REVERSIBLE TRANSFORMS.
//
// Every transform states the factor it targets and the MEASURED quantity it
// attacks. A transform without a measurement behind it is a guess wearing a
// config flag.
//
// The measurements, taken from the frozen EXP-0006 streams over T01–T04:
//   · gravito tool_result volume 2,550 chars/turn vs native 1,674 (1.52×) —
//     essentially the whole context factor;
//   · 17 gate refusals emitted 107,278 chars, 23.8% of gravito's ENTIRE
//     tool_result volume, at ~6.3 KB each;
//   · native emitted 0 hook results, which is what makes the attribution clean.
//
// NOTHING HERE REMOVES A BEHAVIOUR. Authority, persistence, capability
// exhaustion, continuation, prioritisation, evidence and recovery are all still
// administered. What changes is WHERE they happen: the receipt still exists, it
// is just issued mechanically rather than negotiated in dialogue; the gate still
// refuses, it just says so in one line instead of sixty; the doctrine still
// governs, it is just retrievable instead of resident.
//
// A variant that drops a behaviour is a FAILED variant, not a cheap one.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";

// `native` is the ABSENCE of the substrate, run through THIS harness rather than
// EXP-0006's. The header's old claim that "the native arm is NEVER run here" held
// while every comparison was gravito-vs-gravito. The runnable-verification study
// is a 2x2 -- {native, gravito} x {starved, runnable} -- and a native cell
// measured by a different harness in a different ARM_TREE would confound the one
// contrast the study exists to isolate. EXP-0006's native arms remain the frozen
// reference and are untouched; this reproduces the condition, it does not replace it.
export const CONFIGS = ["baseline", "A", "B", "C", "ABC", "microcontext", "corrected", "native"];

// `corrected` is BASELINE with no lean changes at all -- identical doctrine,
// identical gate, identical controls. The only difference is that
// administration now withholds session-local state, which the contaminated
// baseline did not. It is a separate config name so the contaminated runs stay
// on disk for comparison instead of being overwritten: the whole question is
// how the two differ.

// Where the ACTION STATE wrapper is sourced from. Resolved relative to THIS
// file rather than imported from substrate.mjs, so a variant cannot silently
// depend on the administration module's notion of a code root.
const ORCHESTRATOR_ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../../..");

const has = (cfg, f) => cfg === "ABC" || cfg === f;

// ---------------------------------------------------------------------------
// FACTOR A — step tax. Target: 1.45× turns on the screening subset.
//
// The gate blocks Bash categorically until an open routing receipt exists, and
// the worker discovers this by being refused, then works around it. Those are
// dialogue turns spent negotiating with the substrate rather than solving the
// task. The receipt is DETERMINISTIC — nothing about it requires a model in the
// loop — so it is issued mechanically before the arm starts.
//
// The control is preserved exactly: a receipt still governs the work, and the
// gate still enforces that one exists. Only the negotiation is gone.
function applyA(tree, acts) {
  const rdir = path.join(tree, "build-os/packets/routing");
  fs.mkdirSync(rdir, { recursive: true });
  const id = "EXP0007-screening";
  fs.writeFileSync(path.join(rdir, `routing-${id}.md`), [
    `# Routing receipt — ${id}`, "",
    "- **status:** open",
    "- **mode:** direct",
    "- **lane:** tiny",
    "- **task:** single-file TypeScript type repair",
    "- **issued_by:** EXP-0007 harness, mechanically, before the arm started",
    "",
    "Issued OUTSIDE the conversational loop on purpose. The receipt is a",
    "deterministic control record; requiring the worker to negotiate one with a",
    "gate spends dialogue turns on bookkeeping a machine can do.",
  ].join("\n"));
  acts.push({ factor: "A", act: "pre_issue_routing_receipt", detail: `open receipt ${id}, so Bash is permitted without a refusal round-trip` });
}

// ---------------------------------------------------------------------------
// FACTOR B — context tax. Target: 1.46× context/turn on the screening subset.
//
// Two measured contributors:
//   B1  doctrine resident in every turn's payload;
//   B2  gate refusals at ~6.3 KB each, 23.8% of all tool_result volume.
//
// B1 replaces the resident doctrine with a pointer plus a retrieval instruction.
// The doctrine file is STILL PRESENT and still authoritative — it is read when
// needed rather than carried always.
//
// B2 wraps the gate so its refusal is one line. The refusal still happens, still
// blocks, still names the reason; it stops reprinting the contract each time.
function applyB(tree, acts) {
  const full = path.join(tree, "CLAUDE.md");
  if (fs.existsSync(full)) {
    fs.mkdirSync(path.join(tree, "build-os/memory"), { recursive: true });
    const doctrinePath = path.join(tree, "build-os/memory/doctrine.md");
    if (!fs.existsSync(doctrinePath)) fs.copyFileSync(full, doctrinePath);
    fs.writeFileSync(full, SLIM_CLAUDE_MD);
    acts.push({ factor: "B", act: "doctrine_on_demand", detail: "CLAUDE.md becomes a pointer; the full doctrine moves to build-os/memory/doctrine.md, still authoritative, read when needed" });
  }

  const gate = path.join(tree, ".claude/hooks/routing-gate.sh");
  const fullGate = path.join(tree, ".claude/hooks/routing-gate-full.sh");
  if (fs.existsSync(gate) && !fs.existsSync(fullGate)) {
    fs.renameSync(gate, fullGate);
    fs.writeFileSync(gate, TERSE_GATE, { mode: 0o755 });
    acts.push({ factor: "B", act: "terse_gate_output", detail: "the gate still refuses and still names the reason; it stops reprinting the contract at ~6.3 KB per refusal" });
  }

  const settings = path.join(tree, ".claude/settings.json");
  if (fs.existsSync(settings)) {
    try {
      const s = JSON.parse(fs.readFileSync(settings, "utf8"));
      if (s.hooks?.SessionStart) { delete s.hooks.SessionStart; fs.writeFileSync(settings, JSON.stringify(s, null, 2));
        acts.push({ factor: "B", act: "no_session_start_injection", detail: "session context is retrieved on demand rather than injected at start" }); }
    } catch {}
  }
}

// ---------------------------------------------------------------------------
// FACTOR C — output tax. Target: 1.60× output/turn on the screening subset.
//
// Lane announcements, tool-budget declarations and depth accounting are model
// PROSE that exists to satisfy the protocol, not to solve the task. The protocol
// still holds — the harness records lane and budget mechanically in the receipt
// — but the worker stops narrating it.
function applyC(tree, acts) {
  const f = path.join(tree, "CLAUDE.md");
  if (!fs.existsSync(f)) return;
  let src = fs.readFileSync(f, "utf8");

  // NEUTRALISE THE DEMANDS IN THE BODY, don't just contradict them at the end.
  //
  // Caught on the pre-flight dry run, before any compute was spent: appending
  // "do not announce a lane" to a doctrine whose body says "Classify and
  // announce the LANE — one line, before anything else" leaves ONE DOCUMENT
  // GIVING TWO OPPOSITE INSTRUCTIONS. Whichever the worker followed, variant C
  // would not be measuring the output tax — it would be measuring which of two
  // contradictory sentences a model happens to obey.
  //
  // So the announcement REQUIREMENTS are rewritten to their silent equivalents.
  // The protocol is untouched: classification still happens, the budget is
  // still fixed, depth is still bounded. Only the demand to say so is removed.
  const rewrites = [
    [/\*\*Classify and announce the LANE\*\*[^\n]*\n(?:[^\n]*\n)*?(?=\d\.\s|\n##)/,
     "**Classify the LANE** silently. Do not announce it; the substrate records it.\n"],
    [/\*\*Announce\*\* it on one line:[^\n]*\n/g, "Do not announce it. The substrate records the budget.\n"],
    [/`Lane: tiny — one-line comment fix, 1 check, no gates`\./g, "(recorded, not stated)."],
    [/Announce it as\s*\n?`Depth: \d[^`]*`[^.]*\./g, "Record it; do not state it."],
    [/\bannounce\b/gi, "record"],
  ];
  for (const [re, to] of rewrites) src = src.replace(re, to);

  fs.writeFileSync(f, src + "\n" + QUIET_ADDENDUM);
  acts.push({ factor: "C", act: "silent_protocol_state", detail: "announcement requirements rewritten to their silent equivalents in the body, then the silent-state rule appended — no contradictory instruction survives" });
}

/** Apply a configuration to an already-administered gravito arm tree. */
// EXP-0008 MICROCONTEXT. The measured target: across 28 gravito arms the worker
// read 31,000-49,000 chars of Gravito's own implementation per arm, 33-45% of
// all read volume, against native's ZERO. routing-gate.sh alone is ~half.
//
// The gate refuses by naming a CONDITION; the worker needs an ACTION, so it
// opens 47 KB of shell to derive one fact the gate already knew. This installs
// a wrapper that derives the next action and emits it in ~61 tokens. The real
// gate still decides -- it is renamed, not replaced.
//
// NOT variant B. B handed out a pointer and let the worker fetch; this emits no
// path to read and no invitation to explore.
function applyMicrocontext(tree, acts) {
  // PREPEND, do not rename. The first attempt renamed the gate and thereby
  // created routing-gate-real.sh -- an implementation file the baseline never
  // had -- which the worker promptly read for 8,090 chars. A treatment that
  // manufactures new implementation surface cannot measure the removal of
  // implementation surface.
  const gate = path.join(tree, ".claude/hooks/routing-gate.sh");
  if (!fs.existsSync(gate)) return;
  const src = fs.readFileSync(gate, "utf8");
  if (src.includes("GRAVITO ACTION STATE")) return;
  const shim = fs.readFileSync(path.join(ORCHESTRATOR_ROOT, "build-os/experiments/EXP-0008-microcontext/shim.sh"), "utf8");
  const lines = src.split("\n");
  const shebang = lines[0].startsWith("#!") ? lines.shift() + "\n" : "";
  fs.writeFileSync(gate, shebang + shim + "\n" + lines.join("\n"), { mode: 0o755 });
  acts.push({ factor: "microcontext", act: "action_state_shim_in_place",
    detail: "prepended into the existing gate; no new file, no pointer, the complete receipt text inline, tool name from stdin" });
}

export function applyVariant(tree, config) {
  if (!CONFIGS.includes(config)) throw new Error(`unknown config '${config}'`);
  const acts = [];
  // No transform: the substrate is absent, so there is nothing to vary. The
  // absence itself is administered upstream by substrate.mjs.
  if (config === "native") return { config, acts, baseline: false, native: true };
  if (config === "microcontext") { applyMicrocontext(tree, acts); return { config, acts, baseline: false }; }
  if (config === "corrected") return { config, acts, baseline: true };
  if (has(config, "A")) applyA(tree, acts);
  if (has(config, "B")) applyB(tree, acts);
  if (has(config, "C")) applyC(tree, acts);
  return { config, acts, baseline: config === "baseline" };
}

/**
 * Verify the variant took, and that no BEHAVIOUR was dropped. A cheap arm that
 * lost a control is a failed arm — this is the check that tells them apart.
 */
export function verifyVariant(tree, config) {
  const checks = [];
  const ck = (n, ok, d) => { checks.push({ name: n, ok, detail: d }); return ok; };

  // Behaviours that must survive EVERY GRAVITO configuration.
  const required = [
    "build-os/motion/continuation.mjs", "build-os/motion/objective.mjs",
    "build-os/assumptions/authority-selector.mjs", ".claude/hooks/routing-gate.sh",
    "build-os/memory/tool_router.md", "CLAUDE.md",
  ];

  // The native cell inverts the check. Asserting "behaviours preserved" against
  // an arm whose whole definition is their absence would pass only by accident,
  // and would pass just as happily on a gravito arm that failed to administer.
  if (config === "native") {
    const present = ["build-os", ".claude", "CLAUDE.md"].filter((p) => fs.existsSync(path.join(tree, p)));
    ck("native.substrate_absent", present.length === 0,
      present.length ? `STILL PRESENT: ${present.join(", ")}` : "build-os, .claude and CLAUDE.md are all absent");
    ck("native.no_variant_applied", true, "no transform is defined for the absence of the substrate");
    return { ok: checks.every((c) => c.ok), checks };
  }
  const missing = required.filter((p) => !fs.existsSync(path.join(tree, p)));
  ck("behaviours_preserved", missing.length === 0, missing.length ? `MISSING: ${missing.join(", ")}` : `${required.length} load-bearing paths intact`);

  if (has(config, "A")) {
    const r = path.join(tree, "build-os/packets/routing");
    const open = fs.existsSync(r) && fs.readdirSync(r).some((f) => f.startsWith("routing-EXP0007"));
    ck("A.receipt_pre_issued", open, open ? "an open receipt exists before the arm starts" : "no pre-issued receipt");
  }
  if (has(config, "B")) {
    const slim = fs.readFileSync(path.join(tree, "CLAUDE.md"), "utf8");
    ck("B.doctrine_is_a_pointer", slim.length < 3000, `CLAUDE.md is ${slim.length} bytes`);
    ck("B.doctrine_still_reachable", fs.existsSync(path.join(tree, "build-os/memory/doctrine.md")),
      "the full doctrine is still present and authoritative, just not resident");
    ck("B.gate_still_present", fs.existsSync(path.join(tree, ".claude/hooks/routing-gate-full.sh")),
      "the real gate is intact behind the terse wrapper — refusals still refuse");
  }
  if (has(config, "C")) {
    const cm = fs.readFileSync(path.join(tree, "CLAUDE.md"), "utf8");
    ck("C.narration_silenced", /do not narrate/i.test(cm), "the doctrine instructs silent protocol state");
    // THE CHECK THAT MAKES C A MEASUREMENT. A doctrine still demanding an
    // announcement while also forbidding one measures nothing but which
    // sentence the model obeyed.
    const contradictions = [/announce the LANE/i, /\*\*Announce\*\* it on one line/i, /Announce it as/i]
      .filter((re) => re.test(cm));
    ck("C.no_contradictory_announce_requirement", contradictions.length === 0,
      contradictions.length ? `doctrine still DEMANDS an announcement it also forbids: ${contradictions.map(String).join(", ")}`
        : "no surviving instruction demands the narration the addendum forbids");
  }
  if (config === "microcontext") {
    const hooks = fs.readdirSync(path.join(tree, ".claude/hooks"));
    ck("mc.no_new_implementation_file", !hooks.some((f) => /routing-gate-(real|full)\.sh/.test(f)),
      `hooks: ${hooks.join(", ")} — the treatment must not manufacture surface it is measuring the removal of`);
    const real = true;
    const w = real ? fs.readFileSync(path.join(tree, ".claude/hooks/routing-gate.sh"), "utf8") : "";
    ck("mc.wrapper_installed", /GRAVITO ACTION STATE/.test(w), "the wrapper emits derived state");

    // THE CHECK THAT DISTINGUISHES THIS FROM VARIANT B: no pointer may survive
    // into the payload THE WORKER RECEIVES.
    //
    // The first version scanned the wrapper's SOURCE and failed on its own
    // comment -- which contains the words `for details` precisely because it is
    // explaining that the payload must not contain them. That is the fourth
    // self-matching detector in this session: a content pattern applied to a
    // file that talks about the pattern. So this EXECUTES the wrapper against a
    // simulated refusal and inspects the emitted payload. Measure the artifact,
    // never the implementation that produces it -- the same correction the read
    // classifier needed.
    let payload = "", ranOk = false;
    try {
      const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "mc-probe-"));
      const fake = path.join(tmp, "fake-gate.sh");
      fs.writeFileSync(fake, "#!/usr/bin/env bash\necho 'routing-gate: MUTATION BLOCKED — NO OPEN routing receipt exists' >&2\nexit 2\n", { mode: 0o755 });
      payload = execFileSync("bash", [path.join(tree, ".claude/hooks/routing-gate.sh"), "mutgate", "Bash"],
        { encoding: "utf8", input: JSON.stringify({ tool_name: "Bash" }), env: { ...process.env, CLAUDE_PROJECT_DIR: tmp }, stdio: ["pipe", "pipe", "pipe"] });
      ranOk = true;
    } catch (e) { payload = String(e.stderr || e.stdout || ""); ranOk = payload.includes("GRAVITO ACTION STATE"); fs.rmSync; }
    ck("mc.payload_emitted", ranOk && /GRAVITO ACTION STATE/.test(payload), payload.slice(0, 120).replace(/\n/g, " | "));
    ck("mc.no_pointer_in_payload", ranOk && !/\bsee \S+\.(sh|mjs|json|md)\b|\brefer to\b|\bfor details\b|\bread \S+\.(sh|mjs)\b/i.test(payload),
      "the EMITTED payload sends the worker nowhere to read");
    ck("mc.payload_is_self_contained", ranOk && /content:/.test(payload) && /executed_mode: -/.test(payload),
      "the payload carries the COMPLETE text to write, not a filename to fill in from a schema found elsewhere");
    ck("mc.action_resolved", ranOk && !/action: unknown/.test(payload),
      "the tool name is read from the hook's stdin payload, not from an argv position the hook never uses");
    ck("mc.payload_within_budget", ranOk && payload.length <= 700,
      `${payload.length} chars (~${Math.round(payload.length / 4)} tokens), budget <=700 chars`);
  }
  if (config === "corrected") {
    const cm = fs.readFileSync(path.join(tree, "CLAUDE.md"), "utf8");
    ck("corrected.doctrine_unmodified", cm.length > 3000 && !/do not narrate/i.test(cm),
      "no lean change: the corrected baseline differs from the contaminated one ONLY in what administration withheld");
    ck("corrected.gate_unmodified", !/GRAVITO ACTION STATE/.test(fs.readFileSync(path.join(tree, ".claude/hooks/routing-gate.sh"), "utf8")),
      "the gate is the shipped one");
  }
  if (config === "baseline") {
    const cm = fs.readFileSync(path.join(tree, "CLAUDE.md"), "utf8");
    ck("baseline.unmodified", cm.length > 3000 && !/do not narrate/i.test(cm),
      "baseline carries the full unmodified doctrine — it is the anchor, not a variant");
  }
  return { ok: checks.every((c) => c.ok), checks };
}

// ---------------------------------------------------------------------------
const SLIM_CLAUDE_MD = `# CLAUDE.md

This repository runs a Build OS substrate.

**The full doctrine is \`build-os/memory/doctrine.md\`.** It is authoritative.
Read it when a task needs governance — an ambiguous scope, a gate, an external
mutation, an architectural decision. Do not read it for routine work.

**The router is \`build-os/memory/tool_router.md\`.** Consult it when routing is
in question.

Standing rules, which need no lookup:

- **No external mutation without explicit go** — never push, merge, deploy,
  publish, or touch secrets without an explicit go from the user.
- **Design/UI work is frontend only.** Marketing/media work stays in its own
  packets.
- Prefer the cheapest approach that does the job, and escalate only with a
  stated reason.

Everything else is retrievable. Retrieve it when it applies.
`;

const QUIET_ADDENDUM = `
## Protocol state is SILENT

Lane, tool budget and depth are recorded mechanically by the substrate in the
routing receipt. **Do not narrate them.** Do not announce a lane, do not print a
tool budget, do not explain a depth decision, and do not restate governance
rules back before acting on them.

The protocol is unchanged and still binding — its *announcement* is simply not
model output. Spend output tokens on the product task.
`;

const TERSE_GATE = `#!/usr/bin/env bash
# EXP-0007 factor-B wrapper: the gate's DECISION is unchanged, its VOLUME is not.
#
# Measured: 17 refusals emitted 107,278 characters across four EXP-0006 arms —
# 23.8% of all tool_result volume, ~6.3 KB each, because every refusal reprinted
# the contract. The refusal still happens, still blocks, and still names its
# reason; it stops re-teaching the doctrine on every occurrence.
SELF_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
out="$("$SELF_DIR/routing-gate-full.sh" "$@" 2>&1)"; rc=$?
if [ -n "$out" ]; then
  # First line carrying the decision, plus a pointer. Nothing else.
  printf '%s\\n' "$out" | grep -m1 -E 'BLOCKED|REFUS|DENIED|ok|allow' || printf '%s\\n' "$out" | head -1
  printf 'routing-gate: reason above; full contract in build-os/memory/doctrine.md\\n'
fi
exit $rc
`;
