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
* settings.php
	* aegir puts a lot of configuration specific stuff in settings.php
	* it's quite likely that existing settings.php files are somewhat out of date
	* Pantheon's Status > Launch Check feature complains about "Fast 404 pages". The fixes for this are placed in settings.php
	* Pantheon's settings.php file does *NOT* contain the database connection information
	* see the example settings.php file here: https://github.com/cul-it/pantheon-settings

## Before you export
* Disable Simple SAML
	* it is not working on Pantheon yet
	* disable the feature "SimpleSAML Authentication for CUL"
	* disable the module "simpleSAMLphp authentication"
* Move a clone of your Aegir site to the dev server
	* we can access all the parts of the site on lamp-stg but not lamp-prod
	* move the clone to Pantheon from lamp-stg
* the script will get rid of any extra database dumps in the archive
	* extra database dumps causes the Pantheon import script to fail

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
* ssh over to victoria01.library.cornell.edu
* run this script with your site name:

`
/usr/local/bin/victoria-site-export.sh sitename.library.cornell.edu
`

* make note of where the export is stored:

`
https://s3.amazonaws.com/pantheon-imports/sitename.library.cornell.edu/archive.tar.gz
`

## Import into a new Pantheon site
* Follow the first steps for [Guided Migration](https://pantheon.io/docs/migrate/#guided-migration)
* **SKIP the step called "Create an Archive of Your Existing Site With Drush"** - just click on the button "Continue Migration"
* When you get to the step "Import Site Archive", choose the "URL" method, and enter the Amazon s3 path of your site export from above, (something like https://s3.amazonaws.com/pantheon-imports/sitename.library.cornell.edu/archive.tar.gz), and click "Import Archive"
* Watch as "We're Migrating Your Site to Pantheon!" displays

## Import into an existing Pantheon site
* Install terminus onto your own laptop
 * https://github.com/pantheon-systems/terminus/blob/master/README.md#installation
 * I had better luck with the Homebrew installation on Mac OSX than with composer.
* Find the Pantheon name of your site in the Name column after running:

`terminus sites show
`

* Run the terminus site archive import command

`terminus site import --site=sitenamelibrarycornelledu --url=https://s3.amazonaws.com/pantheon-imports/sitename.library.cornell.edu/archive.tar.gz
`

## Once the site is on Pantheon
* get rid of any /sites/sites.php file (for multi-site only)
* overwrite /sites/default/settings.php with the CUL version https://github.com/cul-it/pantheon-settings
* check the Status page in the Pantheon environments for other suggestions - usually caching and cleaning up unused modules
