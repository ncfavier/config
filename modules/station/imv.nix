{ lib, config, ... }: with lib; {
  nixpkgs.overlays = [ (self: super: {
    imv = super.imv.overrideAttrs (old: {
      patches = [ (builtins.toFile "imv-gif-default-delay.patch" ''
diff --git a/src/backend_freeimage.c b/src/backend_freeimage.c
index f354ea5..749a572 100644
--- a/src/backend_freeimage.c
+++ b/src/backend_freeimage.c
@@ -139,7 +139,8 @@ static void first_frame(void *raw_private, struct imv_image **image, int *framet
     FreeImage_GetMetadata(FIMD_ANIMATION, frame, "FrameTime", &tag);
     if (FreeImage_GetTagValue(tag)) {
       *frametime = *(int*)FreeImage_GetTagValue(tag);
-    } else {
+    }
+    if (*frametime == 0) {
       *frametime = 100; /* default value for gifs */
     }
     bmp = FreeImage_ConvertTo24Bits(frame);
      '') ];
      postPatch = ''
        sed -i 's/level >= IMV_INFO/1/g' src/imv.c
      '';
    });
  }) ];

  hm.programs.imv = {
    enable = true;
    settings = {
      options = {
        background = removePrefix "#" config.theme.background;
        overlay_font = "monospace:18";
        title_text = "imv - [$imv_current_index/$imv_file_count] $imv_current_file";
      };
      binds = {
        i = "overlay";
        "<Escape>" = "quit";
        "<Shift+period>" = "next_frame";
        "<less>" = "prev";
        "<Shift+greater>" = "next";
      };
    };
  };
}
