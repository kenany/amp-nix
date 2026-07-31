{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
}: let
  version = "0.0.1785529588-g247d53";

  nativeHashes = {
    "darwin-arm64" = "1pxs4c6ljiwpa36q83p6lzhcklaycw4zlk5wkka3n079ciqnkhkg";
    "darwin-x64" = "1p30vnwnbvb54jza3bbbc3jbkrg1fwrphv21flnivd42q11ykisf";
    "linux-x64" = "1p2k8slbaa86xa2vgqh0iazr2b60rdgcgj098qckaw42858d4wx5";
    "linux-arm64" = "1bi03zyvwvxxwy1faf4543xnag0frmjcghb14y7a1qfccsi4kwbg";
  };

  # Nix system -> Amp platform
  platformMap = {
    "aarch64-darwin" = "darwin-arm64";
    "x86_64-darwin" = "darwin-x64";
    "x86_64-linux" = "linux-x64";
    "aarch64-linux" = "linux-arm64";
  };

  platform = platformMap.${stdenv.hostPlatform.system} or null;

  nativeBinaryUrl = "https://static.ampcode.com/cli/${version}/amp-${platform}";

  nativeBinary =
    if platform != null
    then
      fetchurl {
        url = nativeBinaryUrl;
        sha256 = nativeHashes.${platform};
      }
    else null;
in
  assert platform != null || throw "Amp native runtime is not supported on ${stdenv.hostPlatform.system}. Supported: aarch64-darwin, x86_64-darwin, x86_64-linux, aarch64-linux";
    stdenv.mkDerivation rec {
      pname = "amp-cli";
      inherit version;

      dontStrip = true;
      dontUnpack = true;

      nativeBuildInputs =
        [makeBinaryWrapper]
        ++ lib.optionals stdenv.hostPlatform.isElf [autoPatchelfHook];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin

        install -m755 ${nativeBinary} $out/bin/.amp-unwrapped

        makeBinaryWrapper $out/bin/.amp-unwrapped $out/bin/amp \
          --set AMP_SKIP_UPDATE_CHECK 1 \
          --set AMP_HOME "$HOME/.amp"

        runHook postInstall
      '';

      meta = with lib; {
        description = "Amp - Frontier coding agent for your terminal and editor";
        homepage = "https://ampcode.com";
        license = licenses.unfree;
        platforms = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux"];
        mainProgram = "amp";
      };
    }
