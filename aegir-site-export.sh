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
# fix relative paths in the sql dump file
# /files/bla... becomes /sites/default/files/bla...
echo "Cleaning up relative file paths in sql dump..."
sed -i -e "s|\"/files/|\"/sites/default/files/|g" "${DATABASE}" || error_exit "Problem cleaning up relative file paths."

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
if [ -f "settings.php" ]; then
  error_exit "settings.php already exists in ${NEWBASE}"
fi
cd "${OLDFILES}"
ln -s "${OLDPRIVATE}" private || error_exit "Problem creating private files symlink"
cd "${NEWBASE}"
ln -s "${OLDFILES}" files || error_exit "Problem creating files symlink"
ln -s "${OLDBASE}/settings.php" settings.php || error_exit "Problem creating symlink for settings.php"

# make a drush archive dump of the site, including private files via the symlink
echo "Making site archive..."
ARDFILE="${EXPORTDIR}/archive.tar.gz"
sudo -u aegir drush "$TARGET_SITE_ALIAS" archive-dump default --destination="${ARDFILE}" || error_exit "Problem making drush archive."

# reset permissions
sudo chown -R aegir:lib_web_dev_role "$TEMP"
sudo chmod -R ug+rw "$TEMP"

# delete the temporary symlinks
echo "Unlinking multisite & private files..."
rm "${OLDFILES}/private" || error_exit "Can not remove symlink ${OLDFILES}/private"
rm "${NEWBASE}/files" || error_exit "Can not remove symlink ${NEWBASE}/files"
rm "${NEWBASE}/settings.php" || error_exit "Can not remove symlink ${NEWBASE}/settings.php"

# uncompress archive to access MANIFEST
echo "Adding database dump to archive MANIFEST.ini..."
cd "${EXPORTDIR}"
mkdir archive
tar -zxf archive.tar.gz -C archive || error_exit "Can not decompress archive"
rm archive.tar.gz

# get rid of any existing database dumps in the archive
echo "Removing extra database dump files from archive..."
find ./archive/*/sites/default/files/ \( -name "*.mysql.gz" -o -name "*.mysql.gz.info" -o -name "*.sql" -o -name "*.sql.bak" \) -type f -ls -delete
find ./archive/*/sites/default/private/ \( -name "*.mysql.gz" -o -name "*.mysql.gz.info" -o -name "*.sql" -o -name "*.sql.bak" \) -type f -ls -delete

mv database-default-site.sql archive/
echo 'database-default-file = "database-default-site.sql"' >> archive/MANIFEST.ini
echo 'database-default-driver = "mysql"' >> archive/MANIFEST.ini
tar -zcf archive.tar.gz archive || error_exit "Problem compressing"
rm -rf archive

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
aws s3 sync "${TARGET_SITE}" "s3://${BUCKET}/${TARGET_SITE}" || error_exit "Problem with aws sync"

# remove temp archive
echo "Cleaning up temp archive..."
rm -r "$EXPORTDIR"

echo "********************"
echo "Archive stored here:"
echo "https://s3.amazonaws.com/${BUCKET}/${TARGET_SITE}/archive.tar.gz"
echo "********************"

