{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
}: let
  version = "0.0.1792008042-gef0030";

  nativeHashes = {
    "darwin-arm64" = "14qj27023g1mq1zilkndfq0r6wf15q7xkr5663pb1jyfia660kd6";
    "darwin-x64" = "16hmn45v029zwws3k05yncz8l3r3gr3xfgvwn44iw5ipj22kp9hp";
    "linux-x64" = "1yxbpm1v5wmczlqgscdirqh7chak54ihvhk1anwrgavgb79y8491";
    "linux-arm64" = "0kx95c53kp8848f4bn6yn73bqz4w0c76qrqn597m91y5xpn895y5";
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
