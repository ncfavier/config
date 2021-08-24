{ lib, config, utils, pkgs, ... }: with lib; {
  environment.etc."man_db.conf".text = let
    manualPages = (pkgs.buildEnv {
      name = "man-paths";
      paths = config.environment.systemPackages;
      pathsToLink = [ "/share/man" ];
      extraOutputsToInstall = ["man"];
      ignoreCollisions = true;
    }).overrideAttrs (o: {
      __contentAddressed = true; # avoids rebuilding the man cache every time nixos-version changes
    });
    manualCache = pkgs.runCommandLocal "man-cache" { } ''
      echo "MANDB_MAP ${manualPages}/share/man $out" > man.conf
      ${pkgs.man-db}/bin/mandb -C man.conf -psc >/dev/null 2>&1
    '';
  in mkForce ''
    # Manual pages paths for NixOS
    MANPATH_MAP /run/current-system/sw/bin /run/current-system/sw/share/man
    MANPATH_MAP /run/wrappers/bin          /run/current-system/sw/share/man

    ${optionalString config.documentation.man.generateCaches ''
    # Generated manual pages cache for NixOS (immutable)
    MANDB_MAP /run/current-system/sw/share/man ${manualCache}
    ''}
    # Manual pages caches for NixOS
    MANDB_MAP /run/current-system/sw/share/man /var/cache/man/nixos
  '';

  documentation = {
    dev.enable = true;
    man.generateCaches = true;
  };

  environment.systemPackages = with pkgs; [
    man-pages
    man-pages-posix
    rlwrap
    bat
    ripgrep
    file
    fd
    tree
    ncdu
    lsof
    iotop
    gptfdisk
    pciutils
    zip
    unzip
    config.boot.kernelPackages.bcc
    binutils
    gcc
    gnumake
    openssl
    imagemagick
    ffmpeg-full
    youtube-dl
    python3
    neofetch
    lesspass-cli
    tmsu
    (shellScriptWithDeps "upload" ./upload.sh [])
    (shellScriptWithDeps "order" ./order.sh [])
  ];

  environment.etc.topdefaultrc.source = utils.mkMutableSymlink ./toprc;

  hm.programs.htop = {
    enable = true;
    settings = {
      color_scheme = 1;
      tree_view = true;
    };
  };
}
