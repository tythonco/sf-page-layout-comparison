#!/bin/bash -l

# This script attempts to install a freshly created package version into a temporary test scratch org.
# Requires that a Package version ID was successfully generated in prior step.

PROJECT_NAME=PageLayoutComparison
DEVHUB_NAME="${PROJECT_NAME}DevHub"

set -e

TEST_ORG="${PROJECT_NAME}PackageTestOrg"


if [ -z "$PACKAGE_VER_ID" ]; then
    PACKAGE_VER_ID=$(grep "${PROJECT_NAME}" sfdx-project.json | tail -1 | sed -E 's/^.*"(04t[[:alnum:]]*)"$/\1/')
fi

echo "Install package to temporary scratch org for testing with version ID: ${PACKAGE_VER_ID} ... "

# Check if "PackageTestOrg" already exists, delete if it does
if sf org list | grep "$TEST_ORG"; then
    echo "Pre-existing test scratch org detected! Deleting ..."
    sf org delete scratch -o "$TEST_ORG" -p
fi

# Generate a fresh scratch org to install & test the package
# Ensure namespace is NOT applied to this org since this is to simulate a customer install
sf org create scratch -v "${DEVHUB_NAME}" --no-namespace -f config/project-scratch-def.json -a "$TEST_ORG"

# Install the package
sf package install -p "$PACKAGE_VER_ID" -o "$TEST_ORG" --no-prompt -w 15

unset PACKAGE_VER_ID

echo ""
echo "Opening scratch org for testing, may the Flow be with you!"
echo ""
sleep 3
sf org open -o "$TEST_ORG"

exit
