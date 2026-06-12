{pkgs, self, lib}:
let
 colors = lib.colors;
in
pkgs.mkShell {
    name = "mongodb-env";

    buildInputs = with pkgs; [
        docker
        mongodb-compass
        mongosh
    ];

    shellHook = ''
    set -e

    ${lib.setupEnv { inherit colors; }}
    echo -e "''${GREEN}=== MongoDB Development Shell ===''${NC}"

    if [[ -f "$ENV_FILE" ]]; then
      echo -e "$YELLOW Loading .env from: $ENV_FILE $NC"
      set -a
      source "$ENV_FILE"
      set +a
    else
      echo -e "$YELLOW Loading defaults (no .env found)$NC"
      export MONGODB_USER=root
      export MONGODB_ROOT_PASSWORD=schueler
      export PORT_MONGODB=27017
      export PORT_MONGOEXPRESS=8083
    fi

    PORT_MONGO="''${PORT_MONGODB:-27017}"
    PORT_MONGOEXPRESS="''${PORT_MONGOEXPRESS:-8083}"
    MONGODB_USER="''${MONGODB_USER:-root}"
    MONGODB_ROOT_PASSWORD="''${MONGODB_ROOT_PASSWORD:-schueler}"

    export PORT_MONGO PORT_MONGOEXPRESS MONGODB_USER MONGODB_ROOT_PASSWORD

    ${lib.isComposeExisting {}}


    '';
}