{ profilesPath, ... }: {
  imports = [
    "${profilesPath}/home-manager.nix"
    "${profilesPath}/bash"
    "${profilesPath}/direnv.nix"
    "${profilesPath}/console.nix"
    "${profilesPath}/environment.nix"
    "${profilesPath}/git.nix"
    "${profilesPath}/gpg.nix"
    "${profilesPath}/localisation.nix"
    "${profilesPath}/networking.nix"
    "${profilesPath}/nix.nix"
    "${profilesPath}/ssh.nix"
    "${profilesPath}/sudo.nix"
    "${profilesPath}/tmux.nix"
    "${profilesPath}/users.nix"
    "${profilesPath}/vim"
    "${profilesPath}/ghci.nix"
    "${profilesPath}/clipboard.nix"
  ];
}
