{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
}: let
  version = "0.0.1789764455-g07cced";

  nativeHashes = {
    "darwin-arm64" = "0qkc6n6yrd4w4i61xqcrlls36b8n2mnydqkbrvxrvgawd7a49p92";
    "darwin-x64" = "1fwpw2zl1kmarldx4ivmf39kfiss664vgi4i4iil0rk3p4xxbpnb";
    "linux-x64" = "1i84l5x1q0fsl4c1qm33abv9agh08ji1mg4fd4xmrzwjhgs8iy57";
    "linux-arm64" = "1j2c17rxh7ccq2xjnjk8lg47wwn0j9p4s786gxmqyppjcc1pv8g6";
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
