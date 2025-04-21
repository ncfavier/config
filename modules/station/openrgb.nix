{ lib, config, pkgs, ... }: with lib; let
  loadDefaultProfile = ''
    ${getExe config.services.hardware.openrgb.package} --config ${config.hm.xdg.configHome}/OpenRGB -p default || true
  '';
in mkEnableModule [ "my-services" "openrgb" ] {
  services.hardware.openrgb = {
    enable = true;

    # 1.0rc1 supports my motherboard
    package = (pkgs.mine "openrgb" "sha256-aw1L5q1Ac7KlbwVvHMjH+WBrYsMzOvwjftuGGSglLgU=").openrgb;
  };

  # load the default profile on start and after suspend
  systemd.services.openrgb.postStart = loadDefaultProfile;
  environment.etc."systemd/system-sleep/openrgb".source = pkgs.writeShellScript "openrgb-sleep" ''
    if [[ $1 == post ]]; then
      ${loadDefaultProfile}
    fi
  '';
}
