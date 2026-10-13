{ lib, ... }:
{
  home-manager.users.pierre = { ... }: {
    home.username = lib.mkForce "pierre";
    home.homeDirectory = lib.mkForce "/home/pierre";
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;

    # catppuccin-nix Firefox and Starship modules use IFD at evaluation time.
    # Forcing enable=false keeps the let-bindings lazy so no aarch64 derivation
    # is actually built during eval.
    catppuccin.firefox.enable = lib.mkForce false;
    catppuccin.starship.enable = lib.mkForce false;
  };
}
