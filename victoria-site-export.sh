#!/bin/bash
# victoria-site-export.sh - backup victoriaNN site for Pantheon

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

# create a temporary directory target for backup
TEMP="/tmp/victoria-site-export"
TEMPDIR="${TEMP}/${TARGET_SITE}"
EXPORTDIRNAME="export"
EXPORTDIR="${TEMPDIR}/${EXPORTDIRNAME}"
if [ -d "$EXPORTDIR" ]; then
  error_exit "Directory $EXPORTDIR already exists! Please remove it first."
fi

mkdir -p "$EXPORTDIR" || error_exit "Can't create $EXPORTDIR"
sudo chgrp -R lib_web_dev_role "$TEMP"
sudo chmod -R ug+rw "$TEMP"

# clear site caches
echo 'Clearing site cache...'
drush "$TARGET_SITE_ALIAS" cache-clear all


# backup the site database
echo 'Backing up database...'
DATABASE="${EXPORTDIR}/database.sql"
drush "$TARGET_SITE_ALIAS" sql-dump --ordered-dump --result-file="${DATABASE}"

# copy the modules, themes, libraries
echo 'Copying the code: modules, themes, libraries...'
rsync -azq --exclude /drush "${SITEROOT}/sites/all/" "${EXPORTDIR}/code" || error_exit "Problem copying code."

# copy the assets - files, private/files
echo 'Copying the assets: files, private/files...'
rsync -azq --exclude .htaccess "${SITEROOT}/sites/default/files" "${EXPORTDIR}/assets/" || error_exit "Problem moving files."
rsync -azq --exclude .htaccess "/libweb/sites/${TARGET_SITE}/drupal_files/" "${EXPORTDIR}/assets/private/files/" || error_exit "Problem moving private files."

# compress the exported data
ARCHIVEFILE="${EXPORTDIRNAME}.tar.gz"
ARCHIVEPATH="${TEMPDIR}/${ARCHIVEFILE}"
echo 'Compressing the whole export...'
cd "$TEMPDIR"
tar -zcf "${ARCHIVEFILE}" "${EXPORTDIRNAME}" || error_exit "Problem with tar."
rm -rf "${EXPORTDIR}" || error_exit "Can't remove ${EXPORTDIR}."
echo "Export is stored here:"
echo "$ARCHIVEPATH"

