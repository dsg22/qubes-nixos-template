{
  lib,
  fetchFromGitHub,
  makeWrapper,
  qubes-template-resholve,
  autoPatchelfHook,
  autoconf,
  automake,
  bash,
  gnugrep,
  coreutils,
  pciutils,
  libtool,
  libXt,
  lsb-release,
  libunistring,
  gawk,
  git,
  gnused,
  libgbm,
  pam,
  patch,
  pipewire,
  pixman,
  pkg-config,
  python3,
  python3Packages,
  pulseaudio,
  qubes-core-qrexec,
  qubes-core-agent-linux,
  qubes-core-vchan-xen,
  qubes-core-qubesdb,
  qubes-gui-common,
  systemd,
  util-linux,
  which,
  xen,
  xfce,
  xorg,
  zenity,
}:
let
  packageInfo = import ./package_info.nix;
  pythonWithXcffib = python3.withPackages (
    python-pkgs: with python-pkgs; [
      xcffib
    ]
  );
in
  qubes-template-resholve.mkDerivation rec {
    version = packageInfo.version;
    pname = "qubes-gui-agent-linux";

    src = fetchFromGitHub {
      owner = "QubesOS";
      repo = pname;
      rev = "v${version}";
      hash = packageInfo.hash;
    };

    patches = [
      ./qubes-session-environment.patch
    ];

    nativeBuildInputs =
      [
        autoPatchelfHook
        makeWrapper
        pkg-config
        patch
        git
        libgbm
        automake
        autoconf
        libtool
        pam
        pulseaudio
        pipewire
        libXt
        pixman
        lsb-release
        qubes-gui-common
        qubes-core-vchan-xen
        qubes-core-qubesdb
        xen
      ]
      ++ (with xorg; [
        libXdamage
        libXcomposite
        utilmacros
        xorgserver
      ]);

    buildInputs =
      [
        coreutils
        qubes-core-vchan-xen
        qubes-core-qubesdb
        pam
        zenity
        python3Packages.xcffib
        libunistring
        systemd
        xfce.xfconf
        pythonWithXcffib
        # xdg-user-dirs-update
      ]
      ++ (with xorg; [
        libXcomposite
        libXdamage
        xinit
        xrandr
        xprop
        xsetroot
      ]);

    postPatch = ''
      rm -f pulse/pulsecore
      ln -s "pulsecore-17.0" pulse/pulsecore

      # since we don't know the final resholved package
      # path, it's easiest if we instead configure PATH later
      sed -i -e 's#execl("/usr/bin/qubes-run-xorg",#execlp("qubes-run-xorg",#' gui-agent/vmside.c
    '';

    buildPhase = ''
      make appvm
    '';

    # FIXME sub xdg autostart paths
    # FIXME nixgl
    installPhase = ''
      make install-rh-agent \
          DESTDIR="$out" \
          LIBDIR=/lib \
          USRLIBDIR=/lib \
          SYSLIBDIR=/lib

      # overwrite the broken symlink created by make install-rh-agent
      ln -sf ../../bin/qubes-set-monitor-layout $out/etc/qubes-rpc/qubes.SetMonitorLayout
      ln -sf ../../bin/qubes-start-xephyr $out/etc/qubes-rpc/qubes.GuiVMSession

      # these are nested within runuser calls, easier to just substituteInPlace
      # and pretend to resholve that runuser is not executing it's args
      substituteInPlace "$out/usr/bin/qubes-run-xorg" --replace ' /bin/sh' ' ${bash}/bin/sh'
      substituteInPlace "$out/usr/bin/qubes-run-xorg" --replace '/usr/bin/xinit' '${xorg.xinit}/bin/xinit'

      # skip the wrapper since it's just to determine which binary to call
      substituteInPlace "$out/usr/bin/qubes-run-xorg" --replace '/usr/lib/qubes/qubes-xorg-wrapper' "${xorg.xorgserver}/bin/Xorg"

      # config file template and rendered config relocation
      substituteInPlace "$out/usr/bin/qubes-run-xorg" --replace '/etc/X11/xorg-qubes.conf.template' "$out/etc/X11/xorg-qubes.conf.template"
      substituteInPlace "$out/usr/bin/qubes-run-xorg" --replace ' /etc/X11/xorg-qubes.conf' ' /var/run/xorg-qubes.conf'
      substituteInPlace "$out/usr/bin/qubes-run-xorg" --replace '-config xorg-qubes.conf' '-config /var/run/xorg-qubes.conf'

      substituteInPlace "$out/usr/lib/qubes/icon-sender" --replace-fail \
        '#!/usr/bin/python3' "#!${pythonWithXcffib}/bin/python"

      # resholve won't replace the absolute path reference in this conditional,
      # we can just substitute with true
      # FIXME this wasn't actually replaced properly before...
      # substituteInPlace "$out/usr/bin/qubes-run-xorg" --replace 'if [ -x /bin/loginctl ]; then' 'if [ true ]; then'

      cat >> $out/etc/X11/xorg-qubes.conf.template <<EOF
      Section "Files"
        ModulePath "${xorg.xorgserver}/lib/xorg/modules"
        ModulePath "${xorg.xorgserver}/lib/xorg/modules/extensions"
        ModulePath "${xorg.xorgserver}/lib/xorg/modules/drivers"
        ModulePath "$out/lib/xorg/modules/drivers"
      EndSection
      EOF

      mv "$out/usr/bin" "$out/bin"
      mv "$out/usr/share" "$out/share"
      mv "$out/usr/lib/qubes" "$out/lib/qubes"
      mv "$out/usr/lib/sysctl.d" "$out/lib/sysctl.d"

      rm -rf "$out/usr"
    '';

    postResholveFixup = ''
      # Run through shell to get the user environment, as this services environment will
      # be inherited by programs the user runs through the menu.
      substituteInPlace "$out/etc/xdg/autostart/qubes-qrexec-fork-server.desktop" --replace-fail \
        '/usr/bin/qrexec-fork-server' "${bash}/bin/sh --login -c \"exec $out/bin/qrexec-fork-server\""

      substituteInPlace "$out/etc/xdg/autostart/qubes-gtk4-workarounds.desktop" --replace-fail \
        '/usr/lib/qubes/gtk4-workarounds.sh' "$out/lib/qubes/gtk4-workarounds.sh"
      substituteInPlace "$out/etc/xdg/autostart/qubes-icon-sender.desktop" --replace-fail \
        '/usr/lib/qubes/icon-sender' "$out/lib/qubes/icon-sender-wrapped"
      substituteInPlace "$out/etc/xdg/autostart/qubes-keymap.desktop" --replace-fail \
        '/usr/lib/qubes/qubes-keymap.sh' "$out/lib/qubes/qubes-keymap.sh"
      '';

    solutions = {
      default = {
        scripts = [
          "lib/qubes/qubes-gui-agent-pre.sh"
          "lib/qubes/qubes-keymap.sh"
          "bin/qubes-run-xorg"
          "bin/qubes-session"
          "etc/X11/xinit/xinitrc.d/50guivm-windows-prefix.sh"
          "etc/X11/xinit/xinitrc.d/60xfce-desktop.sh"
        ];
        interpreter = "none";
        fake = {
          # ignore for now, these paths are present in file check so the paths won't be reached
          source = [
            "/etc/X11/xinit/xinitrc.d/qubes-keymap.sh"
            "/etc/X11/Xsession.d/90qubes-keymap"
          ];
          # just ignore this, currently guarded by an unreplaced conditional
          # using which which is always false
          external = [
            "xdg-user-dirs-update"
          ];
        };
        fix = {
          source = ["/usr/lib/qubes/init/functions"];
          "/usr/bin/qubes-gui-runuser" = true;
          "/usr/bin/qubesdb-read" = true;
        };
        inputs = [
          "bin"
          "${qubes-core-agent-linux}/lib/qubes"
          "${qubes-core-agent-linux}/lib/qubes/init/functions"
          qubes-core-qubesdb
          bash
          coreutils
          gawk
          gnused
          gnugrep
          qubes-core-qubesdb
          systemd
          util-linux
          pciutils
          which
          xfce.xfce4-settings
          xfce.xfconf
          xorg.xprop
          xorg.xinit
          xorg.xsetroot
          xorg.setxkbmap
        ];
        keep = {
          source = [
            "$HOME"
            "/etc/X11/xinit/xinitrc.d/qubes-keymap.sh"
            "/etc/X11/Xsession.d/90qubes-keymap"
          ];
          "$XSESSION" = true;
        };
        execer = [
          "cannot:${systemd}/bin/systemctl"
          "cannot:${xfce.xfce4-settings}/bin/xfsettingsd"
          "cannot:${xfce.xfconf}/bin/xfconf-query"
          # lies
          "cannot:bin/qubes-gui-runuser"
          "cannot:${util-linux}/bin/runuser"
        ];
      };
    };

    postFixup = ''
      # set the qrexec paths and override PATH so that we can
      # launch programs similar to the user from a login shell
      makeWrapper "${qubes-core-qrexec}/bin/qrexec-fork-server" "$out/bin/qrexec-fork-server" \
        --run "export QREXEC_SERVICE_PATH=\$(${systemd}/bin/systemctl cat qubes-qrexec-agent.service | ${gnugrep}/bin/grep -Po '(?<=QREXEC_SERVICE_PATH=)[^\"\n]*')" \
        --set QREXEC_MULTIPLEXER_PATH "${qubes-core-qrexec}/lib/qubes/qubes-rpc-multiplexer" \
        --set PATH "/run/wrappers/bin:/home/user/.nix-profile/bin:/nix/profile/bin:/home/user/.local/state/nix/profile/bin:/etc/profiles/per-user/user/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"

      makeWrapper "$out/lib/qubes/icon-sender" "$out/lib/qubes/icon-sender-wrapped" \
        --prefix PATH : ${lib.makeBinPath [ qubes-core-qrexec ]}
    '';

    meta = with lib; {
      description = "The Qubes GUI Agent for AppVMs";
      homepage = "https://qubes-os.org";
      license = licenses.gpl2Plus;
      maintainers = [];
      platforms = platforms.linux;
    };
  }
