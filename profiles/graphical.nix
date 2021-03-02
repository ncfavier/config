{ config, pkgs, lib, me, ... }: let
  font      = "bitmap";
  black     = "#0b000d";
  darkGrey  = "#444444";
  lightGrey = "#666666";
  white     = "#ffffff";
  magenta   = "#ff00cc";
  blue      = "#4bebef";
  borderWidth = 0;
  windowGap = 16;
in {
  services.xserver = {
    enable = true;
    tty = 1;
    displayManager = {
      startx.enable = true;
      # xserverArgs = [ "-keeptty" ];
    };
    # displayManager = {
    #   lightdm = {
    #     enable = true;
    #     greeters.mini = {
    #       enable = true;
    #       user = me;
    #     };
    #   };
    # };
    # desktopManager.xterm.enable = true;
    autoRepeatDelay = 250;
  };

  fonts = {
    fonts = with pkgs; [
      source-serif-pro
      source-sans-pro
      source-code-pro
      source-han-serif
      source-han-sans
      source-han-mono
      twemoji-color-font
      noto-fonts-emoji
      symbola
      dina-font
      tewi-font
      # TODO efont
      siji
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif     = [ "Source Serif Pro" "Source Han Serif" ];
        sansSerif = [ "Source Sans Pro" "Source Han Sans" ];
        monospace = [ "Source Code Pro" "Source Han Mono" ];
        emoji     = [ "Twemoji" "Noto Color Emoji" "Symbola" ];
      };
      localConf = ''
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
        <fontconfig>
          <alias binding="same">
            <family>bitmap</family>
            <prefer>
              <family>Dina</family>
              <family>tewi</family>
              <family>Biwidth</family>
              <family>Twemoji</family>
              <family>Symbola</family>
            </prefer>
          </alias>
          <selectfont>
            <rejectfont>
              <pattern>
                <patelt name="family"><string>Biwidth</string></patelt>
                <patelt name="pixelsize"><int>10</int></patelt>
              </pattern>
            </rejectfont>
          </selectfont>
        </fontconfig>
      '';
    };
  };

  services.dbus.packages = [ pkgs.dconf ];

  home-manager.users.${me} = {
    xsession = {
      enable = true;
      scriptPath = ".xinitrc";
      numlock.enable = true;
      # TODO cursor theme Paper
      initExtra = with pkgs.xorg; ''
        ${xset}/bin/xset -b
        ${xmodmap}/bin/xmodmap -e 'keycode 49 = grave twosuperior'
      '';
      pointerCursor = {
        package = pkgs.paper-icon-theme;
        name = "Paper";
        size = 16;
      };
      importedVariables = [ "PATH" ];
      windowManager.bspwm = {
        enable = true;
        monitors.focused = [ "1" "2" "3" "4" "5" "6" "web" "mail" "irc" "files" ];
        settings = {
          focused_border_color = black;
          normal_border_color = lightGrey;
          presel_feedback_color = white;
          border_width = borderWidth;
          window_gap = windowGap;
          borderless_monocle = true;
          gapless_monocle = true;
          initial_polarity = "second_child";
          pointer_action1 = "move";
          pointer_action2 = "resize_side";
          pointer_action3 = "resize_corner";
        };
        extraConfig = ''
          bspc desktop web -l monocle
          bspc desktop mail -l monocle
        '';
        startupPrograms = [
          "[ -f ~/.fehbg ] && ~/.fehbg"
        ];
        # TODO bspwm
        # TODO bar
      };
    };

    programs.bash.profileExtra = ''
      [[ ! $DISPLAY && $XDG_VTNR == 1 ]] && exec startx
    '';

    services.sxhkd = {
      enable = true;
      extraOptions = [ "-m 1" ];
      keybindings = {
        "super + Escape" = "bspc quit";
        "super + space" = "rofi -show drun";
        "super + Return" = "alacritty";
        "super + w" = "firefox";
        "super + f" = "thunar";
      };
      # TODO sxhkd
    };

    systemd.user.services.sxhkd.Service = {
      Environment = lib.mkForce "";
      KillMode = "process";
    };

    programs.feh = {
      enable = true;
      # TODO feh
    };

    services.dunst = {
      enable = true;
      # TODO dunst
    };

    services.picom = {
      enable = true;
      vSync = true;
    };

    services.redshift = {
      enable = true;
      latitude = 48.0;
      longitude = 2.0;
    };

    programs.rofi = {
      enable = true;
      # TODO rofi
    };

    programs.alacritty = {
      enable = true;
      package = pkgs.alacritty.overrideAttrs ({ patches ? [], ... }: {
        patches = patches ++ [
          (builtins.toFile "alacritty-patch" ''
            diff --git a/alacritty/src/input.rs b/alacritty/src/input.rs
            index 155fab0..9d9fb3a 100644
            --- a/alacritty/src/input.rs
            +++ b/alacritty/src/input.rs
            @@ -891 +890,0 @@ impl<'a, T: EventListener, A: ActionContext<T>> Processor<'a, T, A> {
            -            && utf8_len == 1
          '')
        ];
      });
      settings = {
        window = {
          dimensions = {
            columns = 80;
            lines = 25;
          };
          padding = {
            x = 16;
            y = 16;
          };
          decorations = "none";
        };
        font = {
          normal.family = font;
          size = 7;
        };
        colors = {
          primary = {
            background = black;
            foreground = white;
          };
          normal = {
            black   = black;
            red     = magenta;
            green   = blue;
            yellow  = magenta;
            blue    = blue;
            magenta = magenta;
            cyan    = blue;
            white   = darkGrey;
          };
          bright = {
            black   = lightGrey;
            red     = magenta;
            green   = blue;
            yellow  = magenta;
            blue    = blue;
            magenta = magenta;
            cyan    = blue;
            white   = white;
          };
        };
        selection.save_to_clipboard = true;
        cursor.style.blinking = "Always";
      };
    };

    gtk = {
      enable = true;
      iconTheme = {
        package = pkgs.flat-remix-icon-theme;
        name = "Flat-Remix-Blue-Dark";
      };
      # TODO gtk
    };

    programs.firefox = {
      enable = true;
      profiles.default = {
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
              --bg: ${black};
              --bg-hover: hsla(0, 100%, 100%, .1);
              --bg-active: hsla(0, 100%, 100%, .15);
              --fg: ${white};
              --fg-inactive: ${lightGrey};
              --green: ${blue};
              --blue: ${blue};
              --font: ${font};
              --font-size: 10px;

              --toolbar-non-lwt-bgcolor: var(--bg) !important;
              --toolbar-non-lwt-bgimage: none !important;
              --toolbar-non-lwt-textcolor: var(--fg) !important;
              --tabs-border-color: transparent !important;
            }

            ::selection {
              background-color: ${blue};
              color: white;
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
            --bg: ${black};
            --bg-hover: hsla(0, 100%, 100%, .1);
            --bg-active: hsla(0, 100%, 100%, .15);
            --fg: ${white};
            --fg-inactive: ${lightGrey};
            --green: ${blue};
            --blue: ${blue};
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

    home.packages = with pkgs; [
      rxvt-unicode
      alacritty
      thunderbird
      xfce.thunar
    ];
  };
}
