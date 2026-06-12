{
  colors = {
    green = ''\033[0;32m'';
    yellow = ''\033[1;33m'';
    red = ''\033[0;31m'';
    nc = ''\033[0m'';
  };

  setupEnv = { colors }:
    let
      inherit (colors) green yellow red nc;
    in
    ''
      COMPOSE_FILE="$PWD/docker-compose.yml"
      ENV_FILE="$PWD/.env"
      PROJECT_NAME="itt11-mariadb"

      GREEN='${green}'
      YELLOW='${yellow}'
      RED='${red}'
      NC='${nc}'
      export COMPOSE_FILE ENV_FILE PROJECT_NAME GREEN YELLOW RED NC
    '';

  isComposeExisting = {} : ''
    if [[ ! -f "$COMPOSE_FILE" ]]; then
      echo -e "$RED ERROR: compose file not found at $COMPOSE_FILE$NC"
      return 1
    fi
  '';
}
