#!/bin/sh

PROJECT_NAME=PageLayoutComparison
DEVHUB_NAME="${PROJECT_NAME}DevHub"
PERMSET_NAME="Page_Layout_Comparison"

echo ""
echo "Building your scratch org, please wait..."
echo ""
sf org create scratch -v ${DEVHUB_NAME} -f config/project-scratch-def.json -d -a ${PROJECT_NAME} --duration-days 21
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
sf project deploy start
echo ""
if [ "$?" = "1" ]
then
	echo "ERROR: Pushing source to the scratch org failed!"
	exit
fi
echo "SUCCESS: Source pushed successfully to the scratch org!"

echo ""
echo "Assigning project permission sets to the default scratch org user..."
echo ""
sf org assign permset -n ${PERMSET_NAME}
if [ "$?" = "1" ]
then
	echo "ERROR: Assigning a project permission set to the default scratch org user failed!"
	exit
fi
echo "SUCCESS: Project permission sets assigned successfully to the default scratch org user!"

sf project reset tracking -p

echo ""
echo "Opening scratch org for development, may the Flow be with you!"
echo ""
sleep 3
sf org open
