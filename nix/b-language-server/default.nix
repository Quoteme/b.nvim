{
  lib,
  stdenv,
  fetchFromGitHub,
  gradle_9,
  jdk17,
  makeWrapper,
  graphviz,
  runCommand,
  runtimeShell,
  prob,
}:

let
  gradle = gradle_9;

  # prob-java starts `probcli.sh -sf` from the ProB home, but the upstream
  # script chmods its siblings, which fails in the read-only Nix store.
  probHome = runCommand "prob-home" { } ''
    mkdir $out
    ln -s ${prob}/share/prob/* $out/
    rm $out/probcli.sh
    cat > $out/probcli.sh <<EOF
    #!${runtimeShell}
    exec ${prob}/share/prob/probcli "\$@"
    EOF
    chmod +x $out/probcli.sh
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "b-language-server";
  version = "0-unstable-2026-10-30";

  src = fetchFromGitHub {
    owner = "Quoteme";
    repo = "b-language-server";
    rev = "56661e2a18f471c1d6c15f8ada0862ea566405dd";
    hash = "sha256-xXSHCdOSUqvJg40SD6m2nknlB3Pbm7kP2r2FRM0SvBI=";
  };

  nativeBuildInputs = [
    gradle
    makeWrapper
  ];

  mitmCache = gradle.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  __darwinAllowLocalNetworking = true;

  gradleBuildTask = "shadowJar";
  gradleFlags = [ "-Dorg.gradle.java.home=${jdk17}" ];

  installPhase = ''
    runHook preInstall

    install -Dm644 build/libs/*-all.jar $out/share/b-language-server/b-language-server.jar
    makeWrapper ${jdk17}/bin/java $out/bin/b-language-server \
      --prefix PATH : ${lib.makeBinPath [ graphviz ]} \
      --add-flags "-Dprob.home=${probHome}" \
      --add-flags "-jar $out/share/b-language-server/b-language-server.jar"

    runHook postInstall
  '';

  meta = {
    description = "Language server for the B method, using ProB as backend";
    homepage = "https://github.com/Quoteme/b-language-server";
    license = lib.licenses.epl20;
    mainProgram = "b-language-server";
    platforms = lib.platforms.linux;
  };
})
