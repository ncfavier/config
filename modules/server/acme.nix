{ lib, ... }: with lib; {
  security.acme = {
    acceptTerms = true;
    defaults.email = "acme@${my.domain}";
  };
}
