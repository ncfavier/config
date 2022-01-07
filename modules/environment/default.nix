{ lib, config, utils, pkgs, ... }: with lib; {
  documentation = {
    dev.enable = true;
    man.generateCaches = true;
    man.man-db.manualPages = (pkgs.buildEnv {
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
    usbutils
    zip
    unzip
    config.boot.kernelPackages.bcc
    binutils
    gcc
    gnumake
    openssl
    bc
    fortune
    imagemagick
    ffmpeg-full
    (yt-dlp.override { withAlias = true; })
    python3
    neofetch
    lesspass-cli
    tmsu
    (utils.shellScriptWith "upload" ./upload.sh {})
    (utils.shellScriptWith "order" ./order.sh {})
  ];

  environment.etc.topdefaultrc.source = utils.mkMutableSymlink ./toprc;

  hm.programs.htop = {
    enable = true;
    settings = {
      color_scheme = 1;
      tree_view = true;
    };
  };

  nixpkgs.overlays = [ (pkgs: prev: {
    tmsu = prev.tmsu.overrideAttrs (o: {
      patches = o.patches or [] ++ [ (builtins.toFile "tmsu-patch" ''
        --- a/src/github.com/oniony/TMSU/common/path/path.go
        +++ b/src/github.com/oniony/TMSU/common/path/path.go
        @@ -92,14 +92 @@ func Dereference(path string) (string, error) {
        -	stat, err := os.Lstat(path)
        -	if err != nil {
        -		return "", err
        -	}
        -	if stat.Mode()&os.ModeSymlink != 0 {
        -		path, err := os.Readlink(path)
        -		if err != nil {
        -			return "", err
        -		}
        -
        -		return Dereference(path)
        -	}
        -
        -	return path, nil
        +	return filepath.EvalSymlinks(path)
      '') ];
    });
  }) ];
  cachix.derivationsToPush = [ pkgs.tmsu ];
}
