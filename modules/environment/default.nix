{ inputs, lib, config, pkgs, ... }: with lib; {
  documentation = {
    nixos.enable = inputs.nixpkgs ? rev;
    dev.enable = true;
  };

  environment.systemPackages = with pkgs; [
    man-pages
    man-pages-posix
    rlwrap
    bat
    xxd
    dos2unix
    ripgrep
    file
    fd
    tree
    ncdu
    lsof
    inotify-tools
    config.boot.kernelPackages.cpupower
    lm_sensors
    hwinfo
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
    http-server
    openssl
    bc
    fortune
    imagemagickBig
    ffmpeg-full
    jq
    htmlq
    python3
    (writeShellScriptBin "mutate" ''
      # replace a read-only symlink with a mutable copy
      f=''${1%/}
      if [[ -L $f ]]; then
        r=$(realpath -- "$f")
        rm -f -- "$f"
        cp -Tr --remove-destination --preserve=mode -- "$r" "$f"
      fi
      chmod -R u+w -- "$f"
    '')
    (shellScriptWith "upload" {} (readFile ./upload.sh))
    (shellScriptWith "order" {} (readFile ./order.sh))
  ];

  programs.bcc.enable = true; # for execsnoop

  environment.etc.topdefaultrc.source = config.lib.meta.mkMutableSymlink ./toprc;

  hm.programs.htop = {
    enable = true;
    settings = {
      hide_kernel_threads = true;
      hide_userland_threads = true;
      show_thread_names = true;
      highlight_base_name = true;
      show_cpu_frequency = true;
      show_cpu_temperature = true;
      screen_tabs = true;
    };
  };

  hm.xdg.configFile."htop".force = true;

  hm.programs.yt-dlp = {
    enable = true;
    package = pkgs.unstable.yt-dlp.override { withAlias = true; };
    settings = {
      cookies-from-browser = "firefox";
    };
  };

  nixpkgs.overlays = [ (pkgs: prev: {
    shellScriptWith = name: { deps ? [], vars ? {}, completion ? null }: src:
      # can't use `writeScriptBin` because no check phase,
      # can't use `writeShellScriptBin` because no interactive shell
      pkgs.writeTextFile {
        inherit name;
        executable = true;
        destination = "/bin/${name}";
        text = ''
          #!${config.my.shellPath}
          ${optionalString (deps != []) ''
          PATH=${makeBinPath deps}''${PATH+:$PATH}
          ''}
          ${toShellVars vars}
          ${src}
        '';
        checkPhase = ''
          ${pkgs.stdenv.shellDryRun} "$target"
        '' + optionalString (completion != null) ''
          installShellCompletion --bash --cmd "$name" ${builtins.toFile "completions.bash" completion}
        '';
        derivationArgs = optionalAttrs (completion != null) {
          nativeBuildInputs = [ pkgs.installShellFiles ];
        };
      };

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
        --- a/common/path/path.go
        +++ b/common/path/path.go
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
}
