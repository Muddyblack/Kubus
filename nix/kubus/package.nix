# Kubus, packaged from the official Linux release AppImage.
#
# Deliberately written to nixpkgs conventions — plain callPackage arguments, no
# flake plumbing — so this exact file can be copied to nixpkgs as
# pkgs/by-name/ku/kubus/package.nix without edits. The flake at the repository
# root calls it, so the flake and a future nixpkgs entry never drift apart.
#
# Wrapping the release AppImage (instead of building the pnpm/Electron workspace
# from source) keeps the derivation small enough that Hydra and Cachix serve it
# as a plain download: nothing is compiled on a user's machine, and a release
# bump is a version plus a hash (see nix/update.sh).
{
  lib,
  fetchurl,
  appimageTools,
}:
let
  pname = "kubus";
  version = "0.8.1";

  src = fetchurl {
    url = "https://github.com/FloSch62/Kubus/releases/download/v${version}/kubus-${version}-linux-x86_64.AppImage";
    hash = "sha256-Pk/D+nHBYERf8+DXBsvsCZLODXS9AOnVx+7xcGqjy7s=";
  };

  # Unpacked only to lift the desktop entry and icons out of the image; the
  # runnable app itself comes from wrapType2 below.
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/kubus.desktop -t $out/share/applications

    # AppRun only exists inside the image. Point the entry at the wrapper and
    # keep %U so the kubus:// scheme handler still receives its argument.
    substituteInPlace $out/share/applications/kubus.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=kubus %U'

    for icon in ${appimageContents}/usr/share/icons/hicolor/*/apps/kubus.png; do
      size=$(basename "$(dirname "$(dirname "$icon")")")
      install -Dm444 "$icon" "$out/share/icons/hicolor/$size/apps/kubus.png"
    done
  '';

  meta = {
    description = "Free, open-source Kubernetes GUI for multi-cluster browsing, logs, exec, port-forward, metrics and Helm";
    homepage = "https://kubus-app.dev/";
    downloadPage = "https://github.com/FloSch62/Kubus/releases";
    changelog = "https://github.com/FloSch62/Kubus/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "kubus";
    # A nixpkgs submission fills this in with the submitter's handle.
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
