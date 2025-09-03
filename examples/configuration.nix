{
  config,
  lib,
  pkgs,
  ...
}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
    };
  };

  hardware.graphics.enable = true;

  # Enable icons, themes, dconf and other stuff useful for a graphical VM.
  services.xserver.desktopManager.xfce.enable = true;

  # HiDPI config
  #services.xserver.dpi = 284;
  #environment.variables= {
  #  "GDK_SCALE" = "2";
  #  "QT_SCALE_FACTOR" = "2.0";
  #  "PLASMA_USE_QT_SCALING" = "1";
  #};

  environment.systemPackages = with pkgs; [
    xterm
    xfce.xfce4-terminal
  ];
}
