{ delib
, pkgs
, lib
, inputs
, ...
}:
let
  # 🌟 CORE APPS & THEME
  myBrowser = "zen-beta";
  myTerminal = "kitty";
  myShell = "zsh";
  myEditor = "code";
  myFileManager = "dolphin";
  myLocale = "en_US.UTF-8";

  # 🌟 HYPRLAND APP WORKSPACES
  # TODO: decide
  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    terminal = "4";
    chat = "5";
    browser-Entertainment = "6";
    vm = "7";
    other = "10";
  };

  # Add more if needed
  termApps = [
    "nvim"
    "neovim"
    "vim"
    "nano"
    "hx"
    "helix"
    "yazi"
    "ranger"
    "lf"
    "nnn"
  ];
  smartLaunch =
    app: if builtins.elem app termApps then "${myTerminal} --class ${app} -e ${app}" else app;

  # 🌟 DESKTOP MAP & RESOLVE FUNCTION
  desktopMap = {
    "firefox" = "firefox.desktop";
    "librewolf" = "librewolf.desktop";
    "google-chrome" = "google-chrome.desktop";
    "chromium" = "chromium-browser.desktop";
    "brave" = "brave-browser.desktop";
    "nvim" = "custom-nvim.desktop";
    "code" = "code.desktop";
    "kate" = "org.kde.kate.desktop";
    "yazi" = "yazi.desktop";
    "ranger" = "ranger.desktop";
    "dolphin" = "org.kde.dolphin.desktop";
    "thunar" = "thunar.desktop";
    "Nautilus" = "org.gnome.Nautilus.desktop";
    "nemo" = "nemo.desktop";
  };
  resolve = name: desktopMap.${name} or "${name}.desktop";

  langLayout = {
    "format-en" = "🇺🇸-EN";
  };

  pinnedApps = [
    (resolve myBrowser)
    (resolve myEditor)
    (resolve myFileManager)
  ];
in

