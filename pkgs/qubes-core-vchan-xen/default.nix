{
  lib,
  stdenv,
  fetchFromGitHub,
  xen,
}:
stdenv.mkDerivation rec {
  pname = "qubes-core-vchan-xen";
  version = "4.2.7";

  src = fetchFromGitHub {
    owner = "QubesOS";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-yMCLduZUK7EW3QL82p7hJTMoDsivI+r76LEFsS8brxU=";
  };

  buildInputs = [xen];

  buildPhase = ''
    make all PREFIX=/ LIBDIR="$out/lib" INCLUDEDIR="$out/include"
  '';

  installPhase = ''
    make install DESTDIR=$out PREFIX=/
  '';

  env.CFLAGS = "-DHAVE_XC_DOMAIN_GETINFO_SINGLE";

  meta = with lib; {
    description = "Libraries required for the higher-level Qubes daemons and tools";
    homepage = "https://qubes-os.org";
    license = licenses.gpl2Plus;
    maintainers = [];
    platforms = platforms.linux;
  };
}
