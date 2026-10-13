# Daily Usage & Updates

After editing any file, use these aliases to apply changes. They require `programs.nh.enable = true` (enabled by default).

| Alias | Command | Description |
|-------|---------|-------------|
| `sw` | `nh os switch` | Rebuild everything (system + home-manager) |
| `upd` | `nh os switch --update` | Update all flake inputs, then rebuild |

Both commands handle system and home-manager rebuilds in one step.

### Binary cache (Cachix)

`cachix.enable = true` in `hosts/nixos-laptop/default.nix` makes `sw` and `upd` pull pre-built binaries from the project's Cachix cache instead of compiling locally, which is significantly faster on a good connection. Pushing is off (`cachix.push = false`), so your own builds are not uploaded.
