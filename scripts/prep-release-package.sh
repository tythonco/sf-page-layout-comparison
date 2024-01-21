#!/bin/bash -l

# This script will create a PROMOTED package version for tentative release.
# Only released package versions can be listed on AppExchange and installed in customer orgs.
# Prior to running the script, it is expected that the package has been fully-tested (incl. unit tests and adequate code coverage) and is release-ready.

PROJECT_NAME=PageLayoutComparison
DEVHUB_NAME="${PROJECT_NAME}DevHub"

set -e

if ! grep "\"${PROJECT_NAME}\"," sfdx-project.json; then
    echo 'Specified package does not exist! Double check the package name. Exiting ... '
    exit
fi

# Check if this is a new version release
# TODO: redo version check flow to directly modify version info based on prompt instead of requiring manual modifcation before running script
echo "Package versions with same MAJOR.MINOR.PATCH can only be released once!"
read -p "Is this a new version release and have you updated version information in the package configuration file? y/n: " NEW_VER

if [[ "${NEW_VER}" != 'y' ]] ; then
    echo "Ensure you have updated the version number in the package configuration file (sfdx-project.json) then rerun this script."
    exit
fi

# Create a new package version for promotion
echo "Create package version for promotion..."
sf package version create -v "${DEVHUB_NAME}" -p "${PROJECT_NAME}" -x -c -w 15

if [ "$?" = "1" ]; then
	echo "" && echo "ERROR: Problem creating release-ready package version! Ensure passing unit tests and code coverage! Exiting ..."
    exit 1
fi

PKG_VER_ID=$(grep "${PROJECT_NAME}" sfdx-project.json | tail -1 | sed -E 's/^.*"(04t[[:alnum:]]*)"$/\1/')

# Promote package
echo "Promote package ${PROJECT_NAME} for release ..."
sf package version promote -v "${DEVHUB_NAME}" -p "${PKG_VER_ID}" -n
echo "Package version has been promoted!"

# TODO: Specify a specific pre-release (non-scratch) org for testing?
# Generate a fresh test scratch org to install the package
# Ensure namespace is NOT applied to this org since this is to simulate a customer install
echo "Install promoted package to temporary scratch org for final testing ... "
if sf org list | grep "${PROJECT_NAME}PackageTestOrg"; then
    echo "Deleting pre-existing test scratch org ..."
    sf org delete scratch -o "${PROJECT_NAME}PackageTestOrg" -p
fi
sf org create scratch -v "${DEVHUB_NAME}" --no-namespace -f config/project-scratch-def.json -a "${PROJECT_NAME}PackageTestOrg"
echo "Test scratch org created."

echo "Preparing to test install PROMOTED package ${PROJECT_NAME} ... "
sf package install -p "${PKG_VER_ID}" -o "${PROJECT_NAME}PackageTestOrg" --no-prompt -w 15

if [ "$?" = "1" ]
then
	echo "" && echo "ERROR: Problem installing test package!"
	exit
else
    echo "Package install successful!"
fi

unset PKG_VER_ID

echo ""
echo "Opening scratch org for final testing before official release!"
echo ""
sleep 3
sf org open -o "${PROJECT_NAME}PackageTestOrg"

exit
