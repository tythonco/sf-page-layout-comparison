#!/bin/sh

PROJECT_NAME=PageLayoutComparison
DEVHUB_NAME="${PROJECT_NAME}DevHub"

echo ""
echo "Building your scratch org, please wait..."
echo ""
sfdx force:org:create -v ${DEVHUB_NAME} -f config/project-scratch-def.json -s -a ${PROJECT_NAME} -d 21 --json
echo ""
if [ "$?" = "1" ]
then
	echo "ERROR: Can't create your org!"
	exit
fi
echo "SUCCESS: Scratch org created!"

echo ""
echo "Pushing source to the scratch org! This may take a while! So now might be a good time to stretch your legs and/or grab your productivity beverage of choice..."
echo ""
sfdx force:source:push --json
echo ""
if [ "$?" = "1" ]
then
	echo "ERROR: Pushing source to the scratch org failed!"
	exit
fi
echo "SUCCESS: Source pushed successfully to the scratch org!"

sfdx force:source:tracking:reset -p

echo ""
echo "Opening scratch org for development, may the Flow be with you!"
echo ""
sleep 3
sfdx force:org:open
