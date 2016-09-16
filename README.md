# Move Aegir site to Pantheon

Updated: 9/14/2016 jgr25

## First time only
* Install drush
 * http://docs.drush.org/en/master/install/
* Install terminus
 * https://github.com/pantheon-systems/terminus/blob/master/README.md#installation
 * I had better luck with the Homebrew installation on Mac OSX than with composer.

## Differences between our setup and Pantheon's
* Files Paths
 * Pantheon
	  * [site-root]/sites/default/files
	  * [site-root]/sites/default/files/private
 * Aegir
	  * [site-root]/sites/[site-name]/files
	  * [site-root]/sites/[site-name]/private/files
 * Victorias
	  * [site-root]/sites/default/files
	  * [site-root]/../drupal_files
* No Multi-Site
* No support for Drupal 6 sites

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
* use victoria-site-export.sh

## Replace local git repo's /sites/all with yours
