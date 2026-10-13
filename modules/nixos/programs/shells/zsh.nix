{ delib
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "programs.zsh";

  home.always =
    { myconfig, ... }:
    let
      fastfetchEnabled = myconfig.programs.fastfetch.enable or false;
      splashCmd = myconfig.programs.fastfetch.splashCommand or "fastfetch";
      currentShell = myconfig.constants.shell or "bash";
      isNixOS = moduleSystem == "nixos";
    in
    lib.mkIf (currentShell == "zsh") {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        initContent =
          # Common init
          ''
            # LOAD USER CONFIG
            if [ -f "$HOME/.zshrc_custom" ]; then
              source "$HOME/.zshrc_custom"
            fi
          ''
          # NixOS-specific init
          + lib.optionalString isNixOS ''
            # FIX HYPRLAND SOCKET (Dynamic Update)
            if [ -d "/run/user/$(id -u)/hypr" ];
            then
              socket_file=$(find /run/user/$(id -u)/hypr/ -name ".socket.sock" -print -quit)
              if [ -n "$socket_file" ];
              then
                export HYPRLAND_INSTANCE_SIGNATURE=$(basename $(dirname "$socket_file"))
              fi
            fi

            # TMUX AUTOSTART (Only in GUI)
            if command -v tmux > /dev/null && [ -z "$TMUX" ] && [ -z "$NVIM" ] && [ -n "$DISPLAY" ]; then
              tmux new-session -A -s main
            fi

            # UWSM STARTUP (Universal & Safe)
            if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
                if command -v uwsm > /dev/null && uwsm check may-start > /dev/null && uwsm select; then
                    exec systemd-cat -t uwsm_start uwsm start default
                fi
            fi
          ''
          + lib.optionalString fastfetchEnabled ''

            # STARTUP SPLASH
            case "$-" in
              (*i*)
                if [ -n "$TMUX" ] || ! command -v tmux > /dev/null || [ -z "$DISPLAY" ]; then
                  ${splashCmd}
                fi
                ;;
            esac
          '';
      };
    };
}
