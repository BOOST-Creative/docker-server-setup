#! /bin/bash

# exports individual databases from mariadb for backup

excluded_dbs=(mysql sys performance_schema information_schema)

mkdir -p "/home/USERNAME/server/backups/mariadb"
docker exec mariadb sh -c 'mysql -N -uroot -p"$MYSQL_ROOT_PASSWORD" -e "show databases"' | while read -r dbname; do
  match=0
  for excluded_db in "${excluded_dbs[@]}"; do
    if [[ $excluded_db = "$dbname" ]]; then
      match=1
      break
    fi
  done
  if [[ $match = 0 ]]; then
    docker exec -e dbname="$dbname" mariadb sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" "${dbname}"' > "/home/USERNAME/server/backups/mariadb/$dbname.sql";
  fi
done

# entire db example
# docker exec mariadb sh -c 'mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > ~/home/USERNAME/server/backups/mariadb.sql