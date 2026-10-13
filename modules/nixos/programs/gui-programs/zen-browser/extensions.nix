{ delib, inputs, pkgs, lib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }:
    let
      buildFirefoxXpiAddon = lib.makeOverridable (
        { stdenv ? pkgs.stdenv
        , fetchurl ? pkgs.fetchurl
        , pname
        , version
        , addonId
        , url
        , sha256
        , meta
        , ...
        }:
        stdenv.mkDerivation {
          name = "${pname}-${version}";
          inherit meta;
          src = fetchurl { inherit url sha256; };
          preferLocalBuild = true;
          allowSubstitutes = true;
          passthru = { inherit addonId; };
          buildCommand = ''
            dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
            mkdir -p "$dst"
            install -v -m644 "$src" "$dst/${addonId}.xpi"
          '';
        }
      );

      addons = pkgs.callPackage inputs.firefox-addons {
        buildMozillaXpiAddon = buildFirefoxXpiAddon;
      };
    in
    {
      programs.zen-browser.profiles.default.extensions.packages = with addons; [
        # TODO: add your own, e.g. ublock-origin
      ];

      # ── Normal (policy-based) extensions ────────────────────────────────────
      # programs.zen-browser.policies.ExtensionSettings = {
      #   "extension-id@example.com" = {
      #     install_url = "https://addons.mozilla.org/firefox/downloads/latest/slug/latest.xpi";
      #     installation_mode = "force_installed";
      #   };
      # };
    };
}
