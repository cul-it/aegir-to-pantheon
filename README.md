# Move Aegir site to Pantheon

Updated: 9/12/2016 jgr25

## First time only
* Install drush
* Install terminus

## Make an empty site on Pantheon

## Make a local git repo of the Pantheon site

## Export your Drupal site

### Exporting from Aegir
*Note: if your site is on the production server, clone it and move the clone to lamp-stg. Run this export on the clone.*

* ssh over to lamp-stg.library.cornell.edu
* run this script with your site name:
`
/cul/data/aegir/scratch/aegir-to-pantheon/aegir-site-export.sh sitename.library.cornell.edu
`
* make note of where the export is stored:
`
/tmp/aegir-site-export/sitename.library.cornell.edu/export.tar.gz
`

### Exporting from Victorias
* use a different script

## Replace local git repo's /sites/all with yours
