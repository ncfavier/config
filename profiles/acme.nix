{ my, ... }: {
  security.acme = {
    acceptTerms = true;
    email = my.emailFor "acme";
  };
}
