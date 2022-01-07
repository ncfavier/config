{ lib, ... }: with lib; {
  security.acme = {
    acceptTerms = true;
    defaults.email = my.emailFor "acme";
  };
}
