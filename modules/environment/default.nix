{ inputs, lib, config, pkgs, ... }: with lib; {
  documentation = {
    nixos.enable = inputs.nixpkgs ? rev;
    dev.enable = true;
    man.generateCaches = true;
    man.man-db.manualPages = (pkgs.buildEnv {
      name = "man-paths";
      paths = config.environment.systemPackages ++ config.hm.home.packages;
      pathsToLink = [ "/share/man" ];
      extraOutputsToInstall = [ "man" ];
      ignoreCollisions = true;
    }).overrideAttrs (o: {
      __contentAddressed = true; # avoid needlessly rebuilding the cache
    });
  };

  programs.bcc.enable = true;

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
    binutils
    gcc
    gnumake
    openssl
    bc
    fortune
    imagemagick
    ffmpeg-full
    (yt-dlp.override { withAlias = true; })
    htmlq
    python3
    neofetch
    lesspass-cli
    tmsu
    (shellScriptWith "upload" ./upload.sh {})
    (shellScriptWith "order" ./order.sh {})
  ];

  environment.etc.topdefaultrc.source = config.lib.meta.mkMutableSymlink ./toprc;

  hm.programs.htop = {
    enable = true;
    settings = {
      color_scheme = 1;
      tree_view = true;
      hide_kernel_threads = true;
      hide_userland_threads = true;
      show_thread_names = true;
      highlight_base_name = true;
      show_cpu_frequency = true;
      show_cpu_temperature = true;
      screen_tabs = true;
    };
  };

  nixpkgs.overlays = [ (pkgs: prev: {
    shellScriptWith = name: src: { deps ? [], vars ? {} }:
      pkgs.writeScriptBin name ''
        #!${config.my.shellPath}
        ${optionalString (deps != []) ''
        PATH=${makeBinPath deps}''${PATH+:$PATH}
        ''}
        ${toShellVars vars}
        ${readFile src}
      '';

    pythonScriptWithDeps = name: src: deps:
      pkgs.stdenv.mkDerivation {
        inherit name;
        buildInputs = [ (pkgs.python3.withPackages deps) ];
        dontUnpack = true;
        installPhase = ''
          install -D -m555 ${src} "$out/bin/${name}"
        '';
      };

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
