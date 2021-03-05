{ lib, my, here, ... }: {
  config = lib.mkIf here.isServer {
    security.acme = {
      acceptTerms = true;
      email = my.emailFor "acme";
      validMinDays = 60;
    };
  };
}
