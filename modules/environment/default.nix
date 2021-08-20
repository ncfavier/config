{ config, utils, pkgs, ... }: {
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
