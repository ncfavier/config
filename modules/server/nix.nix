{ config, ... }: {
  secrets.nix-binary-cache = {};

  services.nix-serve = {
    enable = true;
    bindAddress = "127.0.0.1";
    openFirewall = false;
    secretKeyFile = config.secrets.nix-binary-cache.path; # nix.monade.li:2Zgy59ai/edDBizXByHMqiGgaHlE04G6Nzuhx1RPFgo=
  };
}
