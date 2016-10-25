<?php

/**
 * example settings.php file for use on Pantheon Drupal sites
 *
 * Warning
 * You should never put the database connection information for a Pantheon database within your settings.php
 * file. These credentials will change. If you are having connection errors, make sure you are running
 * Pressflow core. This is a requirement.
 *
 * https://pantheon.io/docs/settings-php
 * https://github.com/pantheon-systems/pantheon-settings-examples
 *
 * Drupal 7 version
 *
 */

// Require HTTPS.
// Check if Drupal is running via command line
if (isset($_SERVER['PANTHEON_ENVIRONMENT']) &&
  ($_SERVER['HTTPS'] === 'OFF') &&
  (php_sapi_name() != "cli")) {
  if (!isset($_SERVER['HTTP_X_SSL']) ||
  (isset($_SERVER['HTTP_X_SSL']) && $_SERVER['HTTP_X_SSL'] != 'ON')) {
    header('HTTP/1.0 301 Moved Permanently');
    header('Location: https://'. $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI']);
    exit();
  }
}

/**
 * PHP settings:
 *
 * To see what PHP settings are possible, including whether they can be set at
 * runtime (by using ini_set()), read the PHP documentation:
 * http://www.php.net/manual/en/ini.list.php
 * See drupal_environment_initialize() in includes/bootstrap.inc for required
 * runtime settings and the .htaccess file for non-runtime settings. Settings
 * defined there should not be duplicated here so as to avoid conflict issues.
 */

/**
 * Some distributions of Linux (most notably Debian) ship their PHP
 * installations with garbage collection (gc) disabled. Since Drupal depends on
 * PHP's garbage collection for clearing sessions, ensure that garbage
 * collection occurs by using the most common settings.
 */
ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);

/**
 * Set session lifetime (in seconds), i.e. the time from the user's last visit
 * to the active session may be deleted by the session garbage collector. When
 * a session is deleted, authenticated users are logged out, and the contents
 * of the user's $_SESSION variable is discarded.
 */
ini_set('session.gc_maxlifetime', 200000);

/**
 * Set session cookie lifetime (in seconds), i.e. the time from the session is
 * created to the cookie expires, i.e. when the browser is expected to discard
 * the cookie. The value 0 means "until the browser is closed".
 */
ini_set('session.cookie_lifetime', 2000000);

 * configure trusted_host_pattern to avoid a warning within /admin/reports/status
 *
 */
if (defined('PANTHEON_ENVIRONMENT')) {
  if (in_array($_ENV['PANTHEON_ENVIRONMENT'], array('dev', 'test', 'live'))) {
    $settings['trusted_host_patterns'][] = "{$_ENV['PANTHEON_ENVIRONMENT']}-{$_ENV['PANTHEON_SITE_NAME']}.getpantheon.io";
    $settings['trusted_host_patterns'][] = "{$_ENV['PANTHEON_ENVIRONMENT']}-{$_ENV['PANTHEON_SITE_NAME']}.pantheon.io";
    $settings['trusted_host_patterns'][] = "{$_ENV['PANTHEON_ENVIRONMENT']}-{$_ENV['PANTHEON_SITE_NAME']}.pantheonsite.io";
    $settings['trusted_host_patterns'][] = "{$_ENV['PANTHEON_ENVIRONMENT']}-{$_ENV['PANTHEON_SITE_NAME']}.panth.io";

    # Replace value with custom domain(s) added in the site Dashboard
    $settings['trusted_host_patterns'][] = '^.+\.library.cornell\.edu$';
    $settings['trusted_host_patterns'][] = '^library.cornell\.edu$';
  }
}

/**
 * https://pantheon.io/docs/solr-drupal/
 * Choose the appropriate schema for the module that you are using (apachesolr or search_api_solr).
 * In the majority of cases, you will want to use 3.x/schema.xml.
 */
if (isset($_ENV['PANTHEON_ENVIRONMENT'])) {
 // set schema for apachesolr OR set schema for search_api_solr (uncomment the line you need)
 // $conf['pantheon_apachesolr_schema'] = 'sites/all/modules/apachesolr/solr-conf/solr-3.x/schema.xml';
 // $conf['pantheon_apachesolr_schema'] = 'sites/all/modules/search_api_solr/solr-conf/solr-3.x/schema.xml';
 // or if you have a contrib folder for modules use
 // $conf['pantheon_apachesolr_schema'] = 'sites/all/modules/contrib/apachesolr/solr-conf/solr-3.x/schema.xml';
 // $conf['pantheon_apachesolr_schema'] = 'sites/all/modules/contrib/search_api_solr/solr-conf/solr-3.x/schema.xml';
}
