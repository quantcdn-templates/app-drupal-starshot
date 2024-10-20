# Drupal Starshot QuantCDN starter template

This template provides everything you need to get started with [Drupal Starshot](https://www.drupal.org/about/starshot) on QuantCDN.

Click the "Deploy to Quant" button to create a new GitHub repository, QuantCDN project, and deployment pipelines.

[![Deploy to Quant](https://www.quantcdn.io/img/quant-deploy-btn-sml.svg)](https://dashboard.quantcdn.io/deploy/step-one?template=app-drupal-starshot)

`@todo: Quant Cloud deployments are not yet supported for Starshot, coming soon.`

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/quantcdn-templates/app-drupal-starshot)


## Getting Started

## Local development

This is a composer-managed codebase. In the `src` folder simply run `composer install` to install all required dependencies.

### Drupal

To assist with local development this starterkit is compatible with a number of local stack management tools. We have provided some instructions to help with getting you set up quickly.

#### DDEV (Recommended)

To get started with [DDEV](https://ddev.readthedocs.io/en/stable/).

1. Follow the [installation documentation](https://ddev.readthedocs.io/en/stable/users/install/) for DDEV for your OS
2. Run `ddev start` from the repository root
3. Run `ddev init` for your first time install
4. .. (or import your database) `ddev import-db --file=dumpfile.sql.gz`

This will use the configuration file `.ddev/config.yml` and defines the minimum requirements to get your local stack up and running.

By default Drupal will be available at https://starshot.ddev.site

##### First time install in DDEV

A custom command is provided to perform a fresh site install, along with enabling the modules required for Drupal Starshot. To perform a fresh site install run:
```
ddev init
```

##### Enable Redis in DDEV

Quant Cloud codebases are Redis-enabled by default, and it is recommended you use Redis in your local development environments for the best experience.

To add Redis to your local DDEV environment simply run:

1. `ddev get ddev/ddev-redis`
2. `ddev restart`

You should see Redis is connected and functioning from the Reports > Redis report.


#### Docker compose

This is a composer-managed codebase. In the `src` folder simply run `composer install` to install all required dependencies.

#### First time build (Drupal)

First, we must build Drupal and install a blank site with the recommended modules.
```
docker compose up -d
docker compose exec app drush site:install --account-name=admin --account-pass=admin -y
docker compose exec app drush pm:install experience_builder media media_library
docker compose exec app drush pm:install components
docker compose exec app drush theme:enable civictheme -y
docker compose exec app drush theme:enable starshot_demo -y
docker compose exec app drush config:set system.theme default starshot_demo -y
```

Drupal will be running at http://localhost:80


### Management

#### Database import & export

To export a MySQL database run `docker compose exec -T mariadb mysqldump drupal -udrupal -pdrupal > /path/to/database.sql`.
To import a MySQL database run `docker compose exec -T mariadb mysql drupal -udrupal -pdrupal < /path/to/database.sql`.

### Deployment & Management

This template automatically preconfigures your CI pipeline to deploy to Quant. This means you simply need to edit the codebase in the `src` folder and commit changes to trigger the build & deploy process.

#### Post-deployment script

To run processes after a deployment completes (e.g cache rebuild, configuration import) you may modify the contents of the `.docker/deployment-scripts/post-deploy.sh` script.

#### Cron Jobs

Cron jobs will run on a schedule as defined in the `.github/workflows/cron.yaml` file. By default they will run once every 3 hours.

To modify the processes that run during cron you may modify the contents of the `.docker/deployment-scripts/cron.sh` script.

#### Database backups

To take a database backup navigate to your GitHub actions page > Database backup > Run workflow. The resulting database dump will be attached as a CI artefact for download.

#### Managing settings.php and services.yml

Modify the `settings.php` and `services.yml` files provided in the `src` folder to make changes. These files are automatically added to the appropriate location in the Drupal webroot via Composer:
```
    "scripts": {
        "post-install-cmd": [
            "@php -r \"copy('settings.php', 'web/sites/default/settings.php');\"",
            "@php -r \"copy('services.yml', 'web/sites/default/services.yml');\""
        ]
    }
```

The `settings.php` file comes preloaded with important values required for operation on Quant Cloud. If you replace this file please ensure you account for the inclusions below.

**Database connection:**
```
$databases['default']['default'] = [
    'database' => getenv('MARIADB_DATABASE'),
    'username' => getenv('MARIADB_USER'),
    'password' => getenv('MARIADB_PASSWORD'),
    'host' => getenv('MARIADB_HOST'),
    'port' => getenv('MARIADB_PORT') ?: 3306,
    'driver' => 'mysql',
    'prefix' => getenv('MARIADB_PREFIX') ?: '',
    'collation' => 'utf8mb4_general_ci',
];
```

**Configuration directory:**
```
$settings['config_sync_directory'] = '../config/default';
```

**Hash salt:**
```
$settings['hash_salt'] = getenv('MARIADB_DATABASE');
```

**Trusted host patterns:**
```
$settings['trusted_host_patterns'] = [
  '\.apps\.quant\.cloud$',
];
```

**Reverse proxy:**
```
$settings['reverse_proxy'] = TRUE;
$settings['reverse_proxy_addresses'] = array($_SERVER['REMOTE_ADDR']);
```

**Origin protection (if enabled):**
```
// Direct application protection.
// Must route via edge.
$headers = getallheaders();
if (PHP_SAPI !== 'cli' &&
  ($_SERVER['REMOTE_ADDR'] != '127.0.0.1') &&
  (empty($headers['X_QUANT_TOKEN']) || $headers['X_QUANT_TOKEN'] != 'abc123')) {
  die("Not allowed.");
}
```
