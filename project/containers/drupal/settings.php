<?php

$settings['reverse_proxy'] = TRUE;
$settings['reverse_proxy_addresses'] = ['172.18.0.0/16'];

$settings['reverse_proxy_trusted_headers'] = 31;

$settings['trusted_host_patterns'] = [
    '^nginx\.devops$', 
    '^web\.devops$',
    '^[0-9\.]+$',
];

$databases['default']['default'] = [
  //  ToDo () getenv('ENV_PASSWORD e.t.c...')
  'database' => 'drupal',
  'username' => 'drupal',
  'password' => 'drupal',
  'prefix' => '',
  'host' => 'database',
  'port' => '3306',
  'isolation_level' => 'READ COMMITTED',
  'driver' => 'mysql',
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
];

$settings['hash_salt'] = 'F0SWiGt55Sq2w26Sa_jAmM4TQ2yifSrJ3SSMrvau656msLy8HdLM6CvfucK4UXmvJpFnaCXq-w';
$settings['config_sync_directory'] = 'sites/default/files/config_579E8Z2nmJYBk7PZ0vDlLc9CJT74-qtKLusrKECIavUIdlI6QnHeuGV4Uzb8BkoBFLP6QS0mfQ/sync';