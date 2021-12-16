{ lib, ... }: with lib; {
  hm = {
    programs.gpg = {
      enable = true;
      publicKeys = [ {
        text = ''
          -----BEGIN PGP PUBLIC KEY BLOCK-----

          mQENBF9Ne7UBCAD7KZW1RCBXJY1uDLbmaDUm50eshkv1rT8eK0JJXR3MfuCaJ/Kq
          rg547ZjczxED98Qy8A7d1BrIsOiKEoFVou+jCcjU19hlkQiMce3IZmYm0h6MOmZq
          B0MR6EGTlAgDfkiDMYqnAUGst4p2xqqmH/gM/UI2d5ZFrxAbK+PC4d7yMxs5QJkJ
          0buXRnbKL/LGRWwyUCV8UDzQ26kYufVyAhS2Iz2SvUSqca5BaJOzAPJ74CFScbIC
          FK5nlsc2kHH35ZqK3f1Jxmbpi8ZwXUyxT+pFUClzY/s5H4w8c70ItvOyD3T0B+a8
          MF2Ft/c1kLFnHfYJd2FET+RZJQ5P+kXW+iZbABEBAAG0Gk5hw69tIEZhdmllciA8
          bkBtb25hZGUubGk+iQFOBBMBCAA4FiEEUaBwXn3SPLxeqrQ+SbBzIlgLfuIFAl9N
          e7UCGy8FCwkIBwIGFQoJCAsCBBYCAwECHgECF4AACgkQSbBzIlgLfuK0wwgAn0YY
          2hpWW789Mi5pmCrguPqmG3hingYjzM44XvPMt2pZcximyiX5ZzVfLwdgG4y/1/Qy
          5LIUYHb85aD0SZtPtB0Jm4Luqnm3WntuYfysKxbWg7/IiRbxkyJ8UTkO0/ETAyce
          1pubyF0L2jGcW2xiraBqlHe4ben8f7Fds4ReNwgFgexy+avEASXmlSeE1LCRFckG
          +6UMTwlPIdWWlYRBZMVT5e6kSLewBoGXF9Gs/trHwInG5lttKJEnoqMDh/nl/h5i
          /5EP6GzSVd9wYUSwEdI+ktDUB7QJdbxTgIWREZzxPG8ZxetXFEYN8K4w2UCwyemF
          D+/b5UHVjOB+8SVA4Q==
          =8IGY
          -----END PGP PUBLIC KEY BLOCK-----
        '';
        trust = "ultimate";
      } ];
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      sshKeys = [ my.gpgKeygrip ];
    };
  };
}
