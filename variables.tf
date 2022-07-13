variable "region" {
    default = "RegionOne"
}

variable "image" {
    default = "Ubuntu 20.04 LTS" 
    description = "openstack image list : Name"
}

variable "flavor_fileserver" {
    default = "m3.quad"
    description = "openstack flavor list : Name"
}

variable "flavor_manager" {
    default = "m3.quad"
    description = "openstack flavor list : Name"
}

variable "flavor_worker" {
    default = "m3.medium"
    description = "openstack flavor list : Name"
}

variable "ssh_key_file" {
    default = "~/.ssh/id_rsa"
    description = "Path to pub key (assumes it ends with .pub)"
}

variable "ssh_user_name" {
    default = "ubuntu"
    description = "Image specific user"
}

variable "external_gateway" {
    default = "3fe22c05-6206-4db2-9a13-44f04b6796e6"
    description = "openstack network list (network with public interfaces)"
}

variable "pool" {
    default = "public"
    description = "Network pool for assigning floating_ips"
}

variable "external_subnet" {
    default = "192.168.102.0/24"
    description = "Default subnet for external network"
}

variable "internal_subnet" {
    default = "192.168.152.0/24"
    description = "Default subnet for external network"
}

variable "cluster_name" {
    default = "wt-prod"
    description = "Cluster name"
}

variable "num_workers" {
    default = 3
    description = "Number of worker nodes"
}

variable "domain" {
    default = "wholetale.org"
    description = "Site domain name"
}

variable "globus_client_id" {
    default = ""
    description = "Globus client ID"
}

variable "globus_client_secret" {
    default = ""
    description = "Globus client secret"
}

variable "dms_volume_size" {
    default = 100
    description = "DMS volume size in GB"
}

variable "registry_volume_size" {
    default = 1000
    description = "Registry volume size in GB"
}

variable "homes_volume_size" {
    default = 1000 
    description = "Homes volume size in GB"
}

variable "docker_volume_size" {
    default = 500
    description = "Fileserver volume size in GB"
}

variable "registry_user" {
    default = ""
    description = "Default user used in the internal docker registry"
}

variable "registry_pass" {
    default = ""
    description = "Random password for the user used in the internal docker registry"
}

variable "godaddy_api_key" {
   default = ""
   description = "API key for GoDaddy DNS"
}

variable "godaddy_api_secret" {
   default = ""
   description = "API secret for GoDaddy DNS"
}

variable "matlab_file_installation_key" {
   default = ""
   description = "MATLAB file installation key"
}

variable "version" {
   default = "v1.1"
   description = "Docker component versions"
}

variable "dataone_url" {
   default = "https://dev.nceas.ucsb.edu/cn/v2"
   description = "DataONE member node URL"
}
