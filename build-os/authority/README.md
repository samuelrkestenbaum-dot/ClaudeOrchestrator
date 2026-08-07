# Publication authority — local state

`publish-authorization.json` is **deliberately untracked**. It records an
operator's content authorisation for one specific push tip and is consumed by
`.githooks/pre-push` via `build-os/tools/publish-check.mjs`.

Shape:

```json
{
  "authorized": "<the INTENT the operator approved, not a SHA>",
  "authorized_tip": "<the commit that intent resolves to>",
  "granted_by": "operator",
  "confers_status": false
}
```

Three rules the checker enforces, and why each exists:

- **No record → refuse.** Content authorisation is never self-granted.
- **No `authorized_tip` → refuse.** A record naming no commit would authorise
  every future push simply by continuing to exist.
- **Tip mismatch → refuse as stale.** New work needs its own go; only incidental
  ancestors ride along.

`confers_status: true` marks a publication that itself effects a state
transition (draft → frozen, proposed → approved). Those always need their own
authorisation and are refused by default.
