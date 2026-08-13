#!/usr/bin/env node
// PURE provider argv/request construction (AMENDMENT v4). No imports at all:
// building the TEXT of a provider request is capability-free — rehearsal
// uses it for semantic request digests, the sole call site uses it for the
// real spawn. Nothing here can execute anything.

export function buildProviderArgv(config, uuid) {
  return config.invocation.argv.map((a) =>
    a === "<model.requested>" ? config.model.requested : a === "<per-cell uuid>" ? uuid : a);
}
