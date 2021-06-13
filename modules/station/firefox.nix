{ lib, pkgs, ... }: {
  hm = {
    programs.firefox = {
      enable = true;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        darkreader
      ];
      profiles.default = with lib.theme; {
        settings = {
          "browser.fixup.alternate.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.showSearch" = false;
          "browser.newtabpage.activity-stream.showTopSites" = false;
          "browser.newtabpage.enhanced" = false;
          "browser.onboarding.enabled" = false;
          "browser.startup.homepage" = "about:home";
          "browser.tabs.warnOnClose" = false;
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.uiCustomization.state" = ''{"placements":{"widget-overflow-fixed-list":["ublock0_raymondhill_net-browser-action","contact_lesspass_com-browser-action","addon_darkreader_org-browser-action"],"nav-bar":["back-button","forward-button","stop-reload-button","urlbar-container","downloads-button","bookmarks-menu-button"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["personal-bookmarks","managed-bookmarks"]},"seen":["developer-button","ublock0_raymondhill_net-browser-action","contact_lesspass_com-browser-action","addon_darkreader_org-browser-action"],"dirtyAreaCache":["PersonalToolbar","nav-bar","TabsToolbar","toolbar-menubar","widget-overflow-fixed-list"],"currentVersion":16,"newElementCount":7}'';
          "browser.urlbar.clickSelectsAll" = true;
          "browser.urlbar.doubleClickSelectsAll" = false;
          "browser.urlbar.maxRichResults" = "5";
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.searches" = false;
          "devtools.debugger.prompt-connection" = false;
          "extensions.pocket.enabled" = false;
          "full-screen-api.warning.timeout" = "0";
          "general.autoScroll" = true;
          "general.warnOnAboutConfig" = false;
          "gfx.color_management.mode" = "0";
          "gfx.e10s.font-list.shared" = false; # workaround for https://bugzilla.mozilla.org/show_bug.cgi?id=1714282
          "layers.acceleration.force-enabled" = true;
          "network.trr.mode" = "5";
          "security.dialog_enable_delay" = "0";
          "security.fileuri.strict_origin_policy" = false;
          "security.mixed_content.block_active_content" = false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        };
        userChrome = ''
          @-moz-document url(chrome://browser/content/browser.xul), url(chrome://browser/content/browser.xhtml) {
            :root {
              --bg: ${background};
              --bg-hover: hsla(0, 100%, 100%, .1);
              --bg-active: hsla(0, 100%, 100%, .15);
              --fg: ${foreground};
              --fg-inactive: ${foregroundAlt};
              --green: ${cold};
              --blue: ${cold};
              --font: ${font};
              --font-size: 10px;

              --toolbar-non-lwt-bgcolor: var(--bg) !important;
              --toolbar-non-lwt-bgimage: none !important;
              --toolbar-non-lwt-textcolor: var(--fg) !important;
              --tabs-border-color: transparent !important;
            }

            ::selection {
              background-color: var(--blue);
              color: var(--fg);
            }

            toolbar {
              --tab-min-height: 28px !important;
              --tabs-border-color: transparent !important;
              --tabs-top-border-width: 0px !important;
              --toolbarbutton-hover-background: var(--bg-hover) !important;
              --toolbarbutton-active-background: var(--bg-active) !important;
              --toolbarbutton-border-radius: 0px !important;
              --backbutton-background: transparent !important;
              --backbutton-border-color: transparent !important;
            }

            #tabbrowser-tabs {
              background: var(--toolbar-bgcolor) !important;
            }

            .tabbrowser-tab {
              color: var(--fg-inactive) !important;
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
              fill: var(--blue) !important;
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
            }

            #back-button {
              padding: 0px !important;
            }

            #identity-box #connection-icon {
              fill: var(--green) !important;
            }

            #urlbar[pageproxystate="valid"] > #identity-box.verifiedIdentity,
            #urlbar[pageproxystate="valid"] > #identity-box.chromeUI,
            #urlbar[pageproxystate="valid"] > #identity-box.extensionPage,
            #urlbar-display-box {
              border: none !important;
            }

            #identity-box.verifiedIdentity #identity-icon-labels {
              margin-left: 5px !important;
              color: var(--green) !important;
            }

            #tracking-protection-icon-container {
              border-inline-end: none !important;
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
              border-color: var(--blue) !important;
              transition: border-color 0.1s ease-in-out;
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

            #urlbar-background, #searchbar {
              background-color: var(--bg) !important;
            }

            .urlbarView-tags, .urlbarView-url, .urlbarView-title:not(:empty) ~ .urlbarView-action {
              font-size: var(--font-size) !important;
            }

            #pageActionButton,
            #pageActionSeparator {
              display: none;
            }

            #PanelUI-button {
              border: none !important;
            }

            .bookmark-item {
              padding: 4px !important;
            }

            #navigator-toolbox {
              border: none !important;
            }

            .ac-separator,
            .ac-url,
            .ac-action {
              color: var(--blue) !important;
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
            --bg-hover: hsla(0, 100%, 100%, .1);
            --bg-active: hsla(0, 100%, 100%, .15);
            --fg: ${foreground};
            --fg-inactive: ${foregroundAlt};
            --green: ${cold};
            --blue: ${cold};
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
              overflow-y: auto !important;
            }

            html.private {
              --in-content-page-background: var(--bg) !important;
            }

            #onboarding-overlay-button {
              display: none !important;
            }

            .prefs-button {
              display: none !important;
            }
          }

          @-moz-document url(about:blank) {
            html, body {
              background: var(--bg) !important;
            }
          }

          @-moz-document url-prefix(https://github.com/), url-prefix(https://gist.github.com/) {
            .blob-num, .blob-code-inner {
              font-family: monospace !important;
              font-size: 13px !important;
              vertical-align: middle !important;
            }
          }
        '';
      };
    };

    home.sessionVariables.MOZ_USE_XINPUT2 = "1";
  };
}
