# test-spec-contract

Verifies that every specialization's `lib.mkForce` overrides actually land in the evaluated config.

The fake host enables only the features that specializations override. Every check reads back the option value (or config artifact) from the specialization's configuration and asserts it matches the forced value.

## Run

```bash
bash templates/tests/nixos/test-spec-contract/check-nixos-spec-contract.sh
```

Or from inside the directory:

```bash
bash check-nixos-spec-contract.sh
```

## How it works

`01-scenario-spec-contract.nix` builds a fake fully-featured host then exposes
check results as strings (`"ok"` / `"FAIL: ..."`).

`check-nixos-spec-contract.sh` calls `nix eval --raw --impure` for each attribute and reports pass/fail.

## Checks

### guest
| Check | Expected |
|-------|----------|
| `hyprland.enable` | `false` |
| `myconfig.stylix.enable` | `false` |
| `bluetooth.enable` | `false` |
| `services.hyprlock.enable` | `false` |
| `services.swaync.enable` | `false` |
| autostart `.desktop` Exec | points to `guest-welcome` wrapper |

### school
| Check | Expected |
|-------|----------|
| `constants.browser` | `"brave-school"` |
| `constants.editor` | `"nvim"` |
| `school-distrobox-setup` | in `home.packages` |
| `school-distrobox-check` | in `home.packages` |
| `school-distrobox-clear` | in `home.packages` |
