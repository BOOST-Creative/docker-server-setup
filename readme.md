## BOOST setup script for Debian / Ubuntu servers

Run as root on a fresh installation. This is a specific setup for our org. If you want a neutral setup, check **todo add repo**.

```bash
curl -s https://raw.githubusercontent.com/BOOST-Creative/docker-server-setup/main/setup.sh > setup.sh && chmod +x ./setup.sh && ./setup.sh
```

### Hardens and configures system

- Creates non-root user with sudo and docker privileges.

- Updates packages and optionally enables unattended-upgrades.

- Changes SSH port and disables password login.

- Configures firewall to block ingress except on ports 80, 443, and your chosen SSH port.

- fail2ban working out of the box to block malicious bot traffic to public web applications.

- Ensures the server is set to your preferred time zone.

- Installs **[kopia](https://github.com/kopia/kopia)** for backups. Check [here](https://ftlwebservices.com/fast-and-reliable-automated-cloud-backups-with-kopia-and-backblaze/) for instructions.

- Adds aliases like `dcu` / `dcd` / `dcr` for docker compose up / down / restart.

### Installs docker, docker compose, and selected services

Besides Nginx Proxy Manager, all services are tunneled through SSH and not publicly accessible. The following are installed by default:

- **[Portainer](https://github.com/portainer/portainer)** and **[ctop](https://github.com/bcicen/ctop)** for easy container management with GUI and terminal.

- **[Nginx Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager)** for publicly exposing your services with automatic SSL.

- **[MariaDB database](https://hub.docker.com/r/linuxserver/mariadb)** used by Nginx Proxy Manager and any other apps you want.

- **[phpMyAdmin](https://hub.docker.com/r/linuxserver/phpmyadmin)** for graphical administration of the MariaDB database.

- **[File Browser](https://github.com/filebrowser/filebrowser)** for graphical file management.

- **[fail2ban](https://github.com/crazy-max/docker-fail2ban)** configured to read Nginx Proxy Manager logs and block malicious IPs in iptables.

- **[Watchtower](https://github.com/containrrr/watchtower)** to automatically update running containers to the latest image version.

These are defined and can be disabled in `~/server/docker-compose.yml`.

### Notes

To create / start / stop / fix permissions for wordpress sites, run the command `boost`.

Debian / Ubuntu derivatives like Raspbian should work but haven't been tested.

There is a docker network with the same name as your username. If you create new containers in that that network, you can use the container name as a hostname in Nginx Proxy Manager.

If you need to open a port for Wireguard or another service, [allow the port in iptables](https://www.digitalocean.com/community/tutorials/iptables-essentials-common-firewall-rules-and-commands) and run `sudo netfilter-persistent save` to save rules.

To export the MariaDB database to disk for backup, you can use the command below in a cron job (you may want to change the output directory).

```bash
docker exec mariadb sh -c \ 'mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > ~/mariadb.sql
```

If you want to monitor uptime, check out **[Uptime Kuma](https://github.com/louislam/uptime-kuma)**, but you should run this from a different machine.

The fail2ban container is restarted once each day via cron to pick up log files from new proxy hosts. You can manually restart the container if you need it to work with new services immediately.

Additional fail2ban rules may be added to the container in `~/server/fail2ban`. Use the FORWARD chain (not INPUT or DOCKER-USER) and make sure the filter regex is using the NPM log format - `[Client <HOST>]`.

### Using with Cloudflare

info about how use cloudflare action to ban ip instead of iptables

### TODO

- set up kopia and create first snapshots of sites and mariadb in setup?
