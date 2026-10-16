{ delib
, pkgs
, inputs
, ...
}:
delib.host {
  name = "nixos-laptop";

  nixos = {
    system.stateVersion = "26.05";

    environment.variables = { };

    imports = [
      inputs.disko.nixosModules.disko
      ./disko-config-btrfs.nix
      ./hardware-configuration.nix

      # Other config
      (
        { config, ... }:
        {
          i18n.defaultLocale = config.myconfig.constants.mainLocale;
        }
      )
    ];

    hardware.enableRedistributableFirmware = true;
    hardware.graphics.enable = true;
    virtualisation.virtualbox.host.enable = true;
    users.extraGroups.vboxusers.members = [ "pierre" ];
    users.users.pierre.extraGroups = [ "disk" ];
    swapDevices = [
      { device = "/swapfile"; size = 4096; }
    ];
    boot.kernelParams = [ "usb-storage.quirks=0bda:9210:u" ];
    nix.settings.max-jobs = 2;

    # Laptop-specific packages
    environment.systemPackages = with pkgs; [
      lm_sensors # Tools for reading hardware sensors - maintained fork
    ];
  };
}
