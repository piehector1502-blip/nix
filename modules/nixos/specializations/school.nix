{ delib
, inputs
, config
, lib
, pkgs
, ...
}:
let
  # TODO: fill in - git identity used inside the school specialization
  schoolGitName = "CHANGE ME";
  schoolGitEmail = "CHANGE_ME@example.com";
  myUserName = config.myconfig.constants.user;
  c = config.myconfig.constants;
  term = c.terminal.name;

  # HiDPI scale for the distrobox-launched X11/Java tools below (tkgate,
  # SQL Developer). Matches each host's physical panel, mirroring the
  # Hyprland monitor "scale" already declared for it (see
  # hosts/nixos-laptop/default.nix).
  # Deliberately static, not queried from the running compositor: scale is
  # a property of the panel, not of whichever WM/DE happens to be active.
  guiScale =
    if c.hostname == "nixos-laptop" then 1.6
    else 1.0;
  xftDpi = toString (builtins.floor (96 * guiScale));

  distroboxApps = [
    {
      name = "tkgate";
      container = "school-ubuntu";
      image = "ubuntu:latest";
      check = "command -v tkgate";
      rootInit = builtins.concatStringsSep " && " [
        "[ -f /etc/sudoers ] || cp /etc/sudoers.dpkg-new /etc/sudoers"
        "chmod 440 /etc/sudoers"
        "DEBIAN_FRONTEND=noninteractive dpkg --configure -a"
      ];
      install = "sudo apt-get update && sudo apt-get install -y tkgate";
    }
  ];

  distroboxStartupCheck = pkgs.writeShellScript "school-distrobox-startup-check" ''
    MISSING=""
    ${lib.concatMapStringsSep "\n" (app: ''
      if ! ${pkgs.podman}/bin/podman container exists "${app.container}" 2>/dev/null; then
        MISSING="$MISSING ${app.name}"
      fi
    '') distroboxApps}

    if [ -n "$MISSING" ]; then
      echo "Missing distrobox containers:$MISSING"
      echo "Run: school-distrobox-setup"
    else
      echo "Distrobox containers found. Run school-distrobox-check to verify tools are installed."
    fi
  '';

  # Deep check: enters each container and verifies the actual package is installed.
  distroboxDeepCheck = pkgs.writeShellScript "school-distrobox-deep-check" ''
    MISSING=""
    ${lib.concatMapStringsSep "\n" (app: ''
      if ! ${pkgs.podman}/bin/podman container exists "${app.container}" 2>/dev/null; then
        MISSING="$MISSING ${app.name}(no container)"
      elif ! ${pkgs.distrobox}/bin/distrobox enter ${app.container} -- bash -c '${app.check}' &>/dev/null; then
        MISSING="$MISSING ${app.name}(not installed)"
      fi
    '') distroboxApps}

    if [ -n "$MISSING" ]; then
      echo "Missing distrobox tools:$MISSING"
      echo "Run: school-distrobox-setup"
      exit 1
    else
      echo "All distrobox tools are present and verified."
    fi
  '';

