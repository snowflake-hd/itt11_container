# ITT11 Container Solution

Docker-containerisierte Lösung für IoT-Technologien

## Installation

1. **Voraussetzungen:**
   - Docker & Docker Compose installiert
   - Git installiert

2. **Repository klonen:**
   ```bash
   git clone <repository-url>
   cd itt11_container
   ```

3. **Umgebungsvariablen:**
   - `.env` Datei ist bereits konfiguriert
   - Bei Bedarf Passwörter und Ports anpassen

## Container

| Service | Beschreibung | Port | Web-Interface |
|---------|--------------|------|---------------|
| **maria** | MariaDB Datenbank | 3308 | - |
| **phpmyadmin** | DB-Verwaltung | 8082 | http://localhost:8082 |
| **mongodb** | MongoDB Datenbank | 27017 | - |
| **mongo-express** | MongoDB-Verwaltung | 8083 | http://localhost:8083 |
| **opc-router** | OPC Router Runtime | 8081 | http://localhost:8081 |
| **opc-ua-browser** | OPC-UA Browser | 4000 | http://localhost:4000 |
| **nodered** | Node-RED | 1880 | http://localhost:1880 |
| **mosquitto** | MQTT Broker | 1883 | - |

## Container starten

```bash
# Alle Container starten
docker-compose up -d

# Einzelne Container starten
docker-compose up -d maria phpmyadmin
docker-compose up -d mongodb mongo-express
docker-compose up -d opc-router opc-ua-browser
docker-compose up -d nodered mosquitto

# Container stoppen
docker-compose down

# Logs anzeigen
docker-compose logs <service-name>
```

## Standard-Zugangsdaten

- **MariaDB/MongoDB:** root / schueler
- **Mongo Express:** Keine Authentifizierung (deaktiviert)
