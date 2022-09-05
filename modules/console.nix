{ lib, config, ... }: with lib; {
  console = {
    earlySetup = true;
    useXkbConfig = true;

    colors = with config.theme; map (removePrefix "#") [
      background    hot cold hot cold hot cold foregroundAlt
      backgroundAlt hot cold hot cold hot cold foreground
    ];
  };

  environment.etc.issue = mkForce {
    text = " \\e{magenta}\\n\\e{reset} | \\e{reset}\\l\\e{reset} | \\d \\t\n\n";
  };

  services.getty.extraArgs = [ "--nohostname" ];
}
