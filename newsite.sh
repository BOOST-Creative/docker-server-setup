#! /bin/bash

CUR_USER="$(whoami)"

read -r -p "Enter site name or abbreviation (lowercase, no spaces): " sitename

if [ -d "/home/$CUR_USER/sites/$sitename" ]
then
  echo -e "\e[31mFolder exists. Exiting..."
  exit;
fi

mkdir -p "/home/$CUR_USER/sites/$sitename/wordpress"
curl -s https://raw.githubusercontent.com/BOOST-Creative/docker-server-setup/main/wordpress/docker-compose.yml > "/home/$CUR_USER/sites/$sitename/docker-compose.yml"
curl -s https://raw.githubusercontent.com/BOOST-Creative/docker-server-setup/main/wordpress/.htninja > "/home/$CUR_USER/sites/$sitename/.htninja"
# chown nobody: /home/$CUR_USER/sites/$sitename/.htninja

read -r -p 'Type "YES" if this site requires PHP 7: ' oldphp

if [ "$oldphp" == "YES" ]
then
  echo "Using PHP 7..."
  sed -i "s/docker-wordpress-8/docker-wordpress-7/" "/home/$CUR_USER/sites/$sitename/docker-compose.yml"
fi

# replace yml with site name
sed -i "s/CHANGE_TO_SITE_NAME/$sitename/" "/home/$CUR_USER/sites/$sitename/docker-compose.yml"
sed -i "s/CHANGE_TO_USERNAME/$CUR_USER/" "/home/$CUR_USER/sites/$sitename/docker-compose.yml"

echo -e "\n\e[32mSite created at /home/$CUR_USER/sites/$sitename/wordpress\e[0m\n"

read -r -p "Create database now (y/n)? "
if [[ $REPLY =~ ^[Yy]$ ]]
then
  BOOST_DB="${sitename//-/_}"
  BOOST_DB_USER="u_${sitename//-/_}"
  BOOST_DB_PASS=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | head -c"${1:-16}")
  docker exec -e BOOST_DB="$BOOST_DB" -e BOOST_DB_USER="$BOOST_DB_USER" -e BOOST_DB_PASS="$BOOST_DB_PASS" mariadb /bin/bash -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $BOOST_DB; CREATE USER '\''$BOOST_DB_USER'\''; SET PASSWORD FOR '\''$BOOST_DB_USER'\'' = PASSWORD('\''$BOOST_DB_PASS'\''); GRANT ALL PRIVILEGES ON $BOOST_DB.* TO '\''$BOOST_DB_USER'\''; FLUSH PRIVILEGES;"'
  echo -e "\n\e[36mDatabase:\e[0m $BOOST_DB"
  echo -e "\e[36mUser:\e[0m $BOOST_DB_USER"
  echo -e "\e[36mPassword:\e[0m $BOOST_DB_PASS"
  echo -e "\e[36mHost:\e[0m mariadb\n"
fi


read -r -p "Start site now and create a fresh wp installation (y/n)? "
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" create
  echo -e "\n\e[36mChanging owner of site directory...\e[0m"
  # fix permissions for wordpress directory
  sudo chown nobody: "/home/$CUR_USER/sites/$sitename/wordpress"
  echo "Upload your files and start the site later. Goodbye :)"
  rm ~/.newsite.sh
  exit;
fi

# start site
docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" up -d

rm ~/.newsite.sh