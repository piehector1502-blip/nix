{ delib, ... }:
# ⚠ CLOSE ZEN BEFORE REBUILD when modifying this file.
delib.module {
  name = "programs.zen.browser";

  home.ifEnabled = { ... }: {
    programs.zen-browser.profiles.default = {
      pinsForce = true;
      pins = {

        "University resources" = {
          id = "30000000-0000-4000-8000-000000000041";
          isGroup = true;
          folderIcon = "🎓";
          workspace = "10000000-0000-4000-8000-000000000004";
          position = 200;
        };
        "Personal resources" = {
          id = "30000000-0000-4000-8000-000000000042";
          isGroup = true;
          folderIcon = "📔";
          workspace = "10000000-0000-4000-8000-000000000004";
          position = 300;
        };
        "iCorsi Essential" = {
          id = "20000000-0000-4000-8000-000000000014";
          title = "iCorsi";
          url = "https://www.icorsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          position = 100;
          isEssential = true;
        };
        "Portale Studenti Essential" = {
          id = "20000000-0000-4000-8000-000000000015";
          title = "Portale Studenti";
          url = "https://portalestudenti.supsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          position = 101;
          isEssential = true;
        };
        "iCorsi" = {
          id = "40000000-0000-4000-8000-000000000071";
          url = "https://www.icorsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000041";
          position = 101;
        };
        "Portale Studenti" = {
          id = "40000000-0000-4000-8000-000000000072";
          url = "https://portalestudenti.supsi.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000041";
          position = 102;
        };
        "OpenCloud" = {
          id = "40000000-0000-4000-8000-000000000081";
          url = "https://opencloud.nicolkrit.ch/";
          container = 4; # University
          workspace = "10000000-0000-4000-8000-000000000004";
          folderParentId = "30000000-0000-4000-8000-000000000042";
          position = 101;
        };
      };
    };
  };
}
