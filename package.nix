{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
}: let
  version = "0.0.1793174452-gd75e9a";

  nativeHashes = {
    "darwin-arm64" = "0m0fqbi03gj00rizk32904jlj1gbb7yxs79wggq001z2w0y7aj9n";
    "darwin-x64" = "1j7ia72j9kgd631cyyl92sbf937pg0vz5cpvvnpq85bb19r85l0y";
    "linux-x64" = "1196a2ikqh41jk9x6sybdhdig1r642wnxfk0gaf3jjx2hr4am5ik";
    "linux-arm64" = "1myd7xkhkdrz7salhl81xqzwwnwaisay48q4rj8ljhamcr9ia116";
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
