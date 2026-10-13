# Binary cache strategy (Cachix + GitHub Actions)

This document explains the "build once, download everywhere" strategy. GitHub Actions compiles the system in the cloud and uploads the result to **Cachix**; your laptop then downloads the finished binaries instead of compiling them, saving time, heat and battery.

- One architecture is built in CI: **`x86_64-linux`** (`nixos-laptop`, in `build.yml`). It pushes to the `pierre-nixos` cache.
- **`aarch64-linux` is not built** in CI; it is only evaluation-tested.

> For how the CI workflows themselves work (what each job does, why the Nix settings differ, how the push layers work, and the incident log behind the current design), see [`../ci/build-workflows.md`](../ci/build-workflows.md).

## 1. Factory vs. warehouse

1. **The factory (GitHub Actions):** compiles the code in the cloud.
2. **The warehouse (Cachix):** stores the finished binaries.
3. **The customer (your laptop):** downloads the finished product.

## 2. Roles

### The cloud (GitHub Actions)

- **Trigger:** `push` on `develop` and `main`, any pull request, a weekly schedule (`0 5 * * 5`, Fridays 05:00 UTC), and manual `workflow_dispatch`. Pushing a feature branch with no PR open does *not* start a build.
- Builds the `x86_64-linux` host `nixos-laptop` natively (`build.yml`) and pushes to Cachix.

### The laptop

- **Pull:** enabled (`cachix.enable = true` in `hosts/nixos-laptop/default.nix`).
- **Push:** disabled (`cachix.push = false`). Pushing needs a Cachix auth token (`cachix.authTokenPath`), which this repo does not provision.
- **Goal:** zero compilation in normal use. If the laptop starts compiling `webkit` or `gcc`, something is wrong.

## 3. The happy path

1. Edit and commit.
2. `git push`.
3. Wait for the GitHub Actions run to finish (roughly 15-20 minutes when warm; much longer when `flake.lock` changed, because the store-cache key includes its hash). Timeouts are bounded rather than generous because a timeout is not data loss here: `cachix watch-exec` has already uploaded whatever was built, so the next run resumes further along.
4. Run `nh os switch` (`sw`) on the laptop. Nix sees the paths in Cachix and downloads them.

## 4. Technical implementation

### The automation (`.github/workflows/build.yml`)

- **Concurrency:** it cancels older runs of the same workflow on the same ref. This is a genuine trade-off: a cancelled run can lose a long build *and* skip its salvage push. Avoid pushing again while a build you care about is in flight.
- **The cache loop:** it pulls from Cachix before starting and pushes **continuously during the build** via `cachix watch-exec`, not only at the end. It also pushes when the build *fails*.
- **Split by host:** the build matrix has one entry per x86_64 host (currently only `nixos-laptop`), one per runner, all on `ubuntu-latest`.

### The system logic (`modules/nixos/toplevel/cachix.nix`)

This module configures the machine to use the cache as a substituter.

- **Manual push alias:** when `cachix.push = true`, the rebuild aliases (`wrapCaches` in `modules/nixos/programs/shells/shell-aliases.nix`) also pipe `nix path-info -r /run/current-system` into `cachix push`, each suffixed with `|| true` so an unreachable cache never fails a rebuild, and a `cachix-push` alias is available to share the current system closure immediately.

## 5. FAQ

### My laptop is compiling (cache miss)

If you see your laptop building `firefox`, `gcc` or `linux-kernel`, stop (Ctrl+C) and check:

1. GitHub Actions has not finished yet.
2. You made local changes that were never pushed.
3. You are building from a dirty git tree that does not match what is in the cache.

### What if I push to the same branch twice?

`cancel-in-progress: true` kills the now-obsolete build and starts the new one. Two caveats: GitHub's queue can be slow, so be patient before assuming something is broken; and cancelling is not free - a cancelled run can lose everything it had left to do, including its salvage push. What it already built is usually safe because `watch-exec` uploads paths as they are produced, but if a build matters, let it finish.
