#!/bin/bash

CUR_USER="$(whoami)"

PS3="Choose action: "

select lng in "Start site" "Stop Site" "Create site" "Restart Site" "Fix permissions" "Quit"
do
    case $lng in
        "Start site")
          echo -e "\e[36mStarting site...\e[0m"
          read -p "Enter site name or abbreviation (no spaces): " sitename
           docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" up -d
          break;;
        "Stop Site")
          echo -e "\e[36mStopping site...\e[0m"
          read -p "Enter site name or abbreviation (no spaces): " sitename
          docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" stop
          break;;
        "Restart Site")
          echo -e "\e[36mRestarting site...\e[0m"
          read -p "Enter site name or abbreviation (no spaces): " sitename
          docker compose -f "/home/$CUR_USER/sites/$sitename/docker-compose.yml" restart
          break;;
        "Create site")
          echo -e "\e[36mCreating site...\e[0m"
          curl -s https://raw.githubusercontent.com/BOOST-Creative/docker-server-setup/main/newsite.sh > ~/.newsite.sh && chmod +x ~/.newsite.sh && ~/.newsite.sh
          break;;
        "Fix permissions")
          echo -e "\e[36mFixing permissions...\e[0m"
          read -p "Enter site name or abbreviation (no spaces): " sitename
          sudo chown -R nobody: "/home/$CUR_USER/sites/$sitename"
          break;;
        "Quit")
          echo "Goodbye :)"
          break;;
        *)
          echo "huh?";;
    esac
  rm ./.boost.sh
done