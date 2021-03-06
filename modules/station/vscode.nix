{ pkgs, ... }: {
  hm.home.packages = [
    (pkgs.vscode-with-extensions.override {
      vscode = pkgs.vscodium;
      vscodeExtensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        bbenoist.Nix
        haskell.haskell
        james-yu.latex-workshop
        yzhang.markdown-all-in-one
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "white";
          publisher = "arthurwhite";
          version = "1.3.6";
          sha256 = "9Pvzb29d13vgiU8DwasLUiyPVHK97RcnBA3f0q+4y/8=";
        }
        {
          name = "white-winter";
          publisher = "jker";
          version = "1.0.1";
          sha256 = "+IYYyhlgL6ITvh08jgQVrPmGAe0zf0Y7oaM8fLBYGjw=";
        }
        {
          name = "night-owl-light-bold";
          publisher = "feego";
          version = "0.0.5";
          sha256 = "U7wmya8jEwgUcKWyT7t9L1Ca5RlzIAO7hHm9gEF26Vg=";
        }
        {
          name = "theme-lavender";
          publisher = "gerane";
          version = "0.0.5";
          sha256 = "zQFdseqhR11fH6KmejIDJUhjaLH0xHup1FC+OzqqWH0=";
        }
        {
          name = "theme-github-bold";
          publisher = "gustavo";
          version = "0.0.4";
          sha256 = "nnDukucH4ynbc6LDBJ8/Ohsye8xt+1OZJhedZcSHlmU=";
        }
        {
          name = "vscode-theme-1984";
          publisher = "juanmnl";
          version = "0.3.4";
          sha256 = "RZ6SMs5thosLw6XvJwesHxdlcyvWnqCPV7VJc1mBYWM=";
        }
        {
          name = "vscode-duotone-dark";
          publisher = "sallar";
          version = "0.3.3";
          sha256 = "OPOgjjkooaDQzYoPOmly6WenvAILWhxBKuqRKmQi+rQ=";
        }
      ];
    })
  ];
}
