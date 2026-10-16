{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "services.laptop.local-packages";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    let
      pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in


    # TODO: choose
    {
      users.users.${myconfig.constants.user}.packages =
        (with pkgs; [
          # -----------------------------------------------------------------------
          # 🖥️ DESKTOP APPLICATIONS
          # -----------------------------------------------------------------------
          drawio # Diagramming application
          gallery-dl # Command-line program to download image-galleries and -collections from several image hosting sites
          google-chrome # Freeware web browser developed by Google
          microsoft-edge # Web browser from Microsoft
          libreoffice-qt # Open source microsoft office alternative
          localsend # Simple file sharing over local network
          media-downloader # Qt/C++ GUI front end for yt-dlp and others
          obs-studio # Streaming/Recording
          syncthing # Continuous file synchronization
          teams-for-linux # Unofficial Microsoft Teams client
          vscode # Microsoft visual studio code IDE
          vesktop # Discord client
          vlc # Media player

          # -----------------------------------------------------------------------------------
          # 🖥️ CLI UTILITIES
          # -----------------------------------------------------------------------------------
          distrobox-tui # TUI for DistroBox
          hwinfo # Hardware detection tool from openSUSE
          gh # GitHub CLI tool
          tealdeer # Fast implementation of tldr (simplified man pages)

          # -----------------------------------------------------------------------------------
          # 🧑🏽‍💻 CODING
          # -----------------------------------------------------------------------------------
          github-desktop # GitHub's official desktop client
          zeal # Offline documentation browser

          (pkgs.python313.withPackages (
            ps: with ps; [
              faker # Generate fake data
            ]
          ))

          # -----------------------------------------------------------------------------------
          # 😂 FUN PACKAGES
          # -----------------------------------------------------------------------------------
          asciinema # Record and share terminal sessions
          cbonsai # Grow bonsai trees in your terminal
          neo-cowsay # Cowsay reborn (ASCII art with text)
          pipes # Terminal pipes animation

          # -----------------------------------------------------------------------------------
          # 🏠 GENERAL
          # -----------------------------------------------------------------------------------
          fd
          killall
          pay-respects
          ripgrep
          tmate
          tree
          unzip
          yt-dlp
          zip
          zlib

          # -----------------------------------------------------------------------
          # ❓ OTHER
          # -----------------------------------------------------------------------
        ])

        ++ (with pkgs-unstable; [
          # -----------------------------------------------------------------------
          # ⚠️ UNSTABLE PACKAGES (Bleeding Edge)
          # -----------------------------------------------------------------------
        ]);
    };
}
