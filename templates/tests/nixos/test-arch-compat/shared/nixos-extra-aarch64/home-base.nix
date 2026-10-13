{ lib, ... }:
{
  home-manager.users.pierre = { ... }: {
    home.username = lib.mkForce "pierre";
    home.homeDirectory = lib.mkForce "/home/pierre";
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;

    # catppuccin-nix Firefox and Starship modules use IFD at evaluation time:
    #   firefox.nix:  importJSON "${sources.firefox}/themes.json"
    #   starship.nix: importTOML "${sources.starship}/<flavor>.toml"
    # Forcing enable=false keeps the let-bindings lazy so no aarch64 derivation
    # is actually built during --dry-run.
    catppuccin.firefox.enable = lib.mkForce false;
    catppuccin.starship.enable = lib.mkForce false;
  };
}
