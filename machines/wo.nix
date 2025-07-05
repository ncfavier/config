{
  identity = {
    isStation = true;
    wireguard = {
      ipv4 = "10.42.2.3";
      ipv6 = "fd42::2:3";
      publicKey = "fc1Vz7/KPNDQuqTiOyfIpunLIbSl/MYgxMETa9KBWFI=";
    };
    syncthing.id = "KUSNDTE-RO27UK3-HKBQK2W-R2HOLNS-IKTO4ZI-ZKQ7GHO-HQVCQYQ-K5X6WQT";
  };

  nixos = { hardware, lib, config, pkgs, ... }: with lib; {
    my.hashedPassword = "$y$j9T$iAwsXl5QOM5ku7mZGODkq.$CnAcwjvPNqPgUL7oyQ.luxOqq517KcrGkomfk.LH6H.";

    services.syncthing.cert = builtins.toFile "syncthing-cert" ''
      -----BEGIN CERTIFICATE-----
      MIICHjCCAaOgAwIBAgIJAKAiG0vUfpcyMAoGCCqGSM49BAMCMEoxEjAQBgNVBAoT
      CVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBHZW5lcmF0ZWQxEjAQ
      BgNVBAMTCXN5bmN0aGluZzAeFw0yNTA3MDUwMDAwMDBaFw00NTA2MzAwMDAwMDBa
      MEoxEjAQBgNVBAoTCVN5bmN0aGluZzEgMB4GA1UECxMXQXV0b21hdGljYWxseSBH
      ZW5lcmF0ZWQxEjAQBgNVBAMTCXN5bmN0aGluZzB2MBAGByqGSM49AgEGBSuBBAAi
      A2IABKqayorwBgQ4S6GHnZuWngsG1rZONgjn13MbFUXBoE1/lWWX/KnGF0GvbbPp
      rJrZFaT+mNX3YmUWh/1E4mYmhyKzQIqNIuaBUxjbGUIywo1AHewEsvUhCbQBkF1F
      Vm4LT6NVMFMwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggr
      BgEFBQcDAjAMBgNVHRMBAf8EAjAAMBQGA1UdEQQNMAuCCXN5bmN0aGluZzAKBggq
      hkjOPQQDAgNpADBmAjEAkaB9BCrg7/MhoS1xxUB0Kww/CIygygEu7gk1rHfmSDDX
      EHkbBrQ4D4GPA6kaalBhAjEA/6WgAMK7s9mTs58v7zy3zeH1xrBXMkoQWwyvXDLg
      afIOg50rofZ8FxLzgCyG8Tk7
      -----END CERTIFICATE-----
    '';
  };
}
