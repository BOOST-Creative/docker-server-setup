#! /bin/bash

# exit on error
set -e

# clear screen
clear

# variables
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
ENDCOLOR="\e[0m"
REPO="BOOST-Creative/docker-server-setup"
CUR_TIMEZONE=$(timedatectl show | grep zone | sed 's/Timezone=//g');
MARIA_DB_ROOT_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-20})
NPM_DB_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c${1:-20})

# intro message
echo -e "${GREEN}Welcome! This script should be run as the root user on a new Debian or Ubuntu server.${ENDCOLOR}\n"

# change timezone (works on debian / ubuntu / fedora)
read -p "$(echo -e "The system time zone is ${YELLOW}$CUR_TIMEZONE${ENDCOLOR}. Do you want to change it (y/n)?${ENDCOLOR} ")" yn
if [[ $yn =~ ^[Yy]$ ]]
then
  read -p "Enter time zone: " new_timezone
  timedatectl set-timezone $new_timezone
  echo -e "${GREEN}Time zone has changed to: $new_timezone ${ENDCOLOR}"
fi

# create user account (works on debian / ubuntu / fedora)
read -p "$(echo -e "\nEnter username for the user to be created: ")" username
while [[ ! $username =~ ^[a-z][-a-z0-9]*$ ]]; do
  read -p "Invalid format. Enter username for the user to be created: " username
done
useradd -m -s /bin/bash $username
passwd $username
usermod -aG sudo $username || usermod -aG wheel $username

echo ""

# SSH port prompt
read -p "Which port do you want to use for SSH (not 6900-6903 please)? " ssh_port
while (( ssh_port < 1000 || ssh_port > 65000)); do
  read -p "Please use a number between 1000 and 65000: " ssh_port
done

# add ssh key
mkdir -p /home/$username/.ssh
# check if root has authorized_keys already
if [ -s /root/.ssh/authorized_keys ]
then
  cp /root/.ssh/authorized_keys /home/$username/.ssh/authorized_keys
else
  # if no keys, ask for key instead
  read -p "Please paste your public SSH key: " sshkey
  echo $sshkey >> /home/$username/.ssh/authorized_keys
fi
# fix permissions
chown -R $username: /home/$username/.ssh

# add / update packages
echo -e "${CYAN}Updating system & packages...${ENDCOLOR}"


# install docker
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh

# update system - apt update runs in docker script
apt upgrade -y
apt install git unattended-upgrades -y

# unattended-upgrades
echo -e "${CYAN}Setting up unattended-upgrades...${ENDCOLOR}"
dpkg-reconfigure --priority=low unattended-upgrades

# docker stuff
echo -e "${CYAN}Setting up docker containers...${ENDCOLOR}"

# clone repo and copy files
rm -r /tmp/docker-server ||:
git clone --depth=1 "https://github.com/$REPO.git" /tmp/docker-server
mkdir -p /home/$username/server/fail2ban /home/$username/sites
cp -r /tmp/docker-server/fail2ban /home/$username/server/fail2ban/data
cp /tmp/docker-server/docker-compose.yml /home/$username/server/docker-compose.yml
cp /tmp/docker-server/firewall.sh /home/$username/firewall.sh
sed -i "s/REPLACE_ME/$ssh_port/" "/home/$username/firewall.sh"

# create docker networks
docker network create $username
docker network create database

# replace docker compose file with user input, and start
sed -i "s/CHANGE_TO_USERNAME/$username/" "/home/$username/server/docker-compose.yml"
sed -i "s/MARIA_DB_ROOT_PASSWORD/$MARIA_DB_ROOT_PASSWORD/" "/home/$username/server/docker-compose.yml"
sed -i "s/NPM_DB_PASSWORD/$NPM_DB_PASSWORD/" "/home/$username/server/docker-compose.yml"
sed -i "s/USER_UID/$(id -u $username)/" "/home/$username/server/docker-compose.yml"
sed -i "s/USER_GID/$(id -g $username)/" "/home/$username/server/docker-compose.yml"
sed -i "s|USER_TIMEZONE|$(timedatectl show | grep zone | sed 's/Timezone=//g')|" "/home/$username/server/docker-compose.yml"
docker compose -f /home/$username/server/docker-compose.yml up -d

