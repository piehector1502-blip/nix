# Arch-compat scenario B: all modules + tlp + sddm-pixie.
# Returns an attrset of home.activationPackage derivations (one per batch),
# suitable for `nix build --dry-run --file this.nix --attr <name>`.
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else builtins.getEnv "PWD";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;

  nixosPaths = [
    (src + "/templates/tests/nixos/test-arch-compat/shared/nixos-extra-aarch64")

    (src + "/modules/nixos/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants.nix")
    (src + "/modules/nixos/toplevel/nix-nixos.nix")
    (src + "/modules/nixos/themes/catppuccin.nix")
    (src + "/modules/nixos/toplevel/common-configuration-nixos.nix")

    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/toplevel/niri.nix")
    (src + "/modules/nixos/toplevel/mango.nix")
    (src + "/modules/nixos/toplevel/gnome.nix")
    (src + "/modules/nixos/toplevel/kde.nix")
    (src + "/modules/nixos/toplevel/cosmic.nix")

    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix")
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-main.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-binds.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-main.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-binds.nix")
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-main.nix")
    (src + "/modules/nixos/programs/de-wm/gnome/gnome-binds.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-main.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-binds.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-desktop.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-files.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-inputs.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-krunner.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-kscreenlocker.nix")
    (src + "/modules/nixos/programs/de-wm/kde/kde-panels.nix")
    (src + "/modules/nixos/programs/de-wm/cosmic/cosmic-main.nix")

    (src + "/modules/nixos/programs/shells/caelestia-main.nix")
    (src + "/modules/nixos/programs/shells/noctalia-main.nix")

    (src + "/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix")
    (src + "/modules/nixos/programs/waybar/niri/waybar-niri.nix")
    (src + "/modules/nixos/programs/waybar/mango/waybar-mango.nix")

    (src + "/modules/nixos/programs/shells/bash.nix")
    (src + "/modules/nixos/programs/shells/fish.nix")
    (src + "/modules/nixos/programs/shells/zsh.nix")
    (src + "/modules/nixos/programs/shells/shell-aliases.nix")
    (src + "/modules/nixos/programs/shells/starship.nix")
    (src + "/modules/nixos/programs/shells/fzf.nix")
    (src + "/modules/nixos/programs/shells/lazygit.nix")
    (src + "/modules/nixos/programs/shells/tmux.nix")
    (src + "/modules/nixos/programs/shells/bat.nix")
    (src + "/modules/nixos/programs/shells/eza.nix")
    (src + "/modules/nixos/programs/shells/git.nix")
    (src + "/modules/nixos/programs/shells/npm.nix")
    (src + "/modules/nixos/programs/shells/yazi-plugins.nix")
    (src + "/modules/nixos/programs/shells/zoxide.nix")
    (src + "/modules/nixos/programs/shells/nix-search-tv/nst-home.nix")
    (src + "/modules/nixos/programs/claude-code.nix")
    (src + "/modules/nixos/programs/headroom.nix")
    (src + "/modules/nixos/programs/comma.nix")
    (src + "/modules/nixos/programs/doom/doom-main.nix")
    (src + "/modules/nixos/programs/doom/doom-tree-sitter.nix")
    (src + "/modules/nixos/programs/nltch-nur.nix")
    (src + "/modules/nixos/programs/statix.nix")
    (src + "/modules/nixos/programs/television.nix")
    (src + "/modules/nixos/programs/zen-browser.nix")
    (src + "/modules/nixos/services/tailscale.nix")
    (src + "/modules/nixos/toplevel/cachix.nix")
    (src + "/modules/nixos/toplevel/nh.nix")
    (src + "/modules/nixos/toplevel/nix-sweeps.nix")

    (src + "/modules/nixos/programs/cava.nix")
    (src + "/modules/nixos/programs/claude-desktop.nix")
    (src + "/modules/nixos/programs/concord.nix")
    (src + "/modules/nixos/programs/google-antigravity.nix")
    (src + "/modules/nixos/programs/nix-alien.nix")
    (src + "/modules/nixos/programs/nix-ld.nix")
    (src + "/modules/nixos/programs/nix-topology.nix")
    (src + "/modules/nixos/programs/swayosd.nix")
    (src + "/modules/nixos/programs/tgt.nix")
    (src + "/modules/nixos/programs/vicinae.nix")
    (src + "/modules/nixos/programs/walker.nix")

    (src + "/modules/nixos/services/audio.nix")
    (src + "/modules/nixos/services/autotrash.nix")
    (src + "/modules/nixos/services/hypr/hypridle.nix")
    (src + "/modules/nixos/services/hypr/hyprlock.nix")
    (src + "/modules/nixos/services/power/auto-cpufreq.nix")
    (src + "/modules/nixos/services/power/thermald.nix")
    (src + "/modules/nixos/services/power/tlp.nix")
    (src + "/modules/nixos/services/sddm/sddm-astronaut.nix")
    (src + "/modules/nixos/services/sddm/sddm-pixie.nix")
    (src + "/modules/nixos/services/snapshots.nix")
    (src + "/modules/nixos/services/swaync.nix")

    (src + "/modules/nixos/toplevel/bluetooth.nix")
    (src + "/modules/nixos/toplevel/zram.nix")
    (src + "/modules/nixos/toplevel/net.nix")
    (src + "/modules/nixos/toplevel/qt.nix")
    (src + "/modules/nixos/toplevel/xdg-portal.nix")

    (src + "/modules/nixos/specializations/guest.nix")

    (src + "/modules/nixos/programs/cli-programs/direnv.nix")
    (src + "/modules/nixos/programs/cli-programs/neovim.nix")
    (src + "/modules/nixos/programs/file-managers/yazi/init-lua.nix")
    (src + "/modules/nixos/programs/file-managers/yazi/yazi-keymap.nix")
    (src + "/modules/nixos/programs/file-managers/yazi/yazi.nix")
    (src + "/modules/nixos/programs/file-managers/yazi/yazi-theme.nix")
    # profiles/librewolf-profile-{default,privacy}.nix excluded: they are { addons, ... } helper
    # functions called by librewolf-common.nix, not standalone denix modules.
    (src + "/modules/nixos/programs/gui-programs/zathura.nix")
    (src + "/modules/nixos/programs/gui-programs/zen-browser/extensions.nix")
    (src + "/modules/nixos/programs/gui-programs/zen-browser/keyboard.nix")
    (src + "/modules/nixos/programs/gui-programs/zen-browser/mods.nix")
    (src + "/modules/nixos/programs/gui-programs/zen-browser/pins.nix")
    (src + "/modules/nixos/programs/gui-programs/zen-browser/search.nix")
    (src + "/modules/nixos/programs/gui-programs/zen-browser/settings.nix")
    (src + "/modules/nixos/programs/terminal-emulators/alacritty.nix")
    (src + "/modules/nixos/programs/terminal-emulators/kitty.nix")

    # NixOS-specific user modules
    (src + "/modules/nixos/shared/home/home-base.nix")
    (src + "/modules/nixos/shared/system/default-user.nix")
    (src + "/modules/nixos/shared/system/swiss-locale.nix")
    (src + "/modules/nixos/shared/system/virtualisation.nix")
    (src + "/modules/nixos/programs/file-managers/dolphin.nix")
    (src + "/modules/nixos/programs/gui-programs/zen-browser/spaces.nix")
    (src + "/modules/nixos/programs/progressive-web-apps.nix")
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
      (src + "/templates/tests/nixos/test-arch-compat/shared/host-tlp-sddm-pixie.nix")
      (src + "/templates/tests/nixos/test-arch-compat/shared/local-packages.nix")
    ] ++ nixosPaths;
    exclude = [ ];
  }).arch-compat-b.config;

  hm = config.home-manager.users.pierre;
  spec = name: config.specialisation.${name}.configuration.home-manager.users.pierre;
in
{
  "all-modules-tlp-sddm-pixie" = hm.home.activationPackage;
  "specialisation-guest-tlp" = (spec "guest").home.activationPackage;
}
