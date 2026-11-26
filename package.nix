{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
}: let
  version = "0.0.1795665646-gb77778";

  nativeHashes = {
    "darwin-arm64" = "1hkp93c6fkn3zs3wcjgf26syxnznj30fwklpgrwdzfr3plnxs5cz";
    "darwin-x64" = "00rw6na7xhmr9si5b0p71vilmxwcbw5g2nqqn3rlap9fynzxhb2f";
    "linux-x64" = "0gbml9cy4ryh6rgxf8dipbnr88ir0ja349a6r2d3dz5gi62749kq";
    "linux-arm64" = "01i5b0v09ki8wr5x6xmm631r6qcg9zmsn973w11sq5fchzidsqm7";
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
