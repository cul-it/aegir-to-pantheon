#!/bin/bash
# aegir-site-export.sh - backup aegir site as if it was not multi-site

TARGET_SITE="$1"
TARGET_SITE_ALIAS="@${TARGET_SITE}"

# An error exit function
function error_exit
{
  echo "**************************************"
  echo "$1" 1>&2
  echo "**************************************"
  exit 1
}

function useage
{
  echo "Usage: $0 <target site>"
  error_exit "Please try again..."
}

# check argument count
if [ $# -ne 1 ]; then
    useage
fi

# find the path to the site and the multi-site directories
SITEROOT=`sudo -u aegir drush sa "$TARGET_SITE_ALIAS" | grep root | cut -f4 -d\'`
MULTISITEROOT=`sudo -u aegir drush sa "$TARGET_SITE_ALIAS" | grep site_path | cut -f4 -d\'`
echo "$SITEROOT"
echo "$MULTISITEROOT"

# create a temporary directory target for backup
TEMP="/tmp/aegir-site-export"
TEMPDIR="${TEMP}/${TARGET_SITE}"
EXPORTDIR="${TEMPDIR}/export"
mkdir -p "$EXPORTDIR"
sudo chown -R aegir:lib_web_dev_role "$TEMP"
sudo chmod -R ug+rw "$TEMP"

# backup the site database
sudo -u aegir drush "$TARGET_SITE_ALIAS" sql-dump --result-file="${EXPORTDIR}/database.sql"
