#!/bin/bash

CUR_USER="$(whoami)"

PS3="Choose action: "

select lng in "Start site" "Stop Site" "Create Site" "Delete Site & Files" "Restart Site" "Fix permissions" "Add SSH key" "Quit"
do
    case $lng in
        "Start site")
          echo -e "\e[36mStarting site...\e[0m"
          read -r -p "Enter site name or abbreviation (no spaces): " sitename
           docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" up -d
          break;;
        "Stop Site")
          echo -e "\e[36mStopping site...\e[0m"
          read -r -p "Enter site name or abbreviation (no spaces): " sitename
          docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" stop
          break;;
        "Restart Site")
          echo -e "\e[36mRestarting site...\e[0m"
          read -r -p "Enter site name or abbreviation (no spaces): " sitename
          docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" restart
          break;;
        "Create Site")
          echo -e "\e[36mCreating site...\e[0m"
          curl -s https://raw.githubusercontent.com/BOOST-Creative/docker-server-setup/main/newsite.sh > ~/.newsite.sh && chmod +x ~/.newsite.sh && ~/.newsite.sh
          break;;
        "Delete Site & Files")
          echo -e "\e[36mDeleting site (seriously, this will completely delete everything)...\e[0m"
          read -r -p "Enter site name or abbreviation (no spaces) TO COMPLETELY DELETE: " sitename
          docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" stop
          docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" rm
          sudo rm -rf "/home/$CUR_USER/sites/$sitename"
          break;;
        "Fix permissions")
          echo -e "\e[36mFixing permissions...\e[0m"
          read -r -p "Enter site name or abbreviation (no spaces): " sitename
          sudo chown -R nobody: "/home/$CUR_USER/sites/$sitename/wordpress"
          echo -e "\e[32mPermissions updated 👍\e[0m"
          break;;
        "Add SSH key")
          read -r -p "Please paste your public SSH key: " sshkey
          echo "$sshkey" >> /home/"$CUR_USER"/.ssh/authorized_keys
          echo -e "\e[32mSSH key added 👍\e[0m"
          break;;
        "Quit")
          echo "Goodbye :)"
          break;;
        *)
          echo "huh?";;
    esac
  rm ./.boost.sh
done