# Whole Tale Terraform Deployment

The following describes the basic process for deploying the Whole Tale services via Terraform.

## What you'll need
These are detailed below, but in short:
* OpenStack project with API access (and the default MTU)
* CoreOS image with at least Docker 17.09-ce (likely from [Alpha channel](https://alpha.release.core-os.net/amd64-usr/current/)).
* [CoreOS Config Transpiler](https://github.com/coreos/container-linux-config-transpiler)
* Wildcard DNS for your domain
* [Globus Auth client ID and secret](https://auth.globus.org/v2/web/developers)
* rclone binary 
* GoDaddy API integration


## OpenStack
The deployment process currently requires access to an OpenStack project with API access and has been tested on [NCSA Nebula](nebula.ncsa.illinois.edu) and [XSEDE Jetstream](https://portal.xsede.org/jetstream).

## Uploading image via glance

If not available on your system, download the alpha channel CoreOS image and add to OpenStack using the ``glance`` client:

```bash
wget https://alpha.release.core-os.net/amd64-usr/current/coreos_production_openstack_image.img.bz2
glance image-create --name "Container-Linux (1576.1.0)" --container-format bare --disk-format qcow2 \
       --file coreos_production_openstack_image.img
```

## Globus authentication
The ``globus_client_id`` and ``globus_client_secret`` can be obtained by setting up a custom application/service via the [Globus Auth developer tools](https://auth.globus.org/v2/web/developers).


## CoreOS Ignition
The deployment process uses CoreOS [Ignition](https://coreos.com/ignition/docs/latest/) to override some setting during the initial image boot process. This includes injecting authorized keys into instances and some settings including MTU and default nameserver.  Settings are stored in ``coreos.yaml``.

You'll need to download the config transpiler and add it to your ``PATH``:
```bash
$ wget https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.3.1/ct-v0.3.1-x86_64-unknown-linux-gnu
$ mv ct-v0.3.1-x86_64-unknown-linux-gnu ct
$ chmod +x ct
```

Then convert the ``coreos.yaml`` to ``config.ign``:

```bash
$ ct -platform openstack-metadata -in-file coreos.yaml -out-file config.ign
```

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
* num_slaves: Number of Swarm worker nodes
* domain: Domain name for Whole Tale deployment
* globus_client_id: Globus auth client ID
* globus_client_secret: Globus auth client secret
* docker_mtu: Docker MTU for  OpenStack
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
* Creates Docker swarm cluster including master and n workers
* Creates multiple Docker overlay networks
* Deploys replicated Mongo database and restores from backup
* Deploys traefik proxy with Let's Encrypy integration for TLS
* Deploys Celery master and workers
* Deploys core Girder and Dashboard services

