{
  description = "NixOS configuration with a single host, denix, cachix";

  outputs =
    { denix, nixpkgs, ... }@inputs:
    let
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs allSystems;

      baseExclude = [

        # hardware-configuration.nix is a plain module imported explicitly by system.nix
        ./hosts/nixos-laptop/hardware-configuration.nix

        # Any `disko` must be excluded
        ./hosts/nixos-laptop/disko-config-btrfs.nix
      ];

      # Home-manager-only hosts (no NixOS system config - excluded from nixos
      # builds only, since they have no filesystems/bootloader/hardware-configuration
      # and would break `nixosConfigurations.<name>` / `nix flake check`).
      homeOnlyHosts = [
      ];

      mkConfigurations =
        moduleSystem:
        denix.lib.configurations {
          inherit moduleSystem;
          homeManagerUser = "pierre";

          extensions = with denix.lib.extensions; [
            args
            (base.withConfig {
              args.enable = true;
              rices.enable = false;
            })
          ];

          paths = [
            ./hosts
            ./modules/nixos
            ./packages
          ];

          exclude = baseExclude ++ (if moduleSystem == "nixos" then homeOnlyHosts else [ ]);

          specialArgs = { inherit inputs moduleSystem; };
        };

      generatedNixosConfigs = mkConfigurations "nixos";
    in
    {
      nixosConfigurations = generatedNixosConfigs;
      homeConfigurations = mkConfigurations "home";
      formatter = nixpkgs.lib.genAttrs allSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      topology = forAllSystems (
        system:
        import inputs.nix-topology {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ inputs.nix-topology.overlays.default ];
          };
          modules = [
            { nixosConfigurations = generatedNixosConfigs; }
          ];
        }
      );
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-topology.url = "github:oddlama/nix-topology";
    claude-code.url = "github:sadjow/claude-code-nix";
    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-cowork-service.url = "github:patrickjaja/claude-cowork-service";
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    herdr = {
      url = "github:ogulcancelik/herdr/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Full NUR for nltch repo packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned upstream for spotify-adblock; flake.lock tracks the commit automatically
    spotify-adblock-src = {
      url = "github:abba23/spotify-adblock";
      flake = false;
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-community plasma manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openlogi = {
      url = "github:AprilNEA/OpenLogi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # x86_64-linux only (meta.platforms)
    skwd-wall = {
      url = "github:liixini/skwd-wall/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    vicinae.url = "github:vicinaehq/vicinae";
    vicinae-extensions.url = "github:vicinaehq/extensions";

    sidra = {
      url = "github:wimpysworld/sidra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-yazi-plugins = {
      url = "github:lordkekz/nix-yazi-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    concord = {
      url = "github:chojs23/concord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tgt.url = "github:FedericoBruzzone/tgt";

    # README explicitly states: "Neither the module nor the overlay uses this
    # input. To download less, set nix-doom-emacs-unstraightened.inputs.nixpkgs.follows = '';"
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
    };
  };

}
