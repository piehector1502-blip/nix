# Specialization contract scenario.
# Evaluates a fake host with only the modules that specializations touch, then
# reads each specialization's config to verify lib.mkForce overrides landed.
#
# All checks return "ok" or "FAIL: <detail>" for use with nix eval --raw.
#
# Usage:
#   nix eval --raw --impure --file this.nix --attr check-<name>
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else builtins.getEnv "PWD";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;

  nixosPaths = [
    # x86_64 platform override + home-manager base + stylix stub
    (src + "/templates/tests/nixos/test-spec-contract/shared/nixos-extra-x86_64")

    # Core infrastructure
    (src + "/modules/nixos/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants.nix")
    (src + "/modules/nixos/toplevel/nix-nixos.nix")
    (src + "/modules/nixos/themes/catppuccin.nix")
    (src + "/modules/nixos/toplevel/common-configuration-nixos.nix")

    # WM enable options - specs reference myconfig.programs.*.enable on all of these
    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/toplevel/niri.nix")
    (src + "/modules/nixos/toplevel/mango.nix")
    (src + "/modules/nixos/toplevel/gnome.nix")
    (src + "/modules/nixos/toplevel/kde.nix")
    (src + "/modules/nixos/toplevel/cosmic.nix")

    # Hyprland DE modules (needed for monitors/execOnce/windowRules options)
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix")
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix")

    # Waybar (a spec forces waybar-hyprland.waybarWorkspaceIcons)
    (src + "/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix")

    # Niri DE modules (school spec references niri.execOnce, niri.outputs)
    (src + "/modules/nixos/programs/de-wm/niri/niri-main.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-binds.nix")

    # Mango DE modules (school spec references mango.execOnce, mango.monitors)
    (src + "/modules/nixos/programs/de-wm/mango/mango-main.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-binds.nix")

    # Gnome DE modules
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-main.nix")
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-binds.nix")

    # KDE DE modules (plasma-manager HM options)
    (src + "/modules/nixos/programs/de-wm/kde/kde-main.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-desktop.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-files.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-inputs.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-krunner.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-kscreenlocker.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-panels.nix")

    # Custom shells (enabled in host so guest overrides are real)
    (src + "/modules/nixos/programs/shells/caelestia-main.nix")
    (src + "/modules/nixos/programs/shells/noctalia-main.nix")

    # Programs whose enable options specs override
    (src + "/modules/nixos/programs/claude-code.nix")
    (src + "/modules/nixos/programs/claude-desktop.nix")
    (src + "/modules/nixos/programs/nix-alien.nix")
    (src + "/modules/nixos/programs/nix-ld.nix")

    # Services whose enable options specs override
    (src + "/modules/nixos/services/hypr/hypridle.nix")
    (src + "/modules/nixos/services/hypr/hyprlock.nix")
    (src + "/modules/nixos/services/swaync.nix")
    (src + "/modules/nixos/services/tailscale.nix")
    (src + "/modules/nixos/toplevel/bluetooth.nix")

    # Shell modules (used by school initExtra)
    (src + "/modules/nixos/programs/shells/bash.nix")
    (src + "/modules/nixos/programs/shells/fish.nix")
    (src + "/modules/nixos/programs/shells/zsh.nix")

    # Global specializations
    (src + "/modules/nixos/specializations/guest.nix")

    # Minimal user infrastructure
    (src + "/modules/nixos/shared/home/home-base.nix")
    (src + "/modules/nixos/shared/system/default-user.nix")
    (src + "/modules/nixos/shared/system/virtualisation.nix")

    # pierre specializations
    (src + "/modules/nixos/specializations/school.nix")
  ];

  config = (denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "pierre";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inputs = flake.inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (src + "/templates/tests/nixos/test-spec-contract/shared/host-spec-contract.nix")
    ] ++ nixosPaths;
    exclude = [ ];
  }).spec-contract.config;

  # spec name → full NixOS config with that specialization applied
  spec = name: config.specialisation.${name}.configuration;
  # specHm name → home-manager pierre config within that specialization
  specHm = name: (spec name).home-manager.users.pierre;

  checkBool = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${if expected then "true" else "false"}, got ${if actual then "true" else "false"}";

  checkStr = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected '${expected}', got '${actual}'";

  checkContains = name: str: substr:
    if lib.strings.hasInfix substr str then "ok"
    else "FAIL: ${name}: expected to contain '${substr}'";

  checkPkgInList = name: pkglist: pname:
    if builtins.any (p: (p.pname or p.name or "") == pname) pkglist then "ok"
    else "FAIL: ${name}: package '${pname}' not found in home.packages";
in
{
  # ── guest ────────────────────────────────────────────────────────────────────
  check-guest-hyprland-disabled =
    checkBool "guest.hyprland.enable" (spec "guest").myconfig.programs.hyprland.enable false;
  check-guest-stylix-disabled =
    checkBool "guest.myconfig.stylix.enable" (spec "guest").myconfig.stylix.enable false;
  check-guest-bluetooth-disabled =
    checkBool "guest.bluetooth.enable" (spec "guest").myconfig.bluetooth.enable false;
  check-guest-hyprlock-disabled =
    checkBool "guest.services.hyprlock.enable" (spec "guest").myconfig.services.hyprlock.enable false;
  check-guest-swaync-disabled =
    checkBool "guest.services.swaync.enable" (spec "guest").myconfig.services.swaync.enable false;
  # The .desktop text holds the derivation Exec path, not the zenity call directly;
  # verifying "guest-welcome" confirms the autostart entry points to the right wrapper.
  check-guest-welcome-desktop =
    checkContains "guest autostart .desktop"
      (spec "guest").environment.etc."xdg/autostart/guest-welcome.desktop".text
      "guest-welcome";

  # ── school ────────────────────────────────────────────────────────────────────
  check-school-browser-constant =
    checkStr "school.constants.browser" (spec "school").myconfig.constants.browser "brave-school";
  check-school-editor-constant =
    checkStr "school.constants.editor" (spec "school").myconfig.constants.editor "nvim";
  check-school-setup-script =
    checkPkgInList "school home.packages" (specHm "school").home.packages "school-distrobox-setup";
  check-school-check-script =
    checkPkgInList "school home.packages" (specHm "school").home.packages "school-distrobox-check";
  check-school-clear-script =
    checkPkgInList "school home.packages" (specHm "school").home.packages "school-distrobox-clear";
}
