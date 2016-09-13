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
if [ -d "$EXPORTDIR" ]; then
  error_exit "Directory $EXPORTDIR already exists! Please remove it first."
fi

mkdir -p "$EXPORTDIR" || error_exit "Can't create $EXPORTDIR"
sudo chown -R aegir:lib_web_dev_role "$TEMP"
sudo chmod -R ug+rw "$TEMP"

# clear site caches
echo 'Clearing site cache...'
sudo -u aegir drush "$TARGET_SITE_ALIAS" cache-clear all

# backup the site database
echo 'Backing up database...'
DATABASE="${EXPORTDIR}/database.sql"
sudo -u aegir drush "$TARGET_SITE_ALIAS" sql-dump --ordered-dump --result-file="${DATABASE}"

# modify the backup database to make it non-multi-site
echo 'Converting multi-site to single site...'
OLDNAME="sites/${TARGET_SITE}"
NEWNAME="sites/default"
echo "sed -i 's#${OLDNAME}#${NEWNAME}#g' ${DUMP_FILE_ABS}"
sed -i -e "s#${OLDNAME}#${NEWNAME}#g" "${DATABASE}" || error_exit "Problem replacing multi-site path."

# copy the modules, themes, libraries
echo 'Copying the code: modules, themes, libraries...'
rsync -avzq "${SITEROOT}/sites/all" "${EXPORTDIR}/code" || error_exit "Problem copying code."

# copy the assets - files, private/files
echo 'Copying the assets: files, private/files'
rsync -avzq "${MULTISITEROOT}/files" "${EXPORTDIR}/assets/" || error_exit "Problem moving files."
rsync -avzq "${MULTISITEROOT}/private" "${EXPORTDIR}/assets/" || error_exit "Problem moving private files."

# compress the exported data
echo 'Compressing the whole export...'
tar -zcvf "${TEMPDIR}/export.tar.gz" "${TEMPDIR}/export"


