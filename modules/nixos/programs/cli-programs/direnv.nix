{ delib, ... }:
delib.module {
  name = "programs.direnv";
  options = delib.singleEnableOption false;

  home.ifEnabled = { myconfig, ... }:
    let
      devEnvBase = "/home/${myconfig.constants.user}/nix/templates/pierre/dev-environments";
    in
    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        stdlib = ''
          use_dev_env() {
            use flake ${devEnvBase}/language-specific/$1
          }
          use_combined_env() {
            use flake ${devEnvBase}/language-combined/$1
          }
        '';
      };
    };
}
