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

# create a temporary directory target for backup
TEMP="/tmp/aegir-site-export"
TEMPDIR="${TEMP}/${TARGET_SITE}"
EXPORTDIR="${TEMPDIR}"
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
DATABASE="${EXPORTDIR}/database-default-site.sql"
sudo -u aegir drush "$TARGET_SITE_ALIAS" sql-dump --ordered-dump --result-file="${DATABASE}"

# modify the backup database to make it non-multi-site
echo 'Converting multi-site to single site...'
OLDNAME="sites/${TARGET_SITE}"
NEWNAME="sites/default"
sed -i -e "s#${OLDNAME}#${NEWNAME}#g" "${DATABASE}" || error_exit "Problem replacing multi-site path."
echo 'Converting private files paths...'
OLDNAME="sites/default/private/files"
NEWNAME="sites/default/files/private"
sed -i -e "s#${OLDNAME}#${NEWNAME}#g" "${DATABASE}" || error_exit "Problem replacing multi-site path."

# make symlink to multisite files in files directory (temporarily)
echo "Linking in multisite & private files..."
OLDBASE="${MULTISITEROOT}"
NEWBASE="${SITEROOT}/sites/default"
OLDFILES="${OLDBASE}/files"
NEWFILES="${NEWBASE}/files"
OLDPRIVATE="${OLDBASE}/private/files"
NEWPRIVATE="${NEWBASE}/files/private"
DEFAULTFILES="${SITEROOT}/sites/default"
cd "${OLDFILES}"
if [ -d "private" ]; then
  error_exit "Private files directory already exists! ${OLDFILES}"
fi
cd "${NEWBASE}"
if [ -d "files" ]; then
  error_exit "Default files directory already exists in ${NEWBASE}"
fi
cd "${OLDFILES}"
ln -s "${OLDPRIVATE}" private || error_exit "Problem creating private files symlink"
cd "${NEWBASE}"
ln -s "${OLDFILES}" files || error_exit "Problem creating files symlink"

# make a drush archive dump of the site, including private files via the symlink
echo "Making site archive..."
ARDFILE="${EXPORTDIR}/archive.tar.gz"
drush "$TARGET_SITE_ALIAS" archive-dump --destination="${ARDFILE}" || error_exit "Problem making drush archive."

# delete the temporary symlinks
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
command -v aws >/dev/null 2>&1 || error_exit "Problem: aws command is not installed."
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




*********************************
# copy the modules, themes, libraries
echo 'Copying the code: modules, themes, libraries...'
rsync -azq --exclude /drush "${SITEROOT}/sites/all/" "${EXPORTDIR}/code" || error_exit "Problem copying code."

# copy the assets - files, private/files
echo 'Copying the assets: files, private/files...'
rsync -azq --exclude .htaccess "${MULTISITEROOT}/files" "${EXPORTDIR}/assets/" || error_exit "Problem moving files."
rsync -azq --exclude .htaccess "${MULTISITEROOT}/private" "${EXPORTDIR}/assets/" || error_exit "Problem moving private files."

# compress the exported data
ARCHIVEFILE="${EXPORTDIRNAME}.tar.gz"
ARCHIVEPATH="${TEMPDIR}/${ARCHIVEFILE}"
echo 'Compressing the whole export...'
cd "$TEMPDIR"
tar -zcf "${ARCHIVEFILE}" "${EXPORTDIRNAME}" || error_exit "Problem with tar."
rm -rf "${EXPORTDIR}" || error_exit "Can't remove ${EXPORTDIR}."
echo "Export is stored here:"
echo "$ARCHIVEPATH"


