# NixOS Configuration - CLAUDE.md

## ⚠️ Specialized agents exist - use them, not the main loop

This repo has dedicated subagents covering nearly every recurring task: writing config, researching packages/options, verifying builds, debugging failures, linting, and writing tests. **If a task matches one of these agents, delegate to that agent instead of doing the work in the main conversation loop.** This is not optional. The main loop must never itself run package research, `nix flake check`/dry-builds, or failure debugging when an agent exists for it - these are exactly the token-heavy operations that should stay off the main context.

`nix-config-architect` is the hub: it authors/modifies config directly, but for anything with a more specific agent it delegates rather than doing that piece itself. The other agents delegate back to it or to each other in a fixed loop - know these links so you route work correctly instead of picking whichever agent sounds closest:

| Agent | Role | Delegates to | Never does |
|-------|------|---------------|-------------|
| `nix-config-architect` | **Hub / general.** Authors or modifies config: modules, DE/WM enablement, hosts, per-host constants, package/service integration, stylix/catppuccin theming, disko, home-manager. Default for any config-writing task with no more specific agent. | `nix-checker` (verify), `nix-package-researcher` (lookups), `nix-debugger` (diagnose failures), `nix-test-author` (tests), `nix-syntax-linter` (lint sweeps) | Package/option lookups, root-causing failures, running the test suite - hand these off instead of doing them inline. |
| `nix-package-researcher` | Pure read-only lookup: does package/attribute X exist, option paths, channel availability, binary-cache status, version history. | - | Making config changes - always hands findings back to `nix-config-architect`. |
| `nix-checker` | Read-only verification: `nix flake check`, per-host dry-builds, templates/tests suite. Run after any change, or on "verify"/"check the build"/"does it evaluate"/"run flake check"/"dry build"/"run the tests". | `nix-debugger` (on failure needing root-cause), `nix-config-architect` (on failure needing a config fix) | Modifying config or diagnosing *why* something failed - it only reports pass/fail with exact errors. |
| `nix-debugger` | Root-causes a failing build/eval/rebuild: eval errors, type errors, "option does not exist", broken imports, IFD failures, module conflicts, renamed/removed attrs. Diagnoses **and** applies the fix. | `nix-checker` (always re-verifies after fixing) | Leaving a fix unverified - every fix loops back through `nix-checker`. |
| `nix-syntax-linter` | Fast read-only syntax/convention checks, no evaluation: parse errors, formatting drift, denix/repo anti-patterns. | `nix-config-architect` (applies the actual fixes) | Fixing anything itself - it only flags. |
| `nix-test-author` | Writes/improves tests and manages the `run-tests.sh` registry. | `nix-checker` (to actually *run* the suite) | Running the test suite - that's `nix-checker`'s job. |

**Rule of thumb:** before researching a package/option, verifying a build, debugging a failure, linting, or writing tests yourself, ask "is there an agent for this?" If yes, use it - don't do it in the main loop. This holds with no exceptions for the operations the table lists as agent-owned (`nix flake check`, dry-builds, package/option research, failure debugging, lint sweeps, test-suite runs) - there is no "but it's quick" or "but I already have the context" carve-out; a matching agent is always used, even for a single follow-up command after you already diagnosed the issue yourself. Only work directly when NO agent's role matches the operation at all: quick one-line answers, reading a single file to answer a question, or config-writing edits `nix-config-architect` would itself make inline (its own delegated-away pieces still don't count - see its "Never does" column).

## RTK (token optimization)

RTK is active via a `PreToolUse` hook - Bash commands are auto-rewritten (e.g. `git status` → `rtk git status`).
The hook does **not** cover built-in `Read`/`Grep`/`Glob` tools. Prefer shell equivalents (`cat`, `grep`, `find`) over built-in tools when the output would benefit from filtering, so RTK can intercept it.

## Overview

