{ lib, ... }: with lib; {
  console = {
    earlySetup = true;
    useXkbConfig = true;
  };

  environment.etc.issue = mkForce {
    text = " \\e{magenta}\\n\\e{reset} | \\e{reset}\\l\\e{reset} | \\d \\t\n\n";
  };

  services.getty.extraArgs = [ "--nohostname" ];
}
