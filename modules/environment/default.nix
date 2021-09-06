{ lib, config, utils, pkgs, pkgsFlake, ... }: with lib; {
  imports = [
    "${pkgsFlake.fetchFromGitHub {
      owner = "ncfavier";
      repo = "nixpkgs";
      rev = "manualPages";
      hash = "sha256-4toYOU4/0ysfSAw9TCJr9j3xomVKseauWezhcXAaXzg=";
    }}/nixos/modules/misc/documentation.nix"
  ];
  disabledModules = [ "misc/documentation.nix" ];

  documentation = {
    dev.enable = true;
    man.generateCaches = true;
    man.manualPages = (pkgs.buildEnv {
      name = "man-paths";
      paths = config.environment.systemPackages ++ config.hm.home.packages;
      pathsToLink = [ "/share/man" ];
      extraOutputsToInstall = ["man"];
      ignoreCollisions = true;
    }).overrideAttrs (o: {
      __contentAddressed = true; # avoids rebuilding the cache every time nixos-version changes
    });
  };

  environment.localBinInPath = true;

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
    lm_sensors
    dosfstools
    mtools
    gptfdisk
    pciutils
    zip
    unzip
    config.boot.kernelPackages.bcc
    binutils
    gcc
    gnumake
    openssl
    fortune
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
