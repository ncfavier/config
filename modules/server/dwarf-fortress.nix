{ lib, config, pkgs, ... }: with lib; let
  wsPort = 4321;
  password = "quineapple"; # not meant to be secure

  df = pkgs.dwarf-fortress-packages.dwarf-fortress_0_47_04.override (oldArgs: let
    dfplex = pkgs.fetchFromGitHub {
      owner = "ncfavier";
      repo = "dfplex";
      rev = "49f850281f1871aa9cf5d7c5e944afe53fb4fe53";
      fetchSubmodules = true;
      hash = "sha256-8jufSfbjnIhFfNMAfpRX7KeKUkyfMbViOkX/UfauneI=";
    };
    dfhack = oldArgs.dfhack.overrideAttrs (o: {
      preConfigure = o.preConfigure or "" + ''
        ln -s ${dfplex}/server plugins/dfplex
        echo 'add_subdirectory(dfplex)' > plugins/CMakeLists.custom.txt
      '';
      nativeBuildInputs = o.nativeBuildInputs or [] ++ [ pkgs.boost16x ];
    });
  in {
    enableTextMode = true;
    enableTruetype = false;
    enableSound = false;
    enableIntro = false;
    enableFPS = true;
    enableDFHack = true;
    inherit dfhack;
    extraPackages = [
      (pkgs.writeTextDir "dfhack.init" ''
        enable title-version
      '')
      (pkgs.writeTextDir "onLoad.init" ''
        enable dfplex
      '')
      (pkgs.writeTextDir "onUnload.init" ''
        disable dfplex
      '')
      (pkgs.concatTextFile {
        name = "config.js";
        destination = "/hack/www/config.js";
        files = [ "${dfhack}/hack/www/config.js" (builtins.toFile "config-custom.js" ''
          config.port = ${toString wsPort};
          config.secret = ${builtins.toJSON password};
          config.tiles = "Curses.png";
          config.text = "Curses.png";
          config.overworld = "Curses.png";
        '') ];
      })
    ];
    settings = {
      init.FPS_CAP = 60;
      d_init.AUTOSAVE = "SEASONAL";
      dfplex = {
        PORT = wsPort;
        STATICPORT = 0;
        AUTH_REQUIRED = 1;
        UNIPLEX_READONLY = 1;
        MULTIPLEXKEY = 0;
      };
      announcements = let
        don'tPause = "A_D:D_D";
      in {
        BIRTH_CITIZEN = don'tPause;
        MOOD_BUILDING_CLAIMED = don'tPause;
        ARTIFACT_BEGUN = don'tPause;
      };
    };
  });

  tmuxSocket = "/run/df/tmux.socket";
  tmuxConfig = builtins.toFile "tmux-df.conf" ''
    set -g status off
    bind -n C-q detach
  '';
  dfDir = "/run/df/state";
in {
  nixpkgs.config.allowUnfree = true;

  systemd.services.dwarf-fortress = {
    description = "Dwarf Fortress + DFPlex in a tmux session";
    environment = {
      SHELL = getExe pkgs.bashInteractive; # otherwise tmux uses nologin
      DF_DIR = dfDir;
      DFPLEX_SECRET = password;
    };
    serviceConfig = {
      DynamicUser = true;
      RuntimeDirectory = "df";
      BindPaths = [ "${config.my.home}/df:${dfDir}" ];

      Type = "forking";
      ExecStart = "${pkgs.tmux}/bin/tmux -S ${tmuxSocket} -f ${tmuxConfig} new-session -d ${df}/bin/dfhack";
      ExecStop = "-${pkgs.tmux}/bin/tmux -S ${tmuxSocket} kill-server";

      CapabilityBoundingSet = "";
      DevicePolicy = "closed";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RemoveIPC = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" ];
    };
    restartIfChanged = false;
  };

  networking.firewall.allowedTCPPorts = [ wsPort ];

  services.nginx.virtualHosts."df.${my.domain}" = {
    root = "${df.env}/hack/www";
    basicAuth.df = password;
    locations."/".index = "dfplex.html";
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "df-attach" ''
      sudo tmux -S ${tmuxSocket} attach "$@"
    '')
  ];
}
