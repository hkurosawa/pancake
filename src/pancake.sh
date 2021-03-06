#!/bin/bash
CAKE='./Vendor/bin/cake'
COMPOSER_JSON='{
    "name": "websandbox",
    "require": {
        "cakephp/cakephp": ">=2.5.0",
        "cakephp/debug_kit": "2.2.*",
        "slywalker/boost_cake": "*"
    },
    "config": {
        "vendor-dir": "Vendor/"
    }}'; 
CAKE_CORE_INCLUDE_PATH="define('CAKE_CORE_INCLUDE_PATH', ROOT . DS . APP_DIR . '/Vendor/cakephp/cakephp/lib');";
AUTOLOADER_FIX="
// Load Composer autoload.
require APP . '/Vendor/autoload.php';

// Remove and re-prepend CakePHP's autoloader as Composer thinks it is the
// most important.
// See: http://goo.gl/kKVJO7
spl_autoload_unregister(array('App', 'load'));
spl_autoload_register(array('App', 'load'), true, true);";
APPCONTROLLER_FIX='\
    public \$helpers = array(\
        "Session",\
        "Html" => array("className" => "BoostCake.BoostCakeHtml"),\
        "Form" => array("className" => "BoostCake.BoostCakeForm"),\
        "Paginator" => array("className" => "BoostCake.BoostCakePaginator")\
    );\
    public \$components = \
    array("DebugKit.Toolbar");\
';
#create composer.json file
echo $COMPOSER_JSON > ./composer.json
#download composer.phar
curl -sS https://getcomposer.org/installer | php -d detect_unicode=Off
#install components using composer
php composer.phar install
#bake project to current directory
$CAKE bake project . 
#enable DebugKit (loads all plugin)
echo -e "\nCakePlugin::loadAll();" >> ./Config/bootstrap.php
#bake database config
$CAKE bake db_config
#changing CAKE_CORE_INCLUDE_PATH to be a relative path
#http://book.cakephp.org/2.0/en/installation/advanced-installation.html
pushd webroot
sed -i '' -e "/^define('CAKE_CORE_INCLUDE_PATH'.*;/i\\
$CAKE_CORE_INCLUDE_PATH
" -e "s/^\(define(\'CAKE_CORE_INCLUDE_PATH\'.*;\)/\/\/\1/" index.php
popd
#set up autoloader
#http://book.cakephp.org/2.0/en/installation/advanced-installation.html
echo "$AUTOLOADER_FIX" >> Config/bootstrap.php
#enabling DebugKit
sed -i '' -e "/^class AppController extends Controller.*/a\\
$APPCONTROLLER_FIX
" Controller/AppController.php