delib.host {
  name = "nixos-laptop";
  type = "laptop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        hostname = "nixos-laptop";
        mainLocale = myLocale;

        homeStateVersion = "26.05";
        emergencyAccess = true;

        # ---------------------------------------------------------------
        # 👤 USER IDENTITY
        # ---------------------------------------------------------------
        user = "pierre";
        gitUserName = "piehector1502-blip";
        gitUserEmail = "piehector1502@gmail.com";

        # ---------------------------------------------------------------
        # 🐚 SHELLS & APPS
        # ---------------------------------------------------------------
        terminal = {
          name = myTerminal;
        };
        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        # TODO: choose
        wallpapers = [
          {
            targetMonitor = "eDP-1";
            wallpaperURL = "https://raw.githubusercontent.com/Maroc02/hyde-wallpapers/main/Dracula/cat.png";
            wallpaperSHA256 = "1q618phnrmgwdpf67g6qfa6zr1lcrlizpdbpcafkxc79nvc35i0r";
          }

          {
            targetMonitor = "*";
            wallpaperURL = "https://gitea.nicolkrit.ch/krit/wallpapers-repo/raw/branch/main/various/other-user-github-repos/Maroc02/hyde-wallpapers-main/Catppuccin%20Mocha/switch_swirl.jpg";
            wallpaperSHA256 = "1zhg5cx0x6b691jbbn15ggyqrxnvzvfsv3r89f6hg7rpwvnvhbcl";
          }
        ];




        # ---------------------------------------------------------------
        # 🎨 THEMING
        # ---------------------------------------------------------------
        # TODO: to fill
        theme = {
          polarity = "dark";
          base16Theme = "dracula";
          catppuccin = false;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "sapphire";
        };

        keyboardLayout = "us";
        keyboardVariant = "intl";

        weather = "Lugano";

        timeZone = "Europe/Zurich";
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      bluetooth = {
        enable = true;
        autoEnableOnBoot = false;
      };

      cachix = {
        enable = true;
        push = false;
      };

      nh = {
        enable = true;
        gcd = "10d";
        gcn = "2";
      };
      nix-sweeps = {
        enable = true;
        gcd = "10d";
        gcn = "2";
      };

      qt.enable = true;

      # ---------------------------------------------------------------
      # 🚀 PROGRAMS
      # ---------------------------------------------------------------
      programs = {
        direnv.enable = true;
        dolphin.enable = true;
        kitty.enable = true;
        neovim.enable = true;
        pwas.enable = true;
        yazi.enable = true;
        zathura.enable = true;
        bat.enable = true;
        claude-desktop.enable = true;
        eza.enable = true;
        fastfetch.enable = true;
        fzf.enable = true;
        gnome-keyring.enable = true;
        lazygit.enable = true;

        spotifyAdblock.enable = true;

        npm = {
          enable = true;
          packages = [
            "claudefm" # terminal music player
            "claude-token-counter" # Token usage counter for claude code
          ];
          hostPackages = with pkgs; [
            yt-dlp # claudefm: stream source
            mpv # claudefm: playback
          ];
        };
        shell-aliases.enable = true;
        starship.enable = true;
        swayosd.enable = true;
        tmux.enable = true;
        television.enable = true;
        zoxide.enable = true;
        zen.browser.enable = true;

        vicinae = {
          enable = true;
          extraExtensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
            # TODO: choose (slim down if needed)
            agenda
            aria2-manager
            # bluetooth  # excluded upstream (vicinaehq/extensions flake.nix): node-gyp build fails in nix sandbox (dbus-next -> usocket), see vicinaehq/extensions#314
            case-converter
            color-converter
            fuzzy-files
            github
            it-tools
            number-converter
            player-pilot
            supergenpass
            wifi-commander
            wikipedia
            zoxide-recent-directories
          ];

          # TODO: choose slim down if needed
          extraRayCastExtensions = [
            {
              name = "downloads-manager";
              hash = "sha256-GNEWSFWOsS7Ks0nPgqZrFqIYwdw1CYgswIhgAumvTOc=";
            }
            {
              name = "gif-search";
              hash = "sha256-aWIYh6tQbdZxT04TRVEc/HmgJUXFl0eMFpIZpCaIQ4U=";
            }
            {
              name = "google-search";
              hash = "sha256-nGTMIrSEgZX+gPpNc0tLme0MprVzA3Ap4gvEnq3n6IU=";
            }
            {
              name = "lorem-ipsum";
              hash = "sha256-zMhwb4imj79XByXbbVHqhQxso9Jj87bBuJNbqwEjMxs=";
            }
            {
              name = "remove-paywall";
              hash = "sha256-i0jPsCbkl9X/Ka2fRYFHxk3COPxP8V+2C3dTdg6118c=";
            }
            {
              name = "google-translate";
              installName = "translate";
              hash = "sha256-VhJ9wRnToUPccVIQwp4nxQ2ExkgukZIqqET5tS4RpfI=";
            }
            {
              name = "video-downloader";
              hash = "sha256-/Q9VW59t4xgQROuumw/6DWENAWqada+GHszvMyVrT0w=";
            }
            {
              name = "visual-studio-code-recent-projects";
              installName = "visual-studio-code";
              hash = "sha256-fhTmPfLoFpU2wuPHlL0WlLqtHBCLJ7/VMKjt3wLewQc=";
            }
          ];
          extraPackages = with pkgs; [
            aria2 # Required by aria2-manager extension
          ];
        };

        claude-code.enable = true;

        git = {
          enable = true;
          customGitIgnores = [ ];
        };

        # ---------------------------------------------------------------
        # 🐚 SHELLS
        # ---------------------------------------------------------------
        # DO NOT enable 2 different shells in the same windows manager
        caelestia = {
          enable = false;
          enableOnHyprland = false;
        };

        noctalia = {
          enable = false;
          enableOnHyprland = false;
          enableOnNiri = false;
          enableOnMango = false;
        };

        # ---------------------------------------------------------------
        # 🪟 WINDOW MANAGERS
        # ---------------------------------------------------------------
        # TODO: CHOOSE between hyprland and niri or both (enable/disable waybar as needed)
        hyprland = {
          enable = true;
          monitors = [
            {
              output = "eDP-1";
              mode = "1920x1080@60";
              position = "0x0";
              scale = 1.0;
            }
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1;
            }
          ];
          execOnce = [
            "hyprctl dispatch workspace 1"
            "[workspace 1 silent] ${myBrowser}"
            "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
            "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
            "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"
          ];

          windowRules = [
            {
              match.class = "^(${myEditor})$";
              workspace = appWorkspaces.editor;
            }
            {
              match.class = "^(${myFileManager})$";
              workspace = appWorkspaces.fileManager;
            }
            {
              match.class = "^(${myTerminal})$";
              workspace = appWorkspaces.terminal;
            }
            {
              match.class = "^(code)$";
              workspace = "${appWorkspaces.editor} silent";
            }
            {
              match.class = "^(nvim-editor)$";
              workspace = "${appWorkspaces.editor} silent";
            }
            {
              match.class = "^(org.kde.kate)$";
              workspace = "${appWorkspaces.editor} silent";
            }
            {
              match.class = "^(org.kde.dolphin)$";
              workspace = "${appWorkspaces.fileManager} silent";
            }
            {
              match.class = "^(yazi)$";
              workspace = "${appWorkspaces.fileManager} silent";
            }
            {
              match.class = "^(chromium-browser)$";
              workspace = "${appWorkspaces.browser-Entertainment} silent";
            }
            {
              match.class = "^(brave-browser)$";
              workspace = "${appWorkspaces.browser-Entertainment} silent";
            }
            {
              match.class = "^(brave-.*\\..*)$";
              workspace = "${appWorkspaces.browser-Entertainment} silent";
            }
            {
              match.class = "(?i)spotify";
              workspace = "${appWorkspaces.browser-Entertainment} silent";
            }
            {
              match.class = "^(kitty)$";
              workspace = "${appWorkspaces.terminal} silent";
            }
            {
              match.class = "^(alacritty)$";
              workspace = "${appWorkspaces.terminal} silent";
            }
            {
              match.class = "^(vesktop)$";
              workspace = "${appWorkspaces.chat} silent";
            }
            {
              match.class = "^(org.telegram.desktop)$";
              workspace = "${appWorkspaces.chat} silent";
            }
            {
              match.class = "^(com.rtosta.zapzap)$";
              workspace = "${appWorkspaces.chat} silent";
            }

            {
              match.class = "^(scratch-term)$";
              float = true;
            }
            {
              match.class = "^(scratch-term)$";
              center = true;
            }
            {
              match.class = "^(scratch-term)$";
              size = "80% 80%";
            }
            {
              match.class = "^(scratch-term)$";
              workspace = "special:magic";
            }
            {
              match.class = "^(scratch-fs)$";
              float = true;
            }
            {
              match.class = "^(scratch-fs)$";
              center = true;
            }
            {
              match.class = "^(scratch-fs)$";
              size = "80% 80%";
            }
            {
              match.class = "^(scratch-fs)$";
              workspace = "special:magic";
            }
            {
              match.class = "^(scratch-browser)$";
              float = true;
            }
            {
              match.class = "^(scratch-browser)$";
              center = true;
            }
            {
              match.class = "^(scratch-browser)$";
              size = "80% 80%";
            }
            {
              match.class = "^(scratch-browser)$";
              workspace = "special:magic";
            }
          ];

          extraBinds = [
            {
              _args = [
                "SUPER + SHIFT + return"
                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${myTerminal} --class scratch-term")'')
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + F"
                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${myTerminal} --class scratch-fs -e yazi")'')
              ];
            }
            {
              _args = [
                "SUPER + SHIFT + B"
                (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("[workspace special:magic] ${myBrowser} --new-window --class scratch-browser")'')
              ];
            }

            {
              _args = [
                "XF86Tools"
                (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = "m-1" })'')
              ];
            }
            {
              _args = [
                "XF86Launch5"
                (lib.generators.mkLuaInline ''hl.dsp.focus({ workspace = "m+1" })'')
              ];
            }
            {
              _args = [
                "XF86Launch6"
                (lib.generators.mkLuaInline "hl.dsp.window.fullscreen()")
              ];
            }
            {
              _args = [
                "XF86Launch7"
                (lib.generators.mkLuaInline "hl.dsp.window.close()")
              ];
            }
          ];
        };

        # FIXME: not yet ready, see with Krit later
        mango = {
          enable = false;
          monitors = [
            "name:^eDP-1$,width:1920,height:1080,refresh:60,x:0,y:0,scale:1.0"
          ];
          monitorLayouts = {
            "eDP-1" = "scroller";
          };
          execOnce = [
            "sh -c 'sleep 1 && ${myBrowser}'"
            "sh -c 'sleep 5 && ${smartLaunch myEditor}'"
            "sh -c 'sleep 8 && ${smartLaunch myFileManager}'"
            "sh -c 'sleep 11 && ${myTerminal}'"
          ];
          extraBinds = [
            "NONE,XF86Tools,viewtoleft_have_client,0"
            "NONE,XF86Launch5,viewtoright_have_client,0"
            "NONE,XF86Launch6,togglemaximizescreen,"
            "NONE,XF86Launch7,killclient,"
          ];
        };

        niri = {
          enable = false;
          outputs = {
            "eDP-1" = {
              mode = {
                width = 1920;
                height = 1080;
                refresh = 60.0;
              };
            };
          };
          execOnce = [
            "sh -c 'sleep 1 && ${myBrowser}'"
            "sh -c 'sleep 5 && ${smartLaunch myEditor}'"
            "sh -c 'sleep 8 && ${smartLaunch myFileManager}'"
            "sh -c 'sleep 11 && ${myTerminal}'"
            "sh -c 'sleep 27 && niri msg action focus-column-first'" # Refocus browser after all windows are up
          ];
          extraBinds = { };
        };

        # ---------------------------------------------------------------
        # 📊 WAYBARS
        # ---------------------------------------------------------------
        waybar-hyprland = {
          enable = true;
          waybarLayout = langLayout;
          waybarWorkspaceIcons = {
            "1" = "";
            "2" = ":";
            "3" = ":";
            "4" = ":";
            "5" = ":󰭹";
            "6" = ":";
            "7" = "";
            "8" = "";
            "9" = "";
            "10" = ":";
            "magic" = ":";
          };
        };

        waybar-mango = {
          enable = false;
          waybarLayout = langLayout;
        };

        waybar-niri = {
          enable = false;
          waybarLayout = langLayout;
        };

        # ---------------------------------------------------------------
        # 🖥️ DESKTOP ENVIRONMENTS
        # ---------------------------------------------------------------
        cosmic = {
          enable = false;
        };

        gnome = {
          enable = true;
          pinnedApps = pinnedApps;
        };

        kde = {
          enable = false;
          pinnedApps = pinnedApps;
        };
      };

      # ---------------------------------------------------------------
      # ⚙️ SERVICES
      # ---------------------------------------------------------------
      services = {
        laptop = {
          flatpak.enable = true;
          local-packages.enable = true;
        };
        autotrash.enable = true;
        hyprlock.enable = true;
        localsend.enable = true;

        # Power management (mutually exclusive - only enable ONE)
        auto-cpufreq.enable = true; # Recommended: dynamic CPU scaling (uses official flake)
        thermald.enable = false;

        hypridle = {
          enable = true;
          dimTimeout = 180;
          lockTimeout = 300;
          screenOffTimeout = 600;
        };

        # TODO: choose between pixie and astronaut (already built theme or custom wallpaper)
        sddm-astronaut = {
          enable = false;
          embeddedTheme = "jake_the_dog";
        };

        snapshots = {
          enable = true;
          retention = {
            hourly = "5";
            daily = "3";
            weekly = "2";
            monthly = "1";
            yearly = "0";
          };
        };

        swaync = {
          enable = true;
          customSettings = {
            /*
                "mute-protonvpn" = {
                  state = "ignored";
                  app-name = ".*Proton.*";
              */
          };
        };
      };

      # ---------------------------------------------------------------
      # 🎭 SPECIALIZATIONS
      # ---------------------------------------------------------------
      specializations = {
        guest.enable = true;
        school.enable = true;
      };

      # ---------------------------------------------------------------
      # 🔧 SYSTEM
      # ---------------------------------------------------------------
      system = {
        default-user.enable = true;
        swiss-locale.enable = true;
        virtualisation.enable = true;
      };

      home.base.enable = true;
    };
}
