#!/bin/bash
# upload-files.sh - upload file archive to Pantheon
# see https://pantheon.io/docs/rsync-and-sftp/

TARGET_SITE="$1"
TARGET_SITE_ALIAS="@${TARGET_SITE}"
FILES="$2"

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
  echo "Usage: $0 <pantheon site> <files archive"
  echo "Example: $0 warburglibrarycornelledu export/files"
  error_exit "Please try again..."
}

# check argument count
if [ $# -ne 2 ]; then
    useage
fi


export ENV='dev'
export SITE="${TARGET_SITE}"

rsync -rlvz --size-only --ipv4 --progress --dry-run  -e 'ssh -p 2222' "${TARGET_SITE}/*" --temp-dir=../tmp/ $ENV.$SITE@appserver.$ENV.$SITE.drush.in:files/
