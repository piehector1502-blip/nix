{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default.settings = {
      # Required for isEssential pins (in pins.nix) to display correctly.
      "zen.window-sync.enabled" = true;
      "zen.window-sync.sync-only-pinned-tabs" = true;

      # Required so declaratively installed extensions are enabled without a prompt.
      "extensions.autoDisableScopes" = 0;

      # TODO: add your own about:config prefs
    };
  };
}