# dummy logs so fail2ban doesn't shut down
mkdir -p /home/$username/server/npm/data/logs
touch /home/$username/server/npm/data/logs/proxy-host-{1..9}_access.log

# add custom http nginx config
# mkdir -p /home/$username/server/npm/data/nginx/custom
# cp /tmp/docker-server/nginx/http.conf /home/$username/server/npm/data/nginx/custom/http.conf

# fix permissions
chown $username: /home/$username/sites /home/$username/server/docker-compose.yml /home/$username/firewall.sh
# nobody user bc that's what wp container uses
chown -R nobody:nogroup /home/$username/server/filebrowser

# add user to docker users
usermod -aG docker $username

# add cron job to restart fail2ban each morning at 3:42
touch /var/spool/cron/crontabs/$username
echo "42 3 * * * docker restart fail2ban" >> /var/spool/cron/crontabs/$username

# update SSH config
echo -e "\n${CYAN}Updating SSH config...${ENDCOLOR}"
echo "Port $ssh_port" >> /etc/ssh/sshd_config
echo "PermitRootLogin prohibit-password" >> /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "X11Forwarding no" >> /etc/ssh/sshd_config

echo -e "${CYAN}Restarting SSH daemon...${ENDCOLOR}\n"
systemctl restart sshd

# verify ssh key is correct
cat /home/$username/.ssh/authorized_keys
read -p "$(echo -e "\nIs the above SSH key(s) correct (y/n)? ")" ssh_correct
while [[ ! $ssh_correct =~ ^[Yy]$ ]]; do
  read -p "Please paste your public SSH key: " sshkey
  echo $sshkey >> /home/$username/.ssh/authorized_keys
  cat /home/$username/.ssh/authorized_keys
  read -p "$(echo -e "\nIs the above SSH key(s) correct (y/n)? ")" ssh_correct
done

# aliases / .bashrc stuff
echo 'alias dcu="docker compose up -d"' >> /home/$username/.bashrc
echo 'alias dcd="docker compose down"' >> /home/$username/.bashrc
echo 'alias dcr="docker compose restart"' >> /home/$username/.bashrc
echo 'alias boost="curl -s https://raw.githubusercontent.com/BOOST-Creative/docker-server-setup/main/boost.sh > ~/.boost.sh && chmod +x ~/.boost.sh && ~/.boost.sh"' >> /home/boost/.bashrc
echo 'alias ctop="docker run --rm -ti --name=ctop --volume /var/run/docker.sock:/var/run/docker.sock:ro quay.io/vektorlab/ctop:latest"' >> /home/$username/.bashrc
echo 'echo -e "\nPortainer: \e[34mhttp://localhost:6900\n\e[0mNginx Proxy Manager: \e[34mhttp://localhost:6901\n\e[0mphpMyAdmin: \e[34mhttp://localhost:6902\n\e[0mFileBrowser: \e[34mhttp://localhost:6903\e[0m\n\nRun ctop to manage containers and view metrics.\n"' >> /home/$username/.bashrc
echo 'type ~/firewall.sh &>/dev/null && ./firewall.sh' >> /home/$username/.bashrc

# Success Message
echo -e "\n${GREEN}Setup complete 👍. Please log back in as $username on port $ssh_port.${ENDCOLOR}"
echo -e "${GREEN}Firewall script will run on first login.${ENDCOLOR}"
echo -e "${GREEN}Update your SSH config file with the info below${ENDCOLOR}"

echo -e "\n\033[1m🚨\e[31m ENABLE HETZNER FIREWALL NOW 🚨${ENDCOLOR}\n"

echo "Host changeme"
echo "    HostName $(curl -s ifconfig.me)"
echo "    Port $ssh_port"
echo "    User $username"
echo "    LocalForward 6900 127.0.0.1:6900"
echo "    LocalForward 6901 127.0.0.1:6901"
echo "    LocalForward 6902 127.0.0.1:6902"
echo "    LocalForward 6903 127.0.0.1:6903"
echo "    ServerAliveInterval 60"
echo -e "    ServerAliveCountMax 10\n"

# clean up script
rm ./setup.sh