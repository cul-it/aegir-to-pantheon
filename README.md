# Move Aegir or Victoria site to Pantheon

Updated: 9/19/2016 jgr25

## Differences between our setup and Pantheon's
* Files Paths
 * Pantheon
	  * public files here: [site-root]/sites/default/files
	  * private files here: [site-root]/sites/default/files/private
	  * Pantheon has a designated spot for temp files, and ignores imported temp files settings
 * Aegir
	  * public files here: [site-root]/sites/[site-name]/files
	  * private files here: [site-root]/sites/[site-name]/private/files
 * Victorias
	  * public files here: [site-root]/sites/default/files
	  * private files here: [site-root]/../drupal_files
* No Multi-Site
* No support for Drupal 6 sites

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
https://s3.amazonaws.com/pantheon-imports/sitename.library.cornell.edu/archive.tar.gz
`

### Exporting from Victorias
* use victoria-site-export.sh

## Import into a new Pantheon site

## Import into an existing Pantheon site
* Install terminus
 * https://github.com/pantheon-systems/terminus/blob/master/README.md#installation
 * I had better luck with the Homebrew installation on Mac OSX than with composer.

