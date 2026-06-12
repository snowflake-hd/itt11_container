{pkgs, self, ...} :

pkgs.mkShell {
 name = "default";

 shellHook = ''
  echo -e "=== Available Commands ==="
  echo "  nix develop - this shell"
  echo "  nix develop .#mariadb - starts mariadb development environment with some tools"
  echo "  nix develop .#mongodb - starts mongodb development environment with some tools"
  echo ""
  exit 0
 '';
}