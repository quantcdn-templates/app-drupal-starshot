#!/bin/bash

# Run post-deployment scripts.
if [ "$QUANT_ENVIRONMENT_TYPE" == "development" ]; then
    ##
    ## Fresh installation example.
    ##
    STATUS=$(drush status --fields=bootstrap --format=json)

    # Drupal cannot be bootstrapped.
    # Here we perform a fresh installation, and install the required default modules.
    # We install devel_generate to create some sample content.
    if [ "$(jq -r '.bootstrap' 2> /dev/null <<< "$STATUS")" != "Successful" ]; then
        drush sql:create -y
        drush site:install -y
        drush site:install --account-name=admin --account-pass=admin -y
        drush pm:install experience_builder media media_library
        drush pm:install components
        drush theme:enable civictheme -y
        drush theme:enable starshot_demo -y
        drush config:set system.theme default starshot_demo -y
        # Clear the cache
        drush cr
    fi
fi
