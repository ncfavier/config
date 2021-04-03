{ inputs, lib, ... }: {
  disabledModules = [ "services/ttys/getty.nix" ];
  imports = [ "${inputs.nixos-getty-args}/nixos/modules/services/ttys/getty.nix" ];

  console.earlySetup = true;

  environment.etc.issue = lib.mkForce {
    text = " \\e{magenta}\\n\\e{reset} | \\e{reset}\\l\\e{reset} | \\d \\t\n\n";
  };

  services.getty.extraArgs = [ "--nohostname" ];
}
