{ delib, ... }:
delib.module {
  name = "system.virtualisation";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    virtualisation.podman.enable = true;
    # TODO: enable other backends here, e.g. virtualisation.libvirtd.enable = true;
  };
}
