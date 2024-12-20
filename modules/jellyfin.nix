{ lib, config, ... }: with lib; mkEnableModule [ "jellyfin" ] {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.jellyfin.wantedBy = mkForce [];
  systemd.services.jellyfin.serviceConfig.ProtectHome = "read-only";
  systemd.services.jellyfin.serviceConfig.BindReadOnlyPaths = [
    "${config.hm.xdg.userDirs.videos}:/srv/videos"
  ];
}
