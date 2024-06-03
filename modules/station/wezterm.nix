{
  hm.programs.wezterm = {
    enable = true;

    extraConfig = ''
      local config = wezterm.config_builder()

      config.enable_tab_bar = false
      config.window_padding = {
        left = 16,
        right = 16,
        top = 16,
        bottom = 16,
      }
      config.font = wezterm.font 'bitmap'
      config.color_scheme = 'Cloud (terminal.sexy)'

      return config
    '';
  };
}
