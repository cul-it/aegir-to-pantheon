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
EXPORTDIR="${TEMPDIR}"
if [ -d "$EXPORTDIR" ]; then
  error_exit "Directory $EXPORTDIR already exists! Please remove it first."
fi

mkdir -p "$EXPORTDIR" || error_exit "Can't create $EXPORTDIR"
sudo chgrp -R lib_web_dev_role "$TEMP"
sudo chmod -R ug+rw "$TEMP"

# clear site caches
echo 'Clearing site cache...'
drush "$TARGET_SITE_ALIAS" cache-clear all

# make symlink to private files in files directory (temporarily)
echo "Linking in private files..."
FILESDIR="${SITEROOT}/sites/default/files"
PRIVATEDIRSYMLINK="${FILESDIR}/private"
if [ -d "$PRIVATEDIRSYMLINK" ]; then
  error_exit "Private files directory already exists! $PRIVATEDIRSYMLINK"
fi
cd "$FILESDIR"
ln -s "$PRIVATEFILESPATH" "private" || error_exit "Can not make symlink to private files"

# make a drush archive dump of the site, including private files via the symlink
echo "Making site archive..."
ARDFILE="${EXPORTDIR}/archive.tar.gz"
drush "$TARGET_SITE_ALIAS" archive-dump --destination="${ARDFILE}" || error_exit "Problem making drush archive."

# delete the temporary symlink
echo "Unlinking private files..."
rm "$PRIVATEDIRSYMLINK" || error_exit "Can not remove temporary symlink $PRIVATEDIRSYMLINK"

# if the archive dump is < 500mb we can use it
FILESIZE=`stat --printf='%s' "${ARDFILE}"`
if test $FILESIZE -ge "524288000"
  then
  echo "Warning: Archive > 500 Mb - you will need to upload it to Pantheon using the 'Manual Method'"
fi

# upload to amazon s3
echo "Uploade archive to Amazon S3"
BUCKET="pantheon-imports"
cd "$TEMP"
aws s3 sync "${TARGET_SITE}" "s3:${BUCKET}" || "Problem with aws sync"

# remove temp archive
echo "Cleaning up temp archive..."
rm -r "$EXPORTDIR"

echo "********************"
echo "Archive stored here:"
echo "https://s3.amazonaws.com/${bucket}/${TARGET_SITE}/archive.tar.gz"
echo "********************"
