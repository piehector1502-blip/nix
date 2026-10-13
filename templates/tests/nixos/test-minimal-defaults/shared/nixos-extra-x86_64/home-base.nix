{ lib, ... }:
{
  home-manager.users.pierre = { ... }: {
    home.username = lib.mkForce "pierre";
    home.homeDirectory = lib.mkForce "/home/pierre";
    home.stateVersion = "26.05";
    programs.home-manager.enable = true;
  };
}
