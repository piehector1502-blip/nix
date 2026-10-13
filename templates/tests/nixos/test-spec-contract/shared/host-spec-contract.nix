{ delib, ... }:
delib.host {
  name = "spec-contract";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ./base-constants.nix;

    # Enabled so specializations' lib.mkForce false is a real override:
    programs.hyprland.enable = true; # guest disables
    programs.caelestia.enable = true; # guest disables
    programs.noctalia.enable = true; # guest disables
    programs.nix-ld.enable = true; # guest disables
    programs.nix-alien.enable = true; # guest disables
    programs.claude-code.enable = true; # guest disables
    programs.claude-desktop.enable = true; # guest disables
    bluetooth.enable = true; # guest disables

    # Specializations
    specializations.guest.enable = true;
    specializations.school.enable = true;
  };
}
