# Separate package for .desktop files, so we can reference the resholved script paths.
# There has to be a better way to do this.
{
  lib,
  pkgs,
  fetchFromGitHub,
  qubes-gui-agent-linux,
  bash,
}:
let
  packageInfo = import ./package_info.nix;
in
  pkgs.stdenv.mkDerivation rec {
    version = packageInfo.version;
    pname = "qubes-gui-agent-linux-desktop";
  
    src = fetchFromGitHub {
      owner = "QubesOS";
      repo = "qubes-gui-agent-linux";
      rev = "v${version}";
      hash = packageInfo.hash;
    };

    buildInputs = [
      qubes-gui-agent-linux
    ];
  
    buildPhase = "";
  
    installPhase = ''
      mkdir -p $out/etc/xdg/autostart
      cp \
        appvm-scripts/etc/xdgautostart/qubes-pulseaudio.desktop \
        window-icon-updater/qubes-icon-sender.desktop \
        appvm-scripts/etc/xdgautostart/qubes-qrexec-fork-server.desktop \
        appvm-scripts/etc/xdgautostart/qubes-keymap.desktop \
        appvm-scripts/etc/xdgautostart/qubes-gtk4-workarounds.desktop \
        $out/etc/xdg/autostart

      # Run through shell to get the user environment, as this services environment will
      # be inherited by programs the user runs through the menu.
      substituteInPlace "$out/etc/xdg/autostart/qubes-qrexec-fork-server.desktop" --replace-fail \
        '/usr/bin/qrexec-fork-server' "${bash}/bin/sh --login -c \"exec ${qubes-gui-agent-linux}/bin/qrexec-fork-server\""
      substituteInPlace "$out/etc/xdg/autostart/qubes-gtk4-workarounds.desktop" --replace-fail \
        '/usr/lib/qubes/gtk4-workarounds.sh' "${bash}/bin/sh --login -c \"exec ${qubes-gui-agent-linux}/lib/qubes/gtk4-workarounds.sh\""
      substituteInPlace "$out/etc/xdg/autostart/qubes-icon-sender.desktop" --replace-fail \
        '/usr/lib/qubes/icon-sender' "${bash}/bin/sh --login -c \"exec ${qubes-gui-agent-linux}/lib/qubes/icon-sender\""
      substituteInPlace "$out/etc/xdg/autostart/qubes-keymap.desktop" --replace-fail \
        '/usr/lib/qubes/qubes-keymap.sh' "${bash}/bin/sh --login -c \"exec ${qubes-gui-agent-linux}/lib/qubes/qubes-keymap.sh\""
    '';
  
    meta = with lib; {
      description = "The Qubes GUI Agent for AppVMs - .desktop files";
      homepage = "https://qubes-os.org";
      license = licenses.gpl2Plus;
      maintainers = [];
      platforms = platforms.linux;
    };
  }
