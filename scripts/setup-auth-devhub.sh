#!/bin/sh

# Set project name here or follow the cmd line prompt when running script.
PROJECT_NAME=PageLayoutComparison

if [ -z "$PROJECT_NAME" ]
then
      echo ""
      read -p "Enter project name " PROJECT_NAME
      echo ""
else
      echo "Project name is set as: ${PROJECT_NAME}" && echo ""
fi

DEVHUB_NAME="${PROJECT_NAME}DevHub"

echo "Authenticating to DevHub org..."
sf org login web -d -a ${DEVHUB_NAME} -r https://login.salesforce.com

if [ "$?" = "1" ]
then
	echo "" && echo "ERROR: Authorizization with the ${DEVHUB_NAME} org failed!"
	exit
else
    echo "" && echo "SUCCESS: Authenticated to project DevHub org!" && echo ""
fi
