# Implementation Details

## Setup
* drush
* terminus 
	* requires PHP version 5.5.9 or later
	* did not install correctly on lamp-stg
	* user has to authenticate - how does this work on server?
		* terminus auth login

## Gotcha
* site archive files need to be web accessible to be imported into Pantheon
* the migrate scripts will get rid of any extra database dumps in the archive
	* extra database dumps causes the Pantheon import script to fail


## Dealing with private files
* different layouts for private files directory Pantheon, Aegir, Victorias
* luckily, the drush archive-dump follows symbolic links
 * temporarily place a symbolic link to private files in /sites/default/files/private where Pantheon expects to find the private files
 * ard file will be restored as if the private files were in that locatin all along
* fix any path to the private files in the database dump so references will point to new location
	* most sites would only need to change the filesystem settings, since they don't use private files.
	* lets do this as a separate manual task for the few sites that need it

## Fastest way to import
* use terminus if ard file < 500Mb
`terminus site import --site=ltslibrarycornelledu --url=https://lts.library.cornell.edu/sites/default/files/panthexit/ad9fe7a9g7e.tar.gz`
* unpack the archive file and follow manual import method otherwise
	* 