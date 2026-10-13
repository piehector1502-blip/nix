{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default.mods = [
      # TODO: add your own, e.g. "<mod-uuid>" # Mod name
    ];
  };
}
