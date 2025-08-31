{
  lib,
  fetchFromGitHub,
  python3Packages,
}:
let
  packageInfo = import ./package_info.nix;
  pyprojectConfig = ./python-qubesagent_pyproject.toml;
in
  python3Packages.buildPythonPackage rec {
    pname = "python-qubesagent";
    version = packageInfo.version;
    pyproject = true;

    nativeBuildInputs = [
    ];
    buildInputs = [
      python3Packages.pygobject3
      python3Packages.pyxdg
    ];

    postPatch = ''
      sed 's/_REPLACEME_VERSION/${version}/' ${pyprojectConfig} > ./pyproject.toml
    '';

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

