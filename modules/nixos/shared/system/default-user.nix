{ delib, ... }:
delib.module {
  name = "system.default-user";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      users.users.${myconfig.constants.user} = {
        isNormalUser = true;
        description = "${myconfig.constants.user}";
        # wheel (sudo) and networkmanager (network control) are required for a usable desktop user
        extraGroups = [
          "wheel"
          "networkmanager"
          # "video" # example: add extra groups here
        ];
      };
    };
}
