{ delib, ... }:
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default.search = {
      force = true;
      engines = {
        # TODO: add your own, e.g.
        # "kagi" = {
        #   urls = [{ template = "https://kagi.com/search?q={searchTerms}"; }];
        #   definedAliases = [ "@k" ];
        # };
      };
    };
  };
}
