{ lib, theme, ... }: with lib; {
  nixpkgs.overlays = [ (self: super: {
    alacritty = super.alacritty.override {
      rustPlatform = super.rustPlatform // {
        buildRustPackage = o:
          super.rustPlatform.buildRustPackage (removeAttrs o [ "cargoSha256" ] // {
            cargoHash = "sha256-ltzsewNUaZWqdlZOEIhPlX8sm1jjNGA3bLqb9efefUo=";
            cargoPatches = [ (builtins.toFile "alacritty-patch" ''
diff --git a/Cargo.lock b/Cargo.lock
index f719104..5c037a1 100644
--- a/Cargo.lock
+++ b/Cargo.lock
@@ -42,0 +43 @@ dependencies = [
+ "signal-hook 0.3.9",
@@ -83 +84 @@ dependencies = [
- "signal-hook",
+ "signal-hook 0.1.17",
@@ -1432,0 +1434,10 @@ dependencies = [
+[[package]]
+name = "signal-hook"
+version = "0.3.9"
+source = "registry+https://github.com/rust-lang/crates.io-index"
+checksum = "470c5a6397076fae0094aaf06a08e6ba6f37acb77d3b1b91ea92b4d6c8650c39"
+dependencies = [
+ "libc",
+ "signal-hook-registry",
+]
+
@@ -1435 +1446 @@ name = "signal-hook-registry"
-version = "1.3.0"
+version = "1.4.0"
@@ -1437 +1448 @@ source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "16f1d0fef1604ba8f7a073c7e701f213e056707210e9020af4528e0101ce11a6"
+checksum = "e51e73328dc4ac0c7ccbda3a494dfa03df1de2f46018127f60c693f2648455b0"
diff --git a/alacritty/Cargo.toml b/alacritty/Cargo.toml
index c2f623c..7847d9d 100644
--- a/alacritty/Cargo.toml
+++ b/alacritty/Cargo.toml
@@ -36,0 +37 @@ dirs = "3.0.1"
+signal-hook = "0.3.9"
diff --git a/alacritty/src/main.rs b/alacritty/src/main.rs
index 85a4fc5..349efab 100644
--- a/alacritty/src/main.rs
+++ b/alacritty/src/main.rs
@@ -183 +183 @@ fn run(
-        monitor::watch(config.ui_config.config_paths.clone(), event_proxy);
+        monitor::watch(config.ui_config.config_paths.clone(), event_proxy.clone());
@@ -185,0 +186,10 @@ fn run(
+    let mut signals = signal_hook::iterator::Signals::new(&[signal_hook::consts::SIGUSR1])?;
+    let path = config.ui_config.config_paths[0].clone();
+    std::thread::spawn(move || {
+        for sig in signals.forever() {
+            if sig == signal_hook::consts::SIGUSR1 {
+                event_proxy.send_event(Event::ConfigReload(path.clone()));
+            }
+        }
+    });
+
        '') ];
        });
      };
    };
  }) ];
  hm.programs.alacritty = {
    enable = true;
    settings = with theme; {
      window = {
        dimensions = {
          columns = 80;
          lines = 25;
        };
        padding = {
          x = padding;
          y = padding;
        };
        decorations = "none";
      };
      font = {
        normal.family = font;
        size = 7;
      };
      colors = {
        primary = {
          inherit background foreground;
        };
        normal = {
          black   = background;
          red     = hot;
          green   = cold;
          yellow  = hot;
          blue    = cold;
          magenta = hot;
          cyan    = cold;
          white   = darkGrey;
        };
        bright = {
          black   = lightGrey;
          red     = hot;
          green   = cold;
          yellow  = hot;
          blue    = cold;
          magenta = hot;
          cyan    = cold;
          white   = foreground;
        };
      };
      selection.save_to_clipboard = true;
      cursor.style.blinking = "Always";
      key_bindings = [
        { key =  3; mods = "Alt"; chars = "\\e2"; }
        { key =  8; mods = "Alt"; chars = "\\e7"; }
        { key = 10; mods = "Alt"; chars = "\\e9"; }
        { key = 11; mods = "Alt"; chars = "\\e0"; }
      ];
    };
  };
}
