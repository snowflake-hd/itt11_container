{pkgs, self, ...}:
pkgs.mkShell {
    name = "mongodb-env";

    buildInputs = with pkgs; [
        docker
        mongodb-compass
        mongosh
    ];

    shellHook = ''
    set -e

    COMPOSE_FILE="$PWD/docker-compose.yml"
    ENV_FILE="$PWD/.env"
    PROJECT_NAME="itt11-mariadb"

    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'

    echo -e "''${GREEN}=== MongoDB Development Shell ===''${NC}"

    '';
}