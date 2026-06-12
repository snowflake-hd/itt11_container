{ pkgs, self }:

pkgs.mkShell {
  name = "mariadb-env";

  buildInputs = with pkgs; [
    docker
    docker-compose
    mariadb
    curl
    jq
  ];

  shellHook = ''
    set -euo pipefail

    COMPOSE_FILE="${self}/docker-compose.yml"
    ENV_FILE="${self}/.env"
    PROJECT_NAME="itt11-mariadb"

    # Colors for output
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    echo -e "''${GREEN}=== MariaDB Development Shell ===''${NC}"

    # Load environment variables
    if [[ -f "$ENV_FILE" ]]; then
      echo -e "''${YELLOW}Loading .env from: $ENV_FILE''${NC}"
      set -a
      # shellcheck disable=SC1090
      source "$ENV_FILE"
      set +a
    elif [[ -f "$PWD/.env" ]]; then
      echo -e "''${YELLOW}Loading .env from current working directory: $PWD/.env''${NC}"
      set -a
      # shellcheck disable=SC1091
      source "$PWD/.env"
      set +a
    else
      echo -e "''${RED}No .env file found - using defaults''${NC}"
      export MARIADB_ROOT_PASSWORD="schueler"
      export PORT_MARIADB="3308"
      export PORT_PHPMYADMIN="8082"
    fi

    # Validate required variables
    if [[ -z "$${MARIADB_ROOT_PASSWORD-}" ]]; then
      echo -e "''${RED}ERROR: MARIADB_ROOT_PASSWORD not set''${NC}"
      return 1
    fi

    if [[ -z "$${PORT_MARIADB-}" ]]; then
      export PORT_MARIADB="3308"
    fi

    if [[ -z "$${PORT_PHPMYADMIN-}" ]]; then
      export PORT_PHPMYADMIN="8082"
    fi

    # Verify compose file exists
    if [[ ! -f "$COMPOSE_FILE" ]]; then
      echo -e "''${RED}ERROR: compose file not found at $COMPOSE_FILE''${NC}"
      return 1
    fi

    # Start containers
    echo -e "''${YELLOW}Starting MariaDB and phpMyAdmin containers...''${NC}"
    docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d maria phpmyadmin 2>/dev/null || {
      echo -e "''${RED}ERROR: Failed to start containers''${NC}"
      return 1
    }

    # Wait for MariaDB to be ready
    echo -e "''${YELLOW}Waiting for MariaDB to be ready...''${NC}"
    max_attempts=30
    attempt=0
    until mariadb --host=127.0.0.1 --port="$${PORT_MARIADB}" -u root -p"$${MARIADB_ROOT_PASSWORD}" -e "SELECT 1;" &>/dev/null; do
      attempt=$((attempt + 1))
      if [[ $attempt -ge $max_attempts ]]; then
        echo -e "''${RED}ERROR: MariaDB failed to start after $max_attempts attempts''${NC}"
        return 1
      fi
      echo -ne "''${YELLOW}Attempt $attempt/$max_attempts...''${NC}\r"
      sleep 1
    done
    echo -e "''${GREEN}✓ MariaDB is ready''${NC}"

    # Check phpMyAdmin
    if curl -s http://127.0.0.1:$${PORT_PHPMYADMIN} >/dev/null 2>&1; then
      echo -e "''${GREEN}✓ phpMyAdmin is ready at http://127.0.0.1:$${PORT_PHPMYADMIN}''${NC}"
    else
      echo -e "''${YELLOW}phpMyAdmin starting, may take a moment''${NC}"
    fi

    # Define helper functions
    connect() {
      mariadb --host=127.0.0.1 \
        --port="$${PORT_MARIADB}" \
        -u root \
        -p"$${MARIADB_ROOT_PASSWORD}"
    }

    status() {
      echo -e "''${YELLOW}=== Container Status ===''${NC}"
      docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" ps
    }

    restart_db() {
      echo -e "''${YELLOW}Restarting MariaDB...''${NC}"
      docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" restart maria
      sleep 2
      echo -e "''${GREEN}✓ MariaDB restarted''${NC}"
    }

    logs_db() {
      docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" logs -f maria
    }

    export -f connect status restart_db logs_db

    # Print available commands
    echo ""
    echo -e "''${GREEN}=== Available Commands ===''${NC}"
    echo "  connect        - Connect to MariaDB using mariadb-cli"
    echo "  status         - Show container status"
    echo "  restart_db     - Restart MariaDB container"
    echo "  logs_db        - View MariaDB logs"
    echo ""
    echo -e "''${GREEN}=== Service Information ===''${NC}"
    echo "  MariaDB        - localhost:$${PORT_MARIADB}"
    echo "  phpMyAdmin     - http://localhost:$${PORT_PHPMYADMIN}"
    echo ""

    # Cleanup on exit
    cleanup() {
      echo ""
      echo -e "''${YELLOW}Shutting down containers...''${NC}"
      docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down 2>/dev/null || true
      echo -e "''${GREEN}✓ Cleanup complete''${NC}"
    }

    trap cleanup EXIT
  '';
}