in
delib.module {
  name = "specializations.school";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    nixpkgs.config.allowUnfree = true;
    # The actual specialization
    specialisation.school.configuration = {
      system.nixos.tags = [ "school" ];
      # Home separata: stesso utente, cartella diversa
      users.users.${myUserName}.home = lib.mkForce "/home/${myUserName}-school";

      myconfig.programs.hyprland.execOnce = lib.mkForce (
        if c.hostname == "nixos-laptop" then [
          "[workspace 2 silent] ${term} --class nvim-school -d $HOME/.school-workspace -e nvim"
          "[workspace 3 silent] ${term} --class yazi -d $HOME/.school-workspace -e yazi"
          "[workspace 4 silent] ${term} -d $HOME/.school-workspace"
          "[workspace 5 silent] brave-school --app=https://www.icorsi.ch/"
        ] else [ ]
      );
      myconfig.programs.hyprland.windowRules = lib.mkForce [ ];

      myconfig.programs.niri.execOnce = lib.mkForce [
        "brave-school --app=https://www.icorsi.ch/"
        "sleep 2 && vscode-school"
        "sleep 4 && ${term} --class yazi -d $HOME/.school-workspace -e yazi"
        "sleep 6 && ${term} -d $HOME/.school-workspace"
      ];

      myconfig.programs.mango.execOnce = lib.mkForce [
        "sh -c 'sleep 1 && brave-school --app=https://www.icorsi.ch/'"
        "sh -c 'sleep 2 && vscode-school'"
        "sh -c 'sleep 4 && ${term} --class yazi -d $HOME/.school-workspace -e yazi'"
        "sh -c 'sleep 6 && ${term} -d $HOME/.school-workspace'"
      ];

      # Override host-default constants for school specialization
      myconfig.constants.browser = lib.mkForce "brave-school";
      myconfig.constants.editor = lib.mkForce "nvim";
      myconfig.constants.shell = lib.mkForce "bash";

      # Force exit-node off on every boot into this specialisation, regardless
      # of whatever exit-node state tailscale persisted from the last boot.
      systemd.services.tailscale-school-exit-node-off = {
        description = "Force tailscale exit-node off for the school specialisation";
        after = [ "tailscaled.service" "tailscale-autoconnect.service" ];
        wants = [ "tailscaled.service" "tailscale-autoconnect.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          ${pkgs.tailscale}/bin/tailscale set --exit-node=
        '';
      };

      # Self-contained virtualisation: school doesn't depend on the host's virtualisation.nix
      virtualisation.podman.enable = true;
      virtualisation.virtualbox.host.enable = lib.mkForce false;
      swapDevices = lib.mkForce [ ];
      boot.kernelParams = lib.mkForce [
        # Come DEFAULT, senza il fix USB (usb-storage.quirks)
        "panic=10"
        "pause_on_oops=300"
        "quiet"
        "splash"
        "root=fstab"
        "loglevel=4"
        "lsm=landlock,yama,bpf"
        "crashkernel=128M"
        "nmi_watchdog=panic"
        "softlockup_panic=1"
        "vt.default_red=0x28,0xff,0x50,0xf1,0x80,0xff,0x8b,0xf8,0x62,0xff,0x50,0xf1,0x80,0xff,0x8b,0xff"
        "vt.default_grn=0x2a,0x55,0xfa,0xfa,0xbf,0x79,0xe9,0xf8,0x72,0x55,0xfa,0xfa,0xbf,0x79,0xe9,0xff"
        "vt.default_blu=0x36,0x55,0x7b,0x8c,0xff,0xc6,0xfd,0xf2,0xa4,0x55,0x7b,0x8c,0xff,0xc6,0xfd,0xff"
      ];
      services.ollama.enable = true;
      environment.systemPackages = with pkgs; [
        distrobox
        networkmanager-openconnect # For Cisco AnyConnect / GlobalProtect
        networkmanager-openvpn # For OpenVPN connections
        (pkgs.opencloud-desktop.overrideAttrs (old: {
          qtWrapperArgs = (old.qtWrapperArgs or [ ]) ++ [
            "--prefix"
            "NIXPKGS_QT6_QML_IMPORT_PATH"
            ":"
            "${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml"
            "--prefix"
            "NIXPKGS_QT6_QML_IMPORT_PATH"
            ":"
            "${pkgs.kdePackages.qqc2-desktop-style}/lib/qt-6/qml"
            "--prefix"
            "NIXPKGS_QT6_QML_IMPORT_PATH"
            ":"
            "${pkgs.kdePackages.qqc2-breeze-style}/lib/qt-6/qml"
          ];
        }))
      ];

      # Force git to use the school email
      home-manager.users.${myUserName} = { pkgs, lib, ... }: {
        home.homeDirectory = lib.mkForce "/home/${myUserName}-school";
        services.syncthing.enable = true;

        # Nascondi voci duplicate dal menu app (i programmi restano installati)
        home.file.".local/share/applications/brave-browser.desktop".text = "[Desktop Entry]\nType=Application\nName=Brave Web Browser\nExec=brave %U\nNoDisplay=true\n";
        home.file.".local/share/applications/com.brave.Browser.desktop".text = "[Desktop Entry]\nType=Application\nName=Brave Web Browser\nExec=brave %U\nNoDisplay=true\n";
        home.file.".local/share/applications/nvim.desktop".text = "[Desktop Entry]\nType=Application\nName=Neovim wrapper\nExec=nvim %F\nTerminal=true\nNoDisplay=true\n";
        home.file.".local/share/applications/user-nvim.desktop".text = "[Desktop Entry]\nType=Application\nName=Neovim (User)\nExec=nvim %F\nTerminal=true\nNoDisplay=true\n";
        home.file.".local/share/applications/opencloudcmd.desktop".text = "[Desktop Entry]\nType=Application\nName=OpenCloud Desktop (cmd)\nExec=opencloudcmd\nNoDisplay=true\n";

        # Nascondi Foot Client e Foot Server dal menu app
        home.file.".local/share/applications/footclient.desktop".text = "[Desktop Entry]\nType=Application\nName=Foot Client\nExec=footclient\nNoDisplay=true\n";
        home.file.".local/share/applications/foot-server.desktop".text = "[Desktop Entry]\nType=Application\nName=Foot Server\nExec=foot --server\nNoDisplay=true\n";

        # JavaKara (programma del prof, jar in .school-workspace/javakara)
        home.file.".local/share/applications/javakara.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=JavaKara
          Comment=JavaKara
          Exec=${pkgs.jdk}/bin/java -jar /home/${myUserName}-school/.school-workspace/javakara/javakara-x-en.jar
          Icon=application-x-java-archive
          Terminal=false
          Categories=Education;
        '';
        nixpkgs.config.allowUnfree = true;

        home.activation.createSchoolDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.school-workspace/projects || true
          mkdir -p $HOME/.school-workspace/year/1st/1-semester || true
          mkdir -p $HOME/.school-workspace/year/1st/2-semester || true
          mkdir -p $HOME/.school-workspace/year/2st/3-semester || true
          mkdir -p $HOME/.school-workspace/year/2st/4-semester || true
          mkdir -p $HOME/.school-workspace/year/3st/5-semester || true
          mkdir -p $HOME/.school-workspace/year/3st/6-semester || true
          mkdir -p $HOME/.school-workspace/momentary || true
          mkdir -p $HOME/.school-workspace/distrobox-bin || true
        '';

        # School distrobox exports go to isolated path (not ~/.distrobox-bin)
        home.sessionPath = [ "$HOME/.school-workspace/distrobox-bin" ];

        # Setup git identity for the school specialization
        programs.git = {
          enable = true;
          settings = {
            user.email = lib.mkForce schoolGitEmail;
            user.name = lib.mkForce schoolGitName;
          };
        };

        # 🐚 Workspace Alias (shell-agnostic via home.shellAliases)
        home.shellAliases = { school = "cd ~/.school-workspace"; };

        # On interactive shell start, check if distrobox tools are present
        programs.bash.initExtra = ''
          ${distroboxStartupCheck} 2>/dev/null
        '';

        home.packages = with pkgs; [
          # Required Tools
          alpaca # Chat grafica per Ollama
          jdk # Java Development Kit
          mars-mips # MIPS simulator (tecnica digitale)
          geogebra6 #Dynamic mathematics software with graphics, algebra and spreadsheets

          # CS Tools (useful)
          dbeaver-bin
          insomnia
          wireshark
          zeal
          rclone
          filezilla

          # CS Notes / Cheat Sheets - shared toolchain (Typst/LaTeX/Pandoc, diagrams, PDF/image tooling, spellcheck)
          typst
          typstyle
          tectonic
          pandoc
          haskellPackages.pandoc-crossref
          graphviz
          d2
          gnuplot
          poppler-utils
          ghostscript
          imagemagick
          qpdf
          librsvg
          inkscape
          jq
          hunspell
          hunspellDicts.en_US
          hunspellDicts.it_IT

          # CS Notes-specific extras (not in cs-cheat-sheets)
          tinymist
          plantuml
          mermaid-cli

          # CS Notes / Cheat Sheets - merged Python scientific/stats stack (union of both flakes)
          (python313.withPackages (ps: [
            ps.numpy
            ps.scipy
            ps.sympy
            ps.matplotlib
            ps.seaborn
            ps.pandas
            ps.statsmodels
            ps.scikit-learn
            ps.networkx
            ps.ipython
            ps.pygments
            ps.genanki
          ]))


          # Custom Shell Scripts
          (pkgs.writeShellScriptBin "brave-school" ''exec ${pkgs.brave}/bin/brave --user-data-dir=$HOME/.config/BraveSoftware/School "$@"'')
          (pkgs.makeDesktopItem {
            name = "brave-school";
            desktopName = "Brave (School)";
            exec = "brave-school %U";
            icon = "brave";
          })

          (pkgs.writeShellScriptBin "vscode-school" ''exec ${pkgs.vscode}/bin/code --ozone-platform=wayland --enable-features=WaylandWindowDecorations --user-data-dir=$HOME/.config/Code-School --extensions-dir=$HOME/.vscode-school/extensions "$@"'')
          (pkgs.makeDesktopItem {
            name = "vscode-school";
            desktopName = "VSCode (School)";
            exec = "vscode-school %F";
            icon = "vscode";
          })

          (pkgs.writeShellScriptBin "idea-school" ''
            export XDG_CONFIG_HOME=$HOME/.config/school-env
            export XDG_DATA_HOME=$HOME/.local/share/school-env
            export XDG_CACHE_HOME=$HOME/.cache/school-env
            exec ${pkgs.jetbrains.idea}/bin/idea "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "idea-school";
            desktopName = "IDEA (School)";
            exec = "idea-school";
            icon = "idea";
          })

          (pkgs.writeShellScriptBin "tkgate-school" ''
            ${pkgs.xhost}/bin/xhost +local: >/dev/null 2>&1
            export DISPLAY="''${DISPLAY:-:0}"

            # Xft.dpi lives in the X server's RESOURCE_MANAGER, shared by every
            # X11/Xwayland client on this DISPLAY (not just tkgate, and not
            # scoped to any one WM/compositor). Scope the override to this
            # invocation only: capture the current value, restore it on any
            # exit path (normal, error, or signal) via trap.
            origDpi=$(${pkgs.xrdb}/bin/xrdb -query 2>/dev/null | awk '/^Xft\.dpi:/{print $2}')
            origDpi="''${origDpi:-96}"
            restore_dpi() {
              ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: $origDpi" 2>/dev/null || true
            }
            trap restore_dpi EXIT INT TERM

            ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: ${xftDpi}" 2>/dev/null || true
            ${pkgs.distrobox}/bin/distrobox enter school-ubuntu -- bash -c '
              if ! command -v tkgate >/dev/null 2>&1; then
                echo "tkgate is not installed. Run: school-distrobox-setup"
                exit 1
              fi
              export DISPLAY="'"$DISPLAY"'"
              exec tkgate "$@"
            ' _ "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "tkgate-school";
            desktopName = "tkGate (Ubuntu)";
            exec = "tkgate-school";
            icon = "tkgate";
          })

          # Idempotent setup: creates containers and installs only what's missing.
          (pkgs.writeShellScriptBin "school-distrobox-setup" ''
            set -uo pipefail
            EXPORT_PATH="$HOME/.school-workspace/distrobox-bin"
            mkdir -p "$EXPORT_PATH"
            FAILURES=0

            container_exists() { ${pkgs.podman}/bin/podman container exists "$1" 2>/dev/null; }

            ${lib.concatMapStringsSep "\n\n" (app: ''
              # --- ${app.name} in ${app.container} ---
              echo "==> Checking ${app.name}..."
              if ! container_exists "${app.container}"; then
                echo "    Creating ${app.container}..."
                if ! distrobox create --name "${app.container}" --image "${app.image}" --yes; then
                  echo "    FAILED to create ${app.container}"
                  FAILURES=$((FAILURES + 1))
                fi
              fi
              if container_exists "${app.container}"; then
                if distrobox enter ${app.container} -- bash -c '${app.check}' &>/dev/null; then
                  echo "    ${app.name} already installed, skipping."
                else
                  ${lib.optionalString (app ? rootInit) ''
                  echo "    Running rootInit in ${app.container}..."
                  ${pkgs.podman}/bin/podman exec --user root ${app.container} bash -c '${app.rootInit}' || true
                  ''}
                  ${lib.optionalString (app ? preInstall) ''
                  echo "    Installing dependencies in ${app.container}..."
                  distrobox enter ${app.container} -- bash -c '${app.preInstall}' || true
                  ''}
                  echo "    Installing ${app.name}..."
                  if ! distrobox enter ${app.container} -- bash -c '${app.install}'; then
                    echo "    FAILED to install ${app.name}"
                    FAILURES=$((FAILURES + 1))
                  else
                    ${lib.optionalString (app ? postInstall) ''
                    distrobox enter ${app.container} -- bash -c '${app.postInstall}' || true
                    ''}
                    echo "    ${app.name} installed."
                  fi
                fi
              fi
            '') distroboxApps}

            if [ "$FAILURES" -gt 0 ]; then
              echo ""
              echo "==> $FAILURES tool(s) failed to provision."
              exit 1
            fi
            echo ""
            echo "==> All school distrobox tools are ready."
          '')

          # Deep check: verifies packages are actually installed inside containers
          (pkgs.writeShellScriptBin "school-distrobox-check" ''
            exec ${distroboxDeepCheck}
          '')

          # Nuclear cleanup: removes all school containers and the exported binaries.
          # Only reports what was actually removed - silent for things that didn't exist.
          (pkgs.writeShellScriptBin "school-distrobox-clear" ''
            set -uo pipefail
            REMOVED=""

            ${lib.concatMapStringsSep "\n" (app: ''
              if ${pkgs.podman}/bin/podman container exists "${app.container}" 2>/dev/null; then
                if ${pkgs.distrobox}/bin/distrobox rm "${app.container}" --force >/dev/null 2>&1; then
                  REMOVED="$REMOVED\n  - container: ${app.container}"
                fi
              fi
            '') distroboxApps}

            EXPORT_PATH="$HOME/.school-workspace/distrobox-bin"
            if [ -d "$EXPORT_PATH" ] && [ -n "$(ls -A "$EXPORT_PATH" 2>/dev/null)" ]; then
              FILES=$(ls -A "$EXPORT_PATH" | tr '\n' ' ')
              rm -rf "$EXPORT_PATH"/* "$EXPORT_PATH"/.[!.]* 2>/dev/null || true
              REMOVED="$REMOVED\n  - exported binaries in $EXPORT_PATH: $FILES"
            fi

            if [ -z "$REMOVED" ]; then
              echo "Nothing to clear - no school containers or exported binaries found."
            else
              echo -e "Removed:$REMOVED"
            fi
          '')
        ];

        # ------------------------------------------------------------
        # PROGRESSIVE WEB APPS & ISOLATED APPS
        # ------------------------------------------------------------
        xdg.desktopEntries =
          let
            makeSchoolPwa = name: url: icon: startupClass: {
              name = "school-pwa-${builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name)}";
              value = {
                name = name;
                genericName = "School Web App";
                comment = "Launch ${name}";
                exec = "brave-school --app=\"${url}\" --password-store=basic";
                icon = icon;
                settings = { StartupWMClass = startupClass; };
                terminal = false;
                type = "Application";
                categories = [ "Education" ];
                mimeType = [ "x-scheme-handler/https" "x-scheme-handler/http" ];
              };
            };
          in
          builtins.listToAttrs [
            (makeSchoolPwa "SUPSI Portal" "https://portalestudenti.supsi.ch/" "education" "brave-portalestudenti.supsi.ch__-Default")
            (makeSchoolPwa "iCorsi" "https://www.icorsi.ch/" "applications-education" "brave-www.icorsi.ch__-Default")
            (makeSchoolPwa "School OpenCloud" "https://opencloud.nicolkrit.ch/" "folder-cloud" "brave-opencloud.nicolkrit.ch__-Default")
            (makeSchoolPwa "NotebookLM" "https://notebooklm.google.com/" "utilities-terminal" "brave-notebooklm.google.com__-Default")
            (makeSchoolPwa "USI Rooms" "https://usirooms.xyz/" "office-calendar" "brave-usirooms.xyz__-Default")
            (makeSchoolPwa "Lecture Calendar" "https://calendar.google.com/calendar/u/0?cid=NDg0Zjg5MjUyOThlY2M0YzA2NWVkMTNhNGIwM2I4MjdlNTY0YWM5OWRlYjBjMDE0NThiNTZiOWY3MGY3ZmI5Y0Bncm91cC5jYWxlbmRhci5nb29nbGUuY29t" "x-office-calendar" "brave-calendar.google.com__-Default")
          ];
      };
    };
  };
}
