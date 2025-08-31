{
  lib,
  fetchFromGitHub,
  python3Packages,
  qubes-core-qubesdb,
}:
let
  packageInfo = import ./package_info.nix;
in
  python3Packages.buildPythonPackage rec {
    pname = "python-qubesdb";
    sourceRoot = "source/python";
    version = packageInfo.version;
    pyproject = true;

    nativeBuildInputs = [
    ];
    buildInputs = [
      qubes-core-qubesdb
    ];

    src = fetchFromGitHub {
      owner = "QubesOS";
      repo = "qubes-core-qubesdb";
      rev = "v${packageInfo.version}";
      hash = packageInfo.hash;
    };

    build-system = with python3Packages; [
      setuptools
      wheel
    ];
  }
