# Whole Tale Terraform Deployment

The following describes the basic process for deploying the Whole Tale services via Terraform.

## What you'll need
These are detailed below, but in short:
* OpenStack project with API access (and the default MTU)
* Ubuntu 20.04 LTS image 
* Wildcard DNS for your domain
* [Globus Auth client ID and secret](https://auth.globus.org/v2/web/developers)
* rclone binary 
* GoDaddy API integration


## OpenStack
The deployment process currently requires access to an OpenStack project with API access and has been tested on [NCSA Nebula](nebula.ncsa.illinois.edu) and [XSEDE Jetstream](https://portal.xsede.org/jetstream).

## Uploading image via glance

If not available on your system, download the alpha channel CoreOS image and add to OpenStack using the ``glance`` client:

```bash
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
openstack image create  --container-format bare --disk-format qcow2  --file focal-server-cloudimg-amd64.img "Ubuntu 20.04 LTS"
```

## Globus authentication
The ``globus_client_id`` and ``globus_client_secret`` can be obtained by setting up a custom application/service via the [Globus Auth developer tools](https://auth.globus.org/v2/web/developers).

## Setup rclone

The backup process leverages rclone, a simple command line tool to syncrhonize files to a variety of cloud storage services.  We currently use Box for the Whole Tale system. This requires creating an `rclone.conf` file prior to deployment:

```
wget https://downloads.rclone.org/v1.39/rclone-v1.39-linux-amd64.zip
unzip
rclone --config rclone.conf config
```

This will walk you through an interactive session.  Select the following options:
* New config (n) named `backup`
* Use Box 
* Leave client ID and secret blank
* Use auto configure (Y)
* This will open a browser and prompt you to login to Box

This process will generate a config file with the following information:

```
[backup]
type = box
client_id =
client_secret =
token = {"access_token":"<token>","token_type":"bearer","refresh_token":"<token>","expiry":"<date>"}
```

Rclone is used by the `wholetale/backup` container to backup and restore home directories and Mongo using Box.

## GoDaddy API Integration

The deployment process uses the GoDaddy API to automatically create DNS entries for non-production deployments and for wildcard certificate generation.

## Terraform variables

The deployment process uses [Terraform](https://www.terraform.io/).  You'll need to [download and install Terraform for your OS](https://www.terraform.io/downloads.html). Tthis deployment process currently supports only the OpenStack provider.

The ``variables.tf`` file contains variables used during the deployment process. Important variables include:
* image: Image name for CoreOS in your OpenStack project.
* flavor: Instance flavor in OpenStack
* external_gateway: ID for external gateway from OpenStack
* pool: Name of OpenStack floating IP pool
* num_workers: Number of Swarm worker nodes
* domain: Domain name for Whole Tale deployment
* globus_client_id: Globus auth client ID
* globus_client_secret: Globus auth client secret
* godaddy_api_key:  GoDaddy API key
* godaddy_api_secret: GoDaddy API secret

## Terraform deployment

With these settings in place, the deployment process is simple:

```bash
source openstack-rc.sh
terraform apply
```

What happens?
* Creates OpenStack networks and security groups
* Provisions VM instances and volumes
* Creates Docker swarm cluster including manager and n workers
* Creates multiple Docker overlay networks
* Deploys replicated Mongo database and restores from backup
* Deploys traefik proxy with Let's Encrypy integration for TLS
* Deploys Celery manager and workers
* Deploys core Girder and Dashboard services

