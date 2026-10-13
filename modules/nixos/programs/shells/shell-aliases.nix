{ delib, moduleSystem, lib, pkgs, ... }:
delib.module {
  name = "programs.shell-aliases";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig, ... }:
    let
      pythonEnv = pkgs.python3.withPackages (ps: [ ps.requests ]);
      npu = pkgs.writeShellScriptBin "npu" ''
        export NIX_PREFETCH_URL="${pkgs.nix}/bin/nix-prefetch-url"
        exec ${pythonEnv}/bin/python3 ${./npu.py} "$@"
      '';

      tpmReenroll = pkgs.writeShellScriptBin "tpm-reenroll" ''
        set -euo pipefail
        pcrs="0+2+7"
        mappers=$(${pkgs.util-linux}/bin/lsblk -rno NAME,TYPE \
          | ${pkgs.gawk}/bin/awk '$2=="crypt"{print $1}')
        if [ -z "$mappers" ]; then
          echo "No active LUKS/crypt devices found - nothing to do."
          exit 0
        fi
        sudo -v
        for name in $mappers; do
          dev=$(sudo ${pkgs.cryptsetup}/bin/cryptsetup status "$name" \
            | ${pkgs.gawk}/bin/awk '/device:/{print $2}')
          [ -z "$dev" ] && { echo "Could not resolve backing device for '$name', skipping."; continue; }
          echo "Re-enrolling TPM2 (PCRs $pcrs) for $name -> $dev"
          sudo ${pkgs.systemd}/bin/systemd-cryptenroll --wipe-slot=tpm2 "$dev" || true
          sudo ${pkgs.systemd}/bin/systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs="$pcrs" "$dev"
        done
        echo "Done. Reboot to confirm auto-unlock."
      '';

      flakeDir = "~/nix";
      isImpure = myconfig.constants.nixImpure or false;
      isNixOS = moduleSystem == "nixos";
      isHome = moduleSystem == "home";

      nixosSwitchCmd =
        if isImpure then "sudo nixos-rebuild switch --flake . --impure" else "nh os switch ${flakeDir}";

      nixosUpdateCmd =
        if isImpure then
          "nix flake update && sudo nixos-rebuild switch --flake . --impure"
        else
          "nh os switch --update ${flakeDir}";

      nixosBootCmd =
        if isImpure then
          "sudo nixos-rebuild boot --flake . --impure"
        else
          "nh os boot ${flakeDir}";

      nixosTestCmd =
        if isImpure then
          "sudo nixos-rebuild test --flake . --impure"
        else
          "nh os test ${flakeDir}";

      cachixEnabled =
        (myconfig.cachix.enable or false) && (myconfig.cachix.push or false);

      cName = myconfig.cachix.name;
      cachixTokenPath = myconfig.cachix.authTokenPath or "";
      cachixPush =
        if cachixTokenPath != "" then
          "nix path-info -r /run/current-system | env CACHIX_AUTH_TOKEN=$(cat ${cachixTokenPath}) cachix push ${cName}"
        else
          "nix path-info -r /run/current-system | cachix push ${cName}";

      shc = script: "sh -c ${lib.escapeShellArg script}";

      cachixPushAlias = shc cachixPush;

      wrapCaches =
        cmd:
        let
          pushLines = lib.optional cachixEnabled "${cachixPush} || true";
        in
        if pushLines == [ ] then cmd
        else "${cmd} && ${shc (lib.concatStringsSep "; " pushLines)}";

      nixosSwitchWrapped = wrapCaches nixosSwitchCmd;
      nixosUpdateWrapped = wrapCaches nixosUpdateCmd;
      nixosBootWrapped = wrapCaches nixosBootCmd;

      commonAliases = {
        cleanup = "nix-sweep -p default system";
        cleanup-ask = "nix-sweep -p ask system";
        dedup = "nix store optimise";
        cg = "nix-collect-garbage -d";
        nix-gc-roots = "nix-store --gc --print-roots";
        # pinned to v1.3.2: deadnix HEAD (as of ~2026-09-05) fails to build, its flake.lock bumped nixpkgs and its own src trips clippy::pedantic; unpin once upstream fixes or a newer working tag ships
        deadnixfixall = "nix run github:astro/deadnix/v1.3.2 -- -e ${flakeDir}";
        deadnixscanall = "nix run github:astro/deadnix/v1.3.2 -- ${flakeDir}";

        fmt-dry = "cd ${flakeDir} && git add -A && nix fmt -- --check";
        fmt = "cd ${flakeDir} && git add -A && nix fmt";
        cdnix = "cd ${flakeDir}";

        fzf-prev = ''fzf --preview="cat {}"'';
        fzf-editor = "$EDITOR $(fzf -m --preview='cat {}')";
        zlist = "zoxide query -l -s";
        tksession = "tmux kill-session -t";
        tks = "tmux kill-server";
      };

      nixosAliases = {
        swboot = "cd ${flakeDir} && git add -A && ${nixosBootWrapped}";
        swtest = "cd ${flakeDir} && git add -A && ${nixosTestCmd}";
        swdry = "cd ${flakeDir} && git add -A && nh os switch ${flakeDir} --dry";
        sw = "cd ${flakeDir} && ${nixosSwitchWrapped}";
        swfall = "cd ${flakeDir} && ${wrapCaches "${nixosSwitchCmd} --fallback"}";
        gsw = "cd ${flakeDir} && git add -A && ${nixosSwitchWrapped}";
        gswfall = "cd ${flakeDir} && git add -A && ${wrapCaches "${nixosSwitchCmd} --fallback"}";
        gswoff = "cd ${flakeDir} && git add -A && nh os switch ${flakeDir} -- --offline";
        swsrc = "cd ${flakeDir} && git add -A && ${wrapCaches "${nixosSwitchCmd} --option substitute false"}";
        swoff = "cd ${flakeDir} && nh os switch ${flakeDir} -- --offline";
        tswsrc = "cd ${flakeDir} && git add -A && time ${wrapCaches "${nixosSwitchCmd} --option substitute false"}";

        nfc = "cd ${flakeDir} && git add -A && nix flake check";
        nfcall = "cd ${flakeDir} && git add -A && nix flake check --all-systems";
        upd = "cd ${flakeDir} && git add -A && ${nixosUpdateWrapped}";

        swpure = "cd ${flakeDir} && git add -A && nh os switch ${flakeDir}";
        swimpure = "cd ${flakeDir} && git add -A && sudo nixos-rebuild switch --flake . --impure";

        pkgs-home = "$EDITOR ${flakeDir}/modules/nixos/toplevel/home-packages-nixos.nix";
        pkgs-host = "$EDITOR ${flakeDir}/hosts/${myconfig.constants.hostname}/local-packages.nix";

        se = "sudoedit";
        reb-uefi = "systemctl reboot --firmware-setup";
      }
      // (lib.optionalAttrs cachixEnabled { cachix-push = cachixPushAlias; });

      homeAliases = {
        sw = "cd ${flakeDir} && home-manager switch -b hm-backup --flake .#${myconfig.constants.user}@${myconfig.constants.hostname}";
        gsw = "cd ${flakeDir} && git add -A && home-manager switch -b hm-backup --flake .#${myconfig.constants.user}@${myconfig.constants.hostname}";
        swdry = "cd ${flakeDir} && git add -A && home-manager build --flake .#${myconfig.constants.user}@${myconfig.constants.hostname}";
        upd = "cd ${flakeDir} && git add -A && nix flake update && home-manager switch -b hm-backup --flake .#${myconfig.constants.user}@${myconfig.constants.hostname}";
        hm-gens = "home-manager generations";
        nfc = "cd ${flakeDir} && git add -A && nix flake check";
      };

    in
    {
      home.packages = [ npu ] ++ lib.optionals isNixOS [ tpmReenroll ];

      home.shellAliases = commonAliases
        // (if isNixOS then nixosAliases else { })
        // (if isHome then homeAliases else { })
        // lib.optionalAttrs (myconfig.services.snapshots.enable or false) (
        {
          snap-list-home = "snapper -c home list";
          snap-list-root = "sudo snapper -c root list";
        }
      );
    };
}