This repo manages a NixOS host (`nixos-laptop`) using the [denix](https://github.com/yunfachi/denix) framework. Denix auto-discovers all `.nix` files under the configured `paths` (see `flake.nix`), then wires them together via `delib.module` and `delib.host`.

Nixpkgs channel: `nixos-26.05` (home-manager, stylix and catppuccin follow `release-26.05`). Home-manager user: `pierre`. Installed with disko (`hosts/nixos-laptop/disko-config-btrfs.nix`); `hosts/nixos-laptop/hardware-configuration.nix` is a temporary stub that the person installing replaces with their own `nixos-generate-config --no-filesystems` output.

## 🏭 CI build workflows - read the doc before touching them

`Documentation/usage/ci/build-workflows.md` is the reference for
`.github/workflows/build.yml`: what they do, the priority
order of their goals, and - most importantly - **why** each odd-looking decision
is there, with the incident that caused it.

**Read it before changing, debugging, or reasoning about a build workflow.**
Several decisions look like bugs and are not: `pushed=0` is the normal result of a healthy warm
run, and `always()` deliberately does not protect the case you probably think it
does. Every one of those has been re-derived from scratch at least once because
the reasoning lived only in a commit message.

Treat it as a map, not as gospel - verify against the file before acting, and
update the doc in the same commit when you invalidate part of it.

`.github/scripts/check-workflow-invariants.py` enforces the subset of this that
can be checked mechanically; run it after any workflow edit.

## ⛔ `stateVersion` is NEVER bumped after install

`system.stateVersion`, `home.stateVersion`, and the `myconfig.constants.homeStateVersion` / `stateVersion` defaults are **frozen at `"26.05"`**, the release this config is installed under (a fresh install). Once the system is installed, **do not change these values** - not when bumping nixpkgs channels, not when "modernizing". No exceptions, no search-and-replace.

`stateVersion` is *not* a "current channel" marker (that's `config.system.nixos.release`, read-only). It is a backward-compatibility contract that pins the **defaults of stateful modules** to the release at install time. Bumping it silently changes runtime behavior. Concrete hazards:

- **PostgreSQL major version**: `services.postgresql.package` is defaulted from stateVersion. A bump swaps Postgres majors at the next rebuild; the on-disk cluster in `/var/lib/postgresql/<old>/` is incompatible with the new binary and the service refuses to start until you manually run `pg_upgrade`. Same trap historically for MySQL/MariaDB defaults.
- **Home-manager program defaults**: many home-manager defaults (e.g. `gtk.gtk4.theme`, `programs.yazi.shellWrapperName`, `wayland.windowManager.hyprland.configType`, `programs.neovim.withRuby`/`withPython3`, `xdg.userDirs.setSessionVariables`) are gated on `home.stateVersion` being below a release cutoff. Bumping `home.stateVersion` would flip **all of them simultaneously with no warning**, with no straightforward way to flip them back.
- **systemd-tmpfiles, /etc, /var layouts, ZFS/Btrfs pool feature flags**: various modules migrate state or change file ownership only when stateVersion crosses a cutoff. Those migrations are one-way.
- **It is one-way.** Reverting the value does NOT undo any migration that already ran.

The NixOS manual is explicit on this - `options.system.stateVersion` description: "Most users should never change this value after the initial install." Same warning lives in the home-manager manual for `home.stateVersion`.

If you genuinely need to adopt a newer default later, do it **one option at a time, explicitly**, in the Nix code (host or module). Never by touching stateVersion. (There is a single host, so there is no per-host variation to reason about.)

## Host

The repo has exactly one host. It is NixOS only (no Darwin/macOS hosts, no home-only hosts).

| Host | Arch | Platform |
|------|------|----------|
| `nixos-laptop` | `x86_64-linux` | NixOS |

`aarch64-linux` is only exercised by evaluation-only tests in `templates/tests/` (no aarch64 hardware, and CI does not build it).

## Module Layout

All denix modules live in a single tree, `modules/nixos/` (programs, services, shared, specializations, themes, toplevel, config). Host definitions are in `hosts/`, local packages in `packages/`, static assets (wallpapers, profile picture, svgs) in `modules/src/`, and non-denix manual-import files in `templates/`. There is no `users/` directory and no `modules/common/` or `modules/darwin/`.

`flake.nix` passes `paths = [ ./hosts ./modules/nixos ./packages ]` to denix. `moduleSystem` is `"nixos"` for `nixosConfigurations` and `"home"` for the standalone `homeConfigurations` (same paths).

**Verification commands:**

After making any configuration changes, run:

> **Critical - stage new/renamed files first:** Nix flakes only evaluate git-tracked files. Untracked files are invisible to the evaluator and will cause confusing "option does not exist" or missing-module errors. Before running any verification command, always check for and stage untracked files (this directory may not currently be a git repo; if it is):
> ```bash
> git status --short   # look for ?? entries
> git add <any-untracked-files>
> ```

```bash
# 1. Flake check (validates all configurations)
nix flake check

# 2. Dry build for nixos-laptop (x86_64-linux)
nix build .#nixosConfigurations.nixos-laptop.config.system.build.toplevel --dry-run
# Or use the nh helper:
nh os test --dry --ask
```

### Module Block Types

| Block | NixOS build | Standalone home build |
|-------|-------------|-----------------------|
| `nixos.ifEnabled` / `nixos.always` | System-level NixOS config | Ignored |
| `home.ifEnabled` / `home.always` | Sets `home-manager.users.<user>.*` | Sets config directly |

- `home.*` blocks target home-manager in both cases.
- `nixos.*` blocks are NixOS system-level only.

## Denix Framework Architecture

### Auto-Discovery

Denix scans the `paths` listed in `flake.nix` and loads every `.nix` file not in `exclude`. No manual imports needed.

### Key API

- `delib.singleEnableOption <default>` - creates a single `enable` boolean option. Prefer this when a module only needs an on/off toggle.
- `delib.moduleOptions { ... }` - creates multiple typed options (used in `constants.nix`). Declare related options as **flat siblings** - never group them under `submodule`. Use `submodule` only for list elements (e.g. `listOfOption (submodule { ... })`).
- Option helpers: `strOption`, `boolOption`, `listOfOption`, `submodule`
- `imports` blocks must be inside a `nixos.always` or `home.always` block, otherwise the rebuild will fail.
- Never redeclare the module name as an option - `options` or `moduleOptions` is sufficient.

## Constants System

Defines shared typed options via `delib.moduleOptions`. All constants are accessible anywhere as `myconfig.constants.<name>`. The host overrides them in its `myconfig.constants = { ... }` block (`hosts/nixos-laptop/default.nix`).

## Theming

Uses stylix + catppuccin-nix. Controlled via `myconfig.constants.theme.base16Theme`, `myconfig.constants.theme.catppuccin`, `myconfig.constants.theme.catppuccinFlavor` / `catppuccinAccent`, and `myconfig.stylix.enable` + per-target overrides in `myconfig.stylix.targets.*`.

## Secrets

The repo has no secret management (no sops, no agenix). Never hardcode sensitive values - the repo is public. There is no initial password in the config (default `mutableUsers`): the person installing sets the `pierre` password after install with `nixos-enter --root /mnt -c 'passwd pierre'` (see `Documentation/installation/disko.md`).

## Known gotchas

Non-obvious, previously-investigated issues. Read the linked doc before
re-investigating one of these from scratch.

- **Rebuilding from inside a live Hyprland session kicks you to SDDM** - OPEN, no fix yet; root cause narrowed to an nixpkgs/Hyprland bump + a Home Manager/uwsm systemd teardown bug, not this repo's Lua config switch. [`Documentation/usage/gotchas/hyprland-rebuild-kicks-sddm.md`](Documentation/usage/gotchas/hyprland-rebuild-kicks-sddm.md)
- **Stylix + Qt/KDE/GTK theming pitfalls** - never enable `stylix.targets.qt` (crashes Plasma), KDE zebra-striping fix, GTK3 dark-mode fix. [`Documentation/usage/gotchas/stylix-qt-kde-gtk-theming.md`](Documentation/usage/gotchas/stylix-qt-kde-gtk-theming.md)
- **xdg-desktop-portal silently unavailable under non-KDE/GNOME WMs** - dual-level `UseIn=` + `NIX_XDG_DESKTOP_PORTAL_DIR` trap, full diagnosis recipe. [`Documentation/usage/gotchas/xdg-desktop-portal-nixos.md`](Documentation/usage/gotchas/xdg-desktop-portal-nixos.md)

## `./templates/`

Contains `.nix` files not written in the denix style. Not auto-discovered; must be imported manually in the desired host (either directly or via a `default.nix` with an `imports` block).
