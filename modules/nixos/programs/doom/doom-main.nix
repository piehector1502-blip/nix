{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "programs.doom";

  options = delib.singleEnableOption false;

  home.always = { ... }: {
    imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];
  };

  home.ifEnabled = { myconfig, ... }:
    let
      user = myconfig.constants.user;
    in
    {
      programs.doom-emacs = {
        enable = true;
        doomDir = ./doomdir;
        doomLocalDir = "/home/${user}/.local/share/nix-doom";
        emacs = pkgs.emacs-pgtk;
        provideEmacs = true;
        experimentalFetchTree = true;
      };
    };
}
