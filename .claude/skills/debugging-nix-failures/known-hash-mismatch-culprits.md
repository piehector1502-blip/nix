# Fixed-output hash mismatches

`error: hash mismatch in fixed-output derivation ...` almost always means
upstream content at a pinned URL changed, not a config bug.

## Check this file first

It fetches un-versioned "latest" endpoints with no version pin in the URL,
so it drifts whenever upstream publishes an update:

- `modules/nixos/programs/vicinae.nix` - sources extensions from the
  `vicinae`/`vicinae-extensions` flake inputs and `mkRayCastExtension`
  (pinned via `raycastRev`), not a `fetchurl` in this file itself. If the
  failing derivation traces here, the actual hash pin lives inside those
  flake inputs (or bump `raycastRev`/the flake input), not in this repo
  file directly.

Match the failing derivation name/path from the error against this file
first.

## If it's not that file

This is a starting point, not the full search. If the failing store path
doesn't trace back to that file, do **not** stop or guess:

- `grep -rn "fetchurl\|fetchzip\|fetchFromGitHub\|hash = \"sha256-"` scoped
  near the failing derivation name, or
- ask `nix-debugger` to trace the derivation graph

until the actual fixed-output fetch responsible is found. Never report "not
vicinae, giving up" as a terminal answer.

## Regenerating the correct hash - use `nurl`

Once the offending `fetchurl`/`fetchzip`/etc. call is identified, `nurl` (see
`.claude/agents/nix-config-architect.md`) regenerates the hash directly
instead of hand-editing and re-running a dry-build to read the "got:" value
off an error:

```bash
nurl -f fetchurl -H '<the exact url from the fetcher call>'
# or, if nurl isn't installed:
nix run nixpkgs#nurl -- -f fetchurl -H '<url>'
```

`-f fetchurl` forces the plain-URL fetcher (nurl otherwise tries to infer a
VCS fetcher from the host); `-H` prints just the hash. nurl has no "diff
against the old pin" mode - it always recomputes from scratch, which is
exactly what's needed here. Paste the printed hash into the `hash = "..."`
field nix-debugger identified, then continue the reverify loop as normal.
