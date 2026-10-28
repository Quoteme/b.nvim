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
  version = "0-unstable-2025-10-10";

  src = fetchFromGitHub {
    owner = "hhu-stups";
    repo = "b-language-server";
    rev = "16595180e7e02666d0544d6b554715637c3a7ca4";
    hash = "sha256-qCh+7LzXDtB9mO1lxyoZ+1X7BKqWgtvnuByQDSSeMcc=";
  };

  patches = [
    # Adds a `--stdio` transport, checks documents on open and save only,
    # tolerates partial client settings, publishes file:// URIs, and matches
    # prob-java to probcli 1.16.
    ./client-compat.patch
    # Checks Event-B machines and contexts written in Camille notation like
    # Rodin: static checks, proof obligations discharged with ProB, model
    # checking and animation as code actions, and hover documentation.
    ./eventb-camille.patch
  ];

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
    homepage = "https://github.com/hhu-stups/b-language-server";
    license = lib.licenses.epl20;
    mainProgram = "b-language-server";
    platforms = lib.platforms.linux;
  };
})
