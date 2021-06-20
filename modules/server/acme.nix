{ lib, ... }: with lib; {
  security.acme = {
    acceptTerms = true;
    email = my.emailFor "acme";
    validMinDays = 60;
  };
}
