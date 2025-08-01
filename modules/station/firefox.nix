{ lib, config, pkgs, ... }: with lib; {
  hm = {
    programs.firefox = {
      enable = true;
      languagePacks = [ "en-GB" ];
      profiles.default = with config.theme; {
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          french-dictionary
          british-english-dictionary-2
          ublock-origin
          cookies-txt
          darkreader
          refined-github
          redirector # ^https:\/\/(.*?)\.m\.wikipedia\.org\/(.*) → https://$1.wikipedia.org/$2
                     # ^https:\/\/(.*?)\.m\.wiktionary\.org\/(.*) → https://$1.wiktionary.org/$2
          video-resumer
          uppity
          zotero-connector
        ];
        settings = {
          "accessibility.typeaheadfind.autostart" = false;
          "accessibility.typeaheadfind.manual" = false;
          "apz.gtk.touchpad_pinch.enabled" = false;
          "browser.aboutConfig.showWarning" = false;
          "browser.download.alwaysOpenPanel" = false;
          "browser.download.always_ask_before_handling_new_types" = true;
          "browser.fixup.alternate.enabled" = false;
          "browser.gesture.swipe.left" = "";
          "browser.gesture.swipe.right" = "";
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.showSearch" = false;
          "browser.newtabpage.activity-stream.showTopSites" = false;
          "browser.newtabpage.enhanced" = false;
          "browser.onboarding.enabled" = false;
          "browser.sessionstore.restore_on_demand" = false;
          "browser.sessionstore.restore_tabs_lazily" = true;
          "browser.startup.homepage" = "about:home";
          "browser.tabs.firefox-view" = false;
          "browser.tabs.firefox-view-next" = false;
          "browser.tabs.hoverPreview.enabled" = false;
          "browser.tabs.tabmanager.enabled" = false;
          "browser.tabs.warnOnClose" = false;
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.translations.automaticallyPopup" = false;
          "browser.uiCustomization.state" = ''{"placements":{"widget-overflow-fixed-list":[],"unified-extensions-area":["ublock0_raymondhill_net-browser-action","_a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad_-browser-action","redirector_einaregilsson_com-browser-action","jid1-kkzogwgsw3ao4q_jetpack-browser-action","treestyletab_piro_sakura_ne_jp-browser-action","_34daeb50-c2d2-4f14-886a-7160b24d66a4_-browser-action","addon_darkreader_org-browser-action"],"nav-bar":["back-button","forward-button","stop-reload-button","urlbar-container","save-to-pocket-button","bookmarks-menu-button","downloads-button","unified-extensions-button","reset-pbm-toolbar-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["personal-bookmarks"]},"seen":["_a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad_-browser-action","redirector_einaregilsson_com-browser-action","jid1-kkzogwgsw3ao4q_jetpack-browser-action","treestyletab_piro_sakura_ne_jp-browser-action","_34daeb50-c2d2-4f14-886a-7160b24d66a4_-browser-action","addon_darkreader_org-browser-action","ublock0_raymondhill_net-browser-action","developer-button"],"dirtyAreaCache":["nav-bar","widget-overflow-fixed-list","toolbar-menubar","TabsToolbar","PersonalToolbar","unified-extensions-area"],"currentVersion":20,"newElementCount":14}'';
          "browser.urlbar.clickSelectsAll" = true;
          "browser.urlbar.doubleClickSelectsAll" = false;
          "browser.urlbar.maxRichResults" = "5";
          "browser.urlbar.scotchBonnet.enableOverride" = false;
          "browser.urlbar.showSearchTerms.enabled" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.searches" = false;
          "devtools.chrome.enabled" = true;
          "devtools.debugger.prompt-connection" = false;
          "devtools.debugger.remote-enabled" = true;
          "extensions.pocket.enabled" = false;
          "full-screen-api.warning.timeout" = 0;
          "general.autoScroll" = true;
          "gfx.color_management.mode" = "0";
          "layers.acceleration.force-enabled" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "middlemouse.paste" = false;
          "network.trr.mode" = "5";
          "places.history.expiration.max_pages" = "9999999";
          "privacy.donottrackheader.enabled" = true;
          "security.dialog_enable_delay" = "0";
          "security.fileuri.strict_origin_policy" = false;
          "security.mixed_content.block_active_content" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "widget.gtk.overlay-scrollbars.enabled" = false;
        };
        userChrome = ''
          @-moz-document url(chrome://browser/content/browser.xul), url(chrome://browser/content/browser.xhtml) {
            :root {
              --bg: ${background};
              --bg-alt: ${backgroundAlt};
              --bg-hover: hsla(0, 100%, 100%, .1);
              --bg-active: hsla(0, 100%, 100%, .15);
              --fg: ${foreground};
              --fg-alt: ${foregroundAlt};
              --cold: ${cold};
              --hot: ${hot};
              --font: ${font};
              --font-size: ${toString fontSize}pt;

              --toolbar-bgcolor: var(--bg) !important;
              --toolbar-non-lwt-bgcolor: var(--bg) !important;
              --toolbar-non-lwt-bgimage: none !important;
              --toolbar-non-lwt-textcolor: var(--fg) !important;
              --toolbar-field-focus-border-color: var(--cold) !important;
              --autocomplete-popup-highlight-background: var(--cold) !important;
              --autocomplete-popup-highlight-color: var(--bg) !important;
              --tab-min-height: 28px !important;
              --tabs-border-color: transparent !important;
              --tabs-top-border-width: 0px !important;
              --toolbarbutton-hover-background: var(--bg-hover) !important;
              --toolbarbutton-active-background: var(--bg-active) !important;
              --toolbarbutton-border-radius: 0px !important;
              --backbutton-background: transparent !important;
              --backbutton-border-color: transparent !important;
            }

            ::selection {
              background-color: var(--cold) !important;
              color: var(--bg) !important;
            }

            #titlebar {
              background-color: transparent !important;
            }

            #tabbrowser-tabs {
              border-inline-start: none !important;
              padding-inline-start: 0 !important;
              margin-inline-start: 0 !important;
            }

            .tabbrowser-tab {
              color: var(--fg-alt) !important;
              font-family: var(--font) !important;
              font-size: var(--font-size) !important;
            }

            .tabbrowser-tab[fadein]:not([pinned="true"]) {
              max-width: 100% !important;
            }

            .tabbrowser-tab::after,
            .tabbrowser-tab::before {
              border: none !important;
            }

            .tabbrowser-tab[visuallyselected] {
              color: var(--fg) !important;
            }

            .tab-throbber[progress]::before {
              fill: var(--cold) !important;
            }

            .tab-icon-image {
              margin-inline-end: 10px !important;
              margin-top: 0px !important;
            }

            .tab-background,
            .tab-line {
              display: none !important;
            }

            .tabbrowser-tab:not(:hover) .tab-close-button {
              display: none !important;
            }

            .tabs-newtab-button {
              fill: var(--fg) !important;
            }

            #nav-bar {
              color: var(--fg) !important;
              box-shadow: none !important;
              border: none !important;
            }

            #back-button {
              padding: 0px !important;
            }

            #identity-box #connection-icon {
              fill: var(--cold) !important;
            }

            #urlbar[pageproxystate="valid"] > #identity-box.verifiedIdentity,
            #urlbar[pageproxystate="valid"] > #identity-box.chromeUI,
            #urlbar[pageproxystate="valid"] > #identity-box.extensionPage,
            #urlbar-display-box {
              border: none !important;
            }

            #identity-box.verifiedIdentity #identity-icon-labels {
              margin-left: 5px !important;
              color: var(--cold) !important;
            }

            #tracking-protection-icon-container {
              border-inline-end: none !important;
            }

            #remote-control-icon {
              display: none !important;
            }

            #urlbar {
              background: var(--bg) !important;
              color: var(--fg) !important;
              font-family: var(--font) !important;
              font-size: var(--font-size) !important;
              border-color: transparent !important;
              transition: border-color 0.1s ease-in-out;
            }

            #urlbar:not(:-moz-lwtheme):not([focused]) > #urlbar-background, #searchbar:not(:-moz-lwtheme):not(:focus-within) {
              border: none !important;
            }

            #urlbar *|*.textbox-input::-moz-placeholder {
              color: transparent !important;
            }

            .urlbar-icon:hover:not([disabled]), .urlbar-icon-wrapper:hover:not([disabled]) {
              background-color: var(--bg-hover) !important;
            }

            #urlbar-background {
              background: transparent !important;
            }

            .urlbarView-tags, .urlbarView-url, .urlbarView-title:not(:empty) ~ .urlbarView-action {
              font-size: var(--font-size) !important;
            }

            .urlbarView-row[label="Firefox Suggest"] {
              margin-block-start: 0 !important;
            }
            .urlbarView-row[label="Firefox Suggest"]::before {
              display: none !important;
            }

            .bookmark-item {
              padding: 4px !important;
            }

            #navigator-toolbox {
              background-color: var(--bg) !important;
              border: none !important;
            }

            .ac-separator,
            .ac-url,
            .ac-action {
              color: var(--cold) !important;
            }

            .search-one-offs {
              display: none !important;
            }

            .toolbarbutton-animatable-box, .toolbarbutton-1 {
              fill: var(--fg) !important;
            }
          }
        '';
        userContent = ''
          :root {
            --bg: ${background};
            --bg-alt: ${backgroundAlt};
            --bg-hover: hsla(0, 100%, 100%, .1);
            --bg-active: hsla(0, 100%, 100%, .15);
            --fg: ${foreground};
            --fg-alt: ${foregroundAlt};
            --cold: ${cold};
            font-variant-ligatures: none !important;
          }

          @-moz-document media-document(all) {
            body {
              background-image: none !important;
              background-color: var(--bg) !important;
            }
          }

          @-moz-document url(about:home), url(about:newtab), url(about:privatebrowsing) {
            html, body {
              background: var(--bg) !important;
            }

            body {
              display: none !important;
            }
          }

          @-moz-document url(about:blank) {
            html, body {
              background: var(--bg) !important;
            }
          }

          @-moz-document domain(adventofcode.com) {
            body {
              font-size: 12pt !important;
            }

            article {
              width: 75em !important;
            }
          }

          @-moz-document domain(ncatlab.org) {
            body {
              font-family: serif !important;
            }

            h1, h2, h3, h4, h5, h6 {
              font-family: Alice, serif !important;
            }

            math, mtext {
              font-family: serif !important;
            }

            :target {
              background-color: #ddd !important;
            }
          }
        '';
      };
      profiles.work = {
        id = 1;
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          french-dictionary
          ublock-origin
          refined-github
        ];
        settings = {
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
        inherit (config.hm.programs.firefox.profiles.default) userContent;
      };
    };

    home.sessionVariables.MOZ_USE_XINPUT2 = "1";

    # https://firefox-source-docs.mozilla.org/devtools/backend/protocol.html
    # https://searchfox.org/mozilla-central/source/devtools/server/actors/style-sheets.js
    home.file.".mozilla/firefox/default/chrome/userChrome.css".onChange = ''
      if ${getBin pkgs.procps}/bin/pgrep firefox > /dev/null; then
        timeout 10s ${pkgs.firefox-refresh-user-chrome}/bin/firefox-refresh-user-chrome
      fi
    '';

    home.packages = with pkgs; [ firefox-refresh-user-chrome ];
  };

  nixpkgs.overlays = [ (self: super: {
    firefox-refresh-user-chrome = pkgs.shellScriptWith "firefox-refresh-user-chrome" {
      deps = with pkgs; [ firefox jq ];
    } ''
      verbose=0
      if [[ $1 == -v ]]; then
        verbose=1
          shift
      fi
      port=''${1:-6001}

      firefox --start-debugger-server "$port" || exit 0
      exec {ff}<>/dev/tcp/localhost/"$port"
      shopt -s lastpipe # for `jobs`

      while read -u "$ff" -rd : len && IFS= LC_ALL=C read -u "$ff" -rd "" -n "$len" json; do
        printf '%s\n' "$json"
        (( verbose )) && printf '<== %s\n' "$json" >&2
      done |
      jq -cn --unbuffered --rawfile text ~/.mozilla/firefox/default/chrome/userChrome.css '
        def expect(f): first(inputs | if has("error") then "error \(.error): \(.message)\n" | halt_error(1) else . end | f);
        {to: "root", type: "getProcess", id: 0}, (
        expect(.processDescriptor.actor | values) as $process |
        {to: $process, type: "getTarget"}, (
        expect(.process.styleSheetsActor | values) as $styleSheets |
        {to: $process, type: "getWatcher"}, (
        expect(select(.from == $process) | .actor | values) as $watcher |
        {to: $watcher, type: "watchResources", resourceTypes: ["stylesheet"]}, (
        expect(.array[]?[1][] | select(.href | values | endswith("/userChrome.css")).resourceId) as $userChrome |
        {to: $styleSheets, type: "update", resourceId: $userChrome, $text, transition: false}, (
        expect(.array[]?[1][] | select(.updateType == "style-applied" and .resourceId == $userChrome)) |
        halt
        )))))
      ' | {
        while IFS= read -r json; do
          printf '%s:%s' "''${#json}" "$json"
          (( verbose )) && printf '==> %s\n' "$json" >&2
        done >& "$ff"
        kill $(jobs -p) 2> /dev/null
      } || (( ! PIPESTATUS[1] ))
    '';
  }) ];

  # work around https://github.com/NixOS/nix/issues/719
  system.extraDependencies = [ pkgs.nur.repo-sources.rycee ];
}
