{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default = {
      # ── Containers (cookie isolation, like separate browser profiles) ───────
      # Icons must be predefined Firefox strings, not emoji.
      containersForce = true;
      containers = {
        "General" = {
          id = 1;
          color = "green";
          icon = "circle";
        };
        "University" = {
          id = 4;
          color = "turquoise";
          icon = "tree";
        };
      };

      spacesForce = true;
      spaces = {
        "General" = {
          id = "10000000-0000-4000-8000-000000000001";
          position = 1000;
          icon = "🏠️";
          container = 1;
        };
        "University" = {
          id = "10000000-0000-4000-8000-000000000004";
          position = 4000;
          icon = "📚️";
          container = 4;
        };
      };
    };
  };
}
