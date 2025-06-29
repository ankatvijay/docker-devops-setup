-- creating databases
CREATE DATABASE IF NOT EXISTS vaultwarden;
CREATE DATABASE IF NOT EXISTS nginxproxymanager;
CREATE DATABASE IF NOT EXISTS grafana;
CREATE DATABASE IF NOT EXISTS zipkin;

-- creating new user ankat
CREATE USER 'ankat'@'%' IDENTIFIED WITH caching_sha2_password BY 'ankatpass' PASSWORD EXPIRE NEVER;
CREATE USER 'npm'@'%' IDENTIFIED WITH mysql_native_password BY 'ankatpass' PASSWORD EXPIRE NEVER;

GRANT ALL ON *.* TO 'ankat'@'%';
GRANT ALL ON *.* TO 'npm'@'%';
FLUSH PRIVILEGES;
