{ config, ... }: {
  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.monade.li";
    notificationSender = "hydra@monade.li";
    smtpHost = "localhost";
    listenHost = "localhost";
    useSubstitutes = true;
    extraConfig = "email_notification = 1";
  };

  services.nginx = {
    enable = true;
    virtualHosts."hydra.monade.li" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:${toString config.services.hydra.port}";
    };
  };

  nix.buildMachines = [
    {
      hostName = "localhost";
      system = "x86_64-linux";
      supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
    }
  ];
}
