{ lib, config, pkgs, ... }: with lib; let
  profile = "default";
in {
  hm = {
    programs.firefox = {
      enable = true;
      # package = (pkgs.rev "64c27498901f104a11df646278c4e5c9f4d642db" "sha256-mU4mJeb1fRSvCDALe57vIKfhECvYroB4J4s0L2TR/iE=").firefox;
      profiles.${profile} = with config.theme; {
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
          french-dictionary
          tree-style-tab
          ublock-origin
          i-dont-care-about-cookies
          darkreader
          refined-github
          redirector # ^https:\/\/(.*?)\.m\.wikipedia\.org\/(.*) → https://$1.wikipedia.org/$2
                     # ^https:\/\/(.*?)\.m\.wiktionary\.org\/(.*) → https://$1.wiktionary.org/$2
                     # ^https:\/\/mobile\.twitter\.com\/(.*) → https://twitter.com/$1
          youtube-shorts-block
        ];
        settings = {
          "apz.gtk.touchpad_pinch.enabled" = false;
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
          "browser.startup.homepage" = "about:home";
          "browser.tabs.firefox-view" = false;
          "browser.tabs.tabmanager.enabled" = false;
          "browser.tabs.warnOnClose" = false;
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.uiCustomization.state" = ''{"placements":{"widget-overflow-fixed-list":[],"nav-bar":["back-button","forward-button","stop-reload-button","urlbar-container","save-to-pocket-button","bookmarks-menu-button","downloads-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["firefox-view-button","tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["personal-bookmarks"]},"dirtyAreaCache":["nav-bar","widget-overflow-fixed-list","toolbar-menubar","TabsToolbar","PersonalToolbar","unified-extensions-area"],"currentVersion":18,"newElementCount":14}'';
          "browser.urlbar.clickSelectsAll" = true;
          "browser.urlbar.doubleClickSelectsAll" = false;
          "browser.urlbar.maxRichResults" = "5";
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.searches" = false;
          "devtools.chrome.enabled" = true;
          "devtools.debugger.prompt-connection" = false;
          "devtools.debugger.remote-enabled" = true;
          "extensions.pocket.enabled" = false;
          "full-screen-api.warning.timeout" = "0";
          "general.autoScroll" = true;
          "general.warnOnAboutConfig" = false;
          "gfx.color_management.mode" = "0";
          "layers.acceleration.force-enabled" = true;
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

            .tabbrowser-tab[visuallyselected="true"] {
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

            #urlbar[focused="true"] {
              /*border-color: var(--cold) !important;
              transition: border-color 0.1s ease-in-out;*/
            }

            #urlbar:not(:-moz-lwtheme):not([focused="true"]) > #urlbar-background, #searchbar:not(:-moz-lwtheme):not(:focus-within) {
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

          @-moz-document domain(github.com) {
            .blob-num, .blob-code-inner, .highlight pre {
              font-family: monospace !important;
              font-size: 13px !important;
              vertical-align: middle !important;
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

          @-moz-document domain(1lab.dev) {
            @media (prefers-color-scheme: dark) {
              :root {
                --text-bg: #000000 !important;
                --text-fg: #ffffff !important;
              }
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
    };

    home.sessionVariables.MOZ_USE_XINPUT2 = "1";

    # https://firefox-source-docs.mozilla.org/devtools/backend/protocol.html
    # https://searchfox.org/mozilla-central/source/devtools/server/actors/style-sheets.js
    home.file.".mozilla/firefox/${profile}/chrome/userChrome.css".onChange = ''
      if cd ~/.mozilla/firefox/${profile} && pgrep firefox > /dev/null; then
        port=6001
        firefox --start-debugger-server "$port" || exit
        exec {ff}<>/dev/tcp/localhost/"$port"
        shopt -s lastpipe # for `jobs`
        while read -u "$ff" -rd : len && IFS= LC_ALL=C read -u "$ff" -rd "" -n "$len" json; do
          printf '%s\n' "$json"
        done |
        jq -cn --unbuffered --rawfile css chrome/userChrome.css '
          def expect(f): first(inputs | if has("error") then "error \(.error): \(.message)\n" | halt_error(1) else . end | f);
          {to: "root", type: "getProcess", id: 0},
          {to: expect(.processDescriptor.actor | values), type: "getTarget"}, (
          expect(.process.styleSheetsActor | values) as $styleSheetsActor |
          {to: $styleSheetsActor, type: "getStyleSheets"}, (
          expect(.styleSheets[]? | select(.href | values | endswith("userChrome.css")).actor) as $userChromeActor |
          {to: $styleSheetsActor, type: "update", resourceId: $userChromeActor, $css, transition: true}, (
          expect(select(.type == "styleApplied")) | halt
          )))
        ' | {
          while IFS= read -r json; do
            printf '%s:%s' "''${#json}" "$json"
          done >& "$ff"
          kill $(jobs -p)
        }
      fi || true
    '';
  };

  # work around https://github.com/NixOS/nix/issues/719
  system.extraDependencies = [ pkgs.nur.repo-sources.rycee ];
}
