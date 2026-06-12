{ pkgs, self, lib }:

let
  colors = lib.colors;

  containerInformation = rec {
    container = "mongodb";
    actualName = "MongoDB";
  };
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
    echo -e "$GREEN=== MongoDB Development Shell ===$NC"

    if [[ -f "$ENV_FILE" ]]; then
      echo -e "$YELLOW Loading .env from: $ENV_FILE $NC"
      set -a
      source "$ENV_FILE"
      set +a
    else
      echo -e "$YELLOW Loading defaults (no .env found)$NC"
      export MONGODB_ROOT_PASSWORD="schueler"
      export MONGODB_USER="root"
      export PORT_MONGODB="27017"
      export PORT_MONGOEXPRESS="8081"
    fi

    PORT_MONGODB="''${PORT_MONGODB:-27017}"
    PORT_MONGOEXPRESS="''${PORT_MONGOEXPRESS:-8081}"
    MONGODB_ROOT_PASSWORD="''${MONGODB_ROOT_PASSWORD:-schueler}"
    MONGODB_USER="''${MONGODB_USER:-root}"
    export PORT_MONGODB PORT_MONGOEXPRESS MONGODB_ROOT_PASSWORD MONGODB_USER

    ${lib.isComposeExisting {}}

    echo -e "$YELLOW Starting MongoDB and Mongo Express containers...$NC"
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d mongodb mongo-express 2>/dev/null || true

    echo -e "$YELLOW Waiting for MongoDB to be ready...$NC"

    max_attempts=30
    attempt=0

    while [[ $attempt -lt $max_attempts ]]; do
      mongo_container=$(docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps -q mongodb 2>/dev/null) || true
      if [[ -n "$mongo_container" ]] && docker exec "$mongo_container" mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
        echo -e "$GREEN ✓ MongoDB is ready$NC"
        break
      fi
      attempt=$((attempt + 1))
      if [[ $attempt -ge $max_attempts ]]; then
        echo -e "$RED ERROR: MongoDB failed to start after $max_attempts attempts$NC"
        return 1
      fi
      echo -ne "$YELLOW Attempt $attempt/$max_attempts...$NC\r"
      sleep 1
    done

    if curl -s "http://127.0.0.1:$PORT_MONGOEXPRESS" >/dev/null 2>&1; then
      echo -e "$GREEN ✓ Mongo Express is ready at http://127.0.0.1:$PORT_MONGOEXPRESS$NC"
    else
      echo -e "$YELLOW Mongo Express starting, may take a moment$NC"
    fi


    connect() {
      echo -e "$YELLOW Connecting to MongoDB cluster at mongodb://127.0.0.1:$PORT_MONGODB$NC"
      mongosh "mongodb://127.0.0.1:$PORT_MONGODB"
    }

    status() {
      ${lib.containerStatus {}}
    }

    restart_db() {
      ${lib.restartContainer containerInformation}
    }

    logs_db() {
      ${lib.containerLogs { container = containerInformation.container; }}
    }

    export -f connect status restart_db logs_db

    echo ""
    echo -e "$GREEN === Available Commands ===$NC"
    echo "  connect        - Connect to MongoDB using mongosh CLI"
    echo "  status         - Show container status"
    echo "  restart_db     - Restart MongoDB container"
    echo "  logs_db        - View MongoDB logs"
    echo ""
    echo -e "$GREEN === Service Information ===$NC"
    echo "  MongoDB        - localhost:$PORT_MONGODB"
    echo "  Mongo Express  - http://localhost:$PORT_MONGOEXPRESS"
    echo ""

    cleanup() {
      echo ""
      echo -e "$YELLOW Shutting down containers...$NC"
      docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down 2>/dev/null || true
      echo -e "$GREEN ✓ Cleanup complete$NC"
    }

    trap cleanup EXIT
  '';
}
