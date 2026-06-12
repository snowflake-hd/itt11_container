{ pkgs, self, lib }:

let
  colors = lib.colors;

  containerInformation = rec {
    container = "maria";
    actualName = "MariaDB";
  };
in
pkgs.mkShell {
  name = "mariadb-env";

  buildInputs = with pkgs; [
    docker
    mariadb
  ];

  shellHook = ''
    set -e

    ${lib.setupEnv { inherit colors; }}

    echo -e "$GREEN=== MariaDB Development Shell ===$NC"

    if [[ -f "$ENV_FILE" ]]; then
      echo -e "$YELLOW Loading .env from: $ENV_FILE $NC"
      set -a
      source "$ENV_FILE"
      set +a
    else
      echo -e "$YELLOW Loading defaults (no .env found)$NC"
      export MARIADB_ROOT_PASSWORD="schueler"
      export PORT_MARIADB="3308"
      export PORT_PHPMYADMIN="8082"
    fi

    PORT_MARIADB="''${PORT_MARIADB:-3308}"
    PORT_PHPMYADMIN="''${PORT_PHPMYADMIN:-8082}"
    MARIADB_ROOT_PASSWORD="''${MARIADB_ROOT_PASSWORD:-schueler}"
    export PORT_MARIADB PORT_PHPMYADMIN MARIADB_ROOT_PASSWORD

    ${lib.isComposeExisting {}}

    echo -e "$YELLOW Starting MariaDB and phpMyAdmin containers...$NC"
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d maria phpmyadmin 2>/dev/null || true

    echo -e "$YELLOW Waiting for MariaDB to be ready...$NC"

    max_attempts=30
    attempt=0

    while [[ $attempt -lt $max_attempts ]]; do
      maria_container=$(docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps -q maria 2>/dev/null) || true
      if [[ -n "$maria_container" ]] && docker exec "$maria_container" mariadb -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT 1;" &>/dev/null; then
        echo -e "$GREEN ✓ MariaDB is ready$NC"
        break
      fi
      attempt=$((attempt + 1))
      if [[ $attempt -ge $max_attempts ]]; then
        echo -e "$RED ERROR: MariaDB failed to start after $max_attempts attempts$NC"
        return 1
      fi
      echo -ne "$YELLOW Attempt $attempt/$max_attempts...$NC\r"
      sleep 1
    done

    if curl -s "http://127.0.0.1:$PORT_PHPMYADMIN" >/dev/null 2>&1; then
      echo -e "$GREEN ✓ phpMyAdmin is ready at http://127.0.0.1:$PORT_PHPMYADMIN$NC"
    else
      echo -e "$YELLOW phpMyAdmin starting, may take a moment$NC"
    fi

    connect() {
      mariadb --host=127.0.0.1 --port="$PORT_MARIADB" -u root -p"$MARIADB_ROOT_PASSWORD"
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
    echo "  connect        - Connect to MariaDB using mariadb-cli"
    echo "  status         - Show container status"
    echo "  restart_db     - Restart MariaDB container"
    echo "  logs_db        - View MariaDB logs"
    echo ""
    echo -e "$GREEN === Service Information ===$NC"
    echo "  MariaDB        - localhost:$PORT_MARIADB"
    echo "  phpMyAdmin     - http://localhost:$PORT_PHPMYADMIN"
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
