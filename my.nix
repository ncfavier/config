lib: rec {
  username = "n";
  githubUsername = "ncfavier";
  realName = "Naïm Favier";
  domain = "monade.li";
  emailFor = what: "${what}@${domain}";
  email = emailFor username;
  pgpFingerprint = "51A0705E7DD23CBC5EAAB43E49B07322580B7EE2";
  pgpKeygrip = "D10BD70AF981C671C8EE4D288F23BAE560675CA3";

  machines = lib.mapAttrs (_: lib.recursiveUpdate {
    isServer = false;
    isStation = false;
    isPhone = false;
  }) {
    wo = {
      isServer = true;
      hashedPassword = "$6$jvQ36QMw6kyzUjx$ApZlmPkvPyNAf2t51KpnocvMDo/1BubqCMR3q5jZD5OcM1awyAnTIgIeyaVl2XpAiNZPTouyuM1AOzBIGBu4m.";
      wireguard = {
        ipv4 = "10.42.0.1";
        ipv6 = "fd42::0:1";
        publicKey = "fzC/SGpGcIbH/DyHrPYIW+9aAm2h4CvHZZosBPEHDHA=";
      };
      syncthing = {
        id = "7YQ7LRQ-IAWYNHN-VGHTAEQ-JDSH3C7-DUPWBYD-G6L4OJC-W3YLUFZ-SSM5CA6";
        cert = ''
          -----BEGIN CERTIFICATE-----
          MIIBmzCCASCgAwIBAgIIZR/vpL1iGHwwCgYIKoZIzj0EAwIwFDESMBAGA1UEAxMJ
          c3luY3RoaW5nMB4XDTIwMTExMTAwMDAwMFoXDTQwMTEwNjAwMDAwMFowFDESMBAG
          A1UEAxMJc3luY3RoaW5nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE5jPi++Nycm5j
          PRvKzhRkHlw8Am1qLryxpBqFJBoeEvLtFdrBXr0JmcfbXX8htKw863cH6LX1A7G5
          8rYn/qEuquu/yawsBrU2jDRD+18H0Cz2SJkhR6ZbVIFI00ZwO3wzoz8wPTAOBgNV
          HQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1Ud
          EwEB/wQCMAAwCgYIKoZIzj0EAwIDaQAwZgIxALy2BpsKfyvadr0T9dkikU/KPjiT
          Dg2P8CiEOW63UoGxZdgAeTQuFJDQ2IrRUvy8LQIxANrQBQ309xy3sf44pgah1PvZ
          BDS5RTdh3BYmC2aLyy2ocJM7ZA2bmaR5i6dH2YebPw==
          -----END CERTIFICATE-----
        '';
      };
    };
    fu = {
      isStation = true;
      wireguard = {
        ipv4 = "10.42.1.1";
        ipv6 = "fd42::1:1";
        publicKey = "v1MDB6hEYKdBwdVN/rOnOGB82h3xTQpHwU3CAcctGWg=";
      };
      syncthing.id = "VVLGMST-LA633IY-KWESSFD-7FFF7LE-PNJAEML-ZXZSBLL-ATLQHPT-MUHEDAR";
    };
    mo = {
      isStation = true;
      hashedPassword = "$6$YQiLlxItjY$D8bmUq29Zi557FZ3i4fcWdK4S1Nc7YH/6aUUfl3NvuTyK0rq7uKdajhChK/myhmvtN3MzIYXDo6e0hmfhuHjn0";
      wireguard = {
        ipv4 = "10.42.2.1";
        ipv6 = "fd42::2:1";
        publicKey = "tsvrIdHACcHMhtaHQt2tVE+2FO1LMdtiAlSXPNMuHFc=";
      };
      syncthing = {
        id = "WO4GV6E-AJGKLLQ-M7RZGFT-WY7CCOW-LXODXRY-F3QPEJ2-AXDVWKR-SWBGDQP";
        cert = ''
          -----BEGIN CERTIFICATE-----
          MIIBmjCCASCgAwIBAgIIU2Crk9b6ZekwCgYIKoZIzj0EAwMwFDESMBAGA1UEAxMJ
          c3luY3RoaW5nMB4XDTE4MDgwNzIzMjMzNVoXDTQ5MTIzMTIzNTk1OVowFDESMBAG
          A1UEAxMJc3luY3RoaW5nMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEh18xcRgABADs
          7eMwystTMeUC65E+dP/MJf6tOBPRAumbP2LanrtRAW4it1KjJ8QiwtRe3t7+SlvN
          CdC26ni4NH6B9fYhN1vL0pjHy3cun5ouwLxC4tTISyrirJZl4UAPoz8wPTAOBgNV
          HQ8BAf8EBAMCBaAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1Ud
          EwEB/wQCMAAwCgYIKoZIzj0EAwMDaAAwZQIxAJwtZBBG6iGgiCE5Xsfebxltw/Uy
          kjrbRaEBW8Dp+DcmfJjWPz1tW8WwBd3LGdadswIwaE6CkCKXg7/Om2O9WCs8qnjU
          qR/eLxSYOw2/n12rN2cEsWz6SI+vpfDIZoTYxvDP
          -----END CERTIFICATE-----
        '';
      };
    };
    tsu = {
      isPhone = true;
      wireguard = {
        ipv4 = "10.42.3.1";
        ipv6 = "fd42::3:1";
        publicKey = "fRJFAT9BrQW5Wis3Jxq3mTR66IF6YlhvcCtMmjm78kI=";
      };
      syncthing.id = "KXGLMP5-D2RKWZR-QUASDWC-T6H337M-HMEYLX7-D7EW4LM-UARXLZN-NXKVZAU";
    };
  };
  server = machines.wo;
}
