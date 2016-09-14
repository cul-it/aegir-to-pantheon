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
SITEROOT=`drush sa "$TARGET_SITE_ALIAS" | grep root | cut -f4 -d\'`

PRIVATEFILESPATH="/libweb/sites/${TARGET_SITE}/drupal_files/"

# create a temporary directory target for backup
TEMP="/tmp/victoria-site-export"
TEMPDIR="${TEMP}/${TARGET_SITE}"
EXPORTDIRNAME="export"
EXPORTDIR="${TEMPDIR}/${EXPORTDIRNAME}"
if [ -d "$EXPORTDIR" ]; then
  error_exit "Directory $EXPORTDIR already exists! Please remove it first."
fi

mkdir -p "$EXPORTDIR" || error_exit "Can't create $EXPORTDIR"
mkdir -p "${EXPORTDIR}/code"
mkdir -p "${EXPORTDIR}/files/private"
sudo chgrp -R lib_web_dev_role "$TEMP"
sudo chmod -R ug+rw "$TEMP"

# clear site caches
echo 'Clearing site cache...'
drush "$TARGET_SITE_ALIAS" cache-clear all

# make a drush archive dump of the site, including private files path
ARDFILE="${EXPORTDIR}/archive.tar"
drush "$TARGET_SITE_ALIAS" archive-dump --tar-options="-r ${PRIVATEFILESPATH}" --destination="${ARDFILE}" || error_exit "Problem making drush archive."

# if the archive dump is < 500mb we can use it
FILESIZE=`stat --printf='$s' "${ARDFILE}"`
if test  "$FILESIZE" -lt 524288000
  then
  echo "Archive < 500 Mb so you can upload it directly. Path to drush archive file:"
  echo "${ARDFILE}"
  exit 0
fi

# backup the site database
echo 'Backing up database...'
DATABASE="${EXPORTDIR}/database.sql"
drush "$TARGET_SITE_ALIAS" sql-dump --ordered-dump --result-file="${DATABASE}"

# copy the modules, themes, libraries
echo 'Copying the code: modules, themes, libraries...'
rsync -azq --exclude /drush "${SITEROOT}/sites/all/" "${EXPORTDIR}/code" || error_exit "Problem copying code."

# copy the assets - files, private files
echo 'Copying the assets: files, private files...'
rsync -azq --exclude .htaccess "${SITEROOT}/sites/default/files" "${EXPORTDIR}/" || error_exit "Problem moving files."
rsync -azq --exclude .htaccess "/libweb/sites/${TARGET_SITE}/drupal_files/" "${EXPORTDIR}/files/private/" || error_exit "Problem moving private files."

# compress the files directory
echo "Compressing files..."
cd "$EXPORTDIR"
tar -zcf files.tar.gz files || error_exit "Problem with tar of files."
rm -rf files || error_exit "Can't remove files directory."

# compress the exported data
ARCHIVEFILE="${EXPORTDIRNAME}.tar.gz"
ARCHIVEPATH="${TEMPDIR}/${ARCHIVEFILE}"
echo 'Compressing the whole export...'
cd "$TEMPDIR"
tar -zcf "${ARCHIVEFILE}" "${EXPORTDIRNAME}" || error_exit "Problem with tar."
rm -rf "${EXPORTDIR}" || error_exit "Can't remove ${EXPORTDIR}."
echo "Export is stored here:"
echo "$ARCHIVEPATH"


