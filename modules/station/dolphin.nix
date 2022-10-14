{ inputs, lib, config, pkgs, ... }: with lib; {
  system.extraDependencies = collectFlakeInputs inputs.plasma-manager;

  hm = {
    imports = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];

    home.packages = with pkgs; with libsForQt5; [
      dolphin
      dolphin-plugins
      kio-extras
      kdegraphics-thumbnailers
      ffmpegthumbs

      inputs.plasma-manager.packages.${pkgs.system}.rc2nix

      (hiPrio (writeShellScriptBin "dolphin" ''
        exec ${pkgs.dolphin}/bin/dolphin -stylesheet ${builtins.toFile "no-animations.qss" ''
          * { widget-animation-duration: 0; }
        ''} "$@"
      ''))
    ];

    # TODO bookmarks (user-places.xbel), toolbar & shortcuts (kxmlgui5), user actions (https://develop.kde.org/docs/extend/dolphin/service-menus/)
    programs.plasma.files = {
      "dolphinrc"."MainWindow"."MenuBar" = "Disabled";
      "kdeglobals"."Colors:View"."BackgroundNormal" = config.theme.background;
      "ktrashrc"."${config.hm.xdg.dataHome}/Trash" = { name, ... }: {
        configGroupNesting = [ name ];
        UseSizeLimit = false;
        UseTimeLimit = false;
      };

      # rc2nix
      "dolphinrc"."General"."BrowseThroughArchives" = false;
      "dolphinrc"."General"."ConfirmClosingMultipleTabs" = false;
      "dolphinrc"."General"."EditableUrl" = true;
      "dolphinrc"."General"."RememberOpenedTabs" = false;
      "dolphinrc"."General"."ShowSelectionToggle" = false;
      "dolphinrc"."General"."ShowZoomSlider" = false;
      "dolphinrc"."IconsMode"."IconSize" = 256;
      "dolphinrc"."IconsMode"."PreviewSize" = 256;
      "dolphinrc"."IconsMode"."TextWidthIndex" = 0;
      "dolphinrc"."KFileDialog Settings"."Places Icons Auto-resize" = false;
      "dolphinrc"."KFileDialog Settings"."Places Icons Static Size" = 48;
      "dolphinrc"."PlacesPanel"."IconSize" = 48;
      "dolphinrc"."PreviewSettings"."Plugins" = "audiothumbnail,blenderthumbnail,comicbookthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,mobithumbnail,opendocumentthumbnail,gsthumbnail,rawthumbnail,svgthumbnail,ffmpegthumbs";
      "dolphinrc"."Search"."Location" = "Everywhere";
      "dolphinrc"."VersionControl"."enabledPlugins" = "Git";
      "ffmpegthumbsrc"."General"."filmstrip" = false;
      "kdeglobals"."General"."TerminalApplication" = "alacritty";
      "kdeglobals"."KDE"."ShowDeleteCommand" = false;
      "kdeglobals"."PreviewSettings"."MaximumRemoteSize" = 0;
      "kiorc"."Confirmations"."ConfirmDelete" = true;
      "kiorc"."Confirmations"."ConfirmEmptyTrash" = true;
      "kiorc"."Confirmations"."ConfirmTrash" = false;
      "kiorc"."Executable scripts"."behaviourOnLaunch" = "execute";
      "kservicemenurc"."Show"."forgetfileitemaction" = true;
      "kservicemenurc"."Show"."kactivitymanagerd_fileitem_linking_plugin" = true;
      "kservicemenurc"."Show"."mountisoaction" = true;
      "kservicemenurc"."Show"."tagsfileitemaction" = true;
    };
  };

  nixpkgs.overlays = [ (self: super: {
    libsForQt515 = super.libsForQt515.overrideScope' (qself: qsuper: {
      ffmpegthumbs = qsuper.ffmpegthumbs.overrideAttrs (attrs:
      assert versionAtMost attrs.version "22.08.1"; {
        src = pkgs.fetchFromGitHub {
          owner = "KDE";
          repo = "ffmpegthumbs";
          rev = "6efa4c1a6257010f2925d1714d84a17ce23d2176";
          hash = "sha256-4lxPfqJhUJbQUauMy+CPnPYJHUyF6Bt3sfZn0VTVkrg=";
        };
      });
    });
  }) ];
}
