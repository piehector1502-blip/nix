{ delib
, ...
}:
delib.module {
  name = "home.base";
  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }: {
    home.stateVersion = "26.05";
    home.username = myconfig.constants.user;
    home.homeDirectory = "/home/${myconfig.constants.user}";

    xdg.userDirs = { };

    # TODO: add home.activation scripts here to create your own directories
  };
}
