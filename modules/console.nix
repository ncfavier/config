{ lib, config, ... }: with lib; {
  console = {
    earlySetup = true;
    useXkbConfig = true;

    colors = with config.theme; map (removePrefix "#") [
      "000000"      hot cold hot cold hot cold foregroundAlt
      backgroundAlt hot cold hot cold hot cold foreground
    ];
  };

  environment.etc.issue.text = " \\e{magenta}\\n\\e{reset} | \\e{reset}\\l\\e{reset} | \\d \\t\n\n";

  services.getty.extraArgs = [ "--nohostname" ];
}
