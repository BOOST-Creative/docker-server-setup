#! /bin/bash

CUR_USER="$(whoami)"

read -p "Enter site name or abbreviation (no spaces): " sitename

if [ -d "/home/$CUR_USER/sites/$sitename" ]
then
  echo -e "\e[31mFolder exists. Exiting..."
  exit;
fi

mkdir -p "/home/$CUR_USER/sites/$sitename/wordpress"
curl -s https://raw.githubusercontent.com/BOOST-Creative/docker-server-setup/main/wordpress/docker-compose.yml > "/home/$CUR_USER/sites/$sitename/docker-compose.yml"
curl -s https://raw.githubusercontent.com/BOOST-Creative/docker-server-setup/main/wordpress/.htninja > "/home/$CUR_USER/sites/$sitename/.htninja"
# chown nobody: /home/$CUR_USER/sites/$sitename/.htninja

read -p 'Type "PHP7" if this site requires PHP 7: ' oldphp

if [ $oldphp == "PHP7" ]
then
  echo "Using PHP 7..."
  sed -i "s/docker-wordpress-8/docker-wordpress-7/" "/home/$CUR_USER/sites/$sitename/docker-compose.yml"
fi

# replace yml with site name
sed -i "s/CHANGE_TO_SITE_NAME/$sitename/" "/home/$CUR_USER/sites/$sitename/docker-compose.yml"
sed -i "s/CHANGE_TO_USERNAME/$CUR_USER/" "/home/$CUR_USER/sites/$sitename/docker-compose.yml"

echo -e "\e[32mSite created at /home/$CUR_USER/sites/$sitename/wordpress\e[0m"

read -p "Start site now and create a fresh wp installation (y/n)? " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" create
  echo "Upload your files and start the site later. Goodbye :)"
  rm ~/.newsite.sh
  exit;
fi

# start site
docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" up -d
rm ~/.newsite.sh