#docker compose -f docker-compose.yml down
#docker system prune -a --volumes --force
docker network prune --force && docker container prune --force && docker volume prune --force

# Potainer folder creation & assiging permission
sudo mkdir -p /opt/docker/portainer/data && sudo chown -R 200 /opt/docker/portainer/data

# Nexus folder creation & assigning permission
sudo mkdir -p /opt/docker/nexus/nexus-data && sudo chown -R 200 /opt/docker/nexus/nexus-data
sudo mkdir -p /opt/docker/nexus/sonatype-work && sudo chown -R 200 /opt/docker/nexus/sonatype-work

# MySQL folder creation & assigning permission
sudo mkdir -p /opt/docker/mysql/mysql820/conf.d && sudo chown -R 200 /opt/docker/mysql/mysql820/conf.d
sudo mkdir -p /opt/docker/mysql/mysql820/mysql-data && sudo chown -R 200 /opt/docker/mysql/mysql820/mysql-data
sudo mkdir -p /opt/docker/mysql/mysql820/init && sudo chown -R 200 /opt/docker/mysql/mysql820/init

# Postgres folder creation & assigning permission
sudo mkdir -p /opt/docker/postgres/data && sudo chown -R 200 /opt/docker/postgres/data
sudo mkdir -p /opt/docker/postgres/db && sudo chown -R 200 /opt/docker/postgres/db

# Nignx folder creation & assigning permission
sudo mkdir -p /opt/docker/nginx/data && sudo chown -R 200 /opt/docker/nginx/data
sudo mkdir -p /opt/docker/nginx/letsencrypt && sudo chown -R 200 /opt/docker/nginx/letsencrypt

# Vautlwarden folder creation & assigning permission
sudo mkdir -p /opt/docker/vaultwarden && sudo chown -R 200 /opt/docker/vaultwarden

# Grafana folder creation & assigning permission
sudo mkdir -p /opt/docker/grafana/data-plugins && sudo chown -R 200 /opt/docker/grafana/data-plugins
sudo mkdir -p /opt/docker/grafana/provisioning && sudo chown -R 200 /opt/docker/grafana/provisioning
sudo mkdir -p /opt/docker/grafana/datasources && sudo chown -R 200 /opt/docker/grafana/datasources

# Prometheus folder creation & assigning permission
sudo mkdir -p /opt/docker/prometheus/config && sudo chown -R 200 /opt/docker/prometheus/config
sudo mkdir -p /opt/docker/prometheus/data && sudo chown -R 200 /opt/docker/prometheus/data

# Alertmanager folder creation & assigning permission
sudo mkdir -p /opt/docker/alertmanager && sudo chown -R 200 /opt/docker/alertmanager

# MySQL-Expoter folder creation & assigning permission
sudo mkdir -p /opt/docker/mysql-exporter && sudo chown -R 200 /opt/docker/mysql-exporter

# Copy all the config & setup files to respective folders
sudo cp ./mysql-server-init-setup.sql /opt/docker/mysql/mysql820/init/init-setup.sql
sudo cp ./mysql-server-zipkin.sql /opt/docker/mysql/mysql820/init/zipkin.sql
sudo cp ./prometheus-server-prometheus.yml /opt/docker/prometheus/config/prometheus.yml
sudo cp ./grafana-server-datasource.yml /opt/docker/grafana/datasources/datasource.yml
sudo cp ./alertmanager-configuration.yml /opt/docker/alertmanager/config.yml
sudo cp ./prometheus-alert.rules /opt/docker/prometheus/config/alert.rules
sudo cp ./mysql-exporter-my.cnf /opt/docker/mysql-exporter/.my.cnf

docker compose up -d
