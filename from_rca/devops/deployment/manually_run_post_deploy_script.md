# You'd do this if, for instance, the container build portion of the deployment finished fine but it timed out while deploying the containers to the targets (or for troubleshooting an issue like that).
    sudo su - dokku
    export PLUGIN_CORE_AVAILABLE_PATH=/var/lib/dokku/core-plugins/available
    cd ~/caredfor-frontend-rca-export
    ./POST_DEPLOY_SCRIPT