{ delib
, pkgs
, ...
}:
delib.module {
  name = "programs.pwas";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    {
      home.packages = [ pkgs.brave ];

      xdg.desktopEntries = builtins.listToAttrs [
        # TODO: add your own, e.g.
        # (makeBravePwa "GitHub" "https://github.com/" "vcs-git" "brave-github.com__-Default")
      ];
    };
}
