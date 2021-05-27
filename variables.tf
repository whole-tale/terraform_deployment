variable "region" {
    default = "RegionOne"
}

variable "image" {
    default = "Ubuntu 20.04 LTS" 
    description = "openstack image list : Name"
}

variable "flavor" {
    default = "m1.medium"
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
    default = "bef0fe11-1646-4826-9776-3afdf95e53b9"
    description = "openstack network list (network with public interfaces)"
}

variable "pool" {
    default = "ext-net"
    description = "Network pool for assigning floating_ips"
}

variable "external_subnet" {
    default = "192.168.99.0/24"
    description = "Default subnet for external network"
}

variable "internal_subnet" {
    default = "192.168.149.0/24"
    description = "Default subnet for external network"
}

variable "cluster_name" {
    default = "wt-dev"
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

variable "homes_volume_size" {
    default =  50
    description = "Home volume size in GB"
}

variable "registry_volume_size" {
    default =  50
    description = "Registry volume size in GB"
}

variable "dms_volume_size" {
    default =  50
    description = "DMS volume size in GB"
}

variable "docker_volume_size" {
    default =  50
    description = "Docker volume size in GB"
}

variable "registry_user" {
    default = "fido"
    description = "Default user used in the internal docker registry"
}

variable "registry_pass" {
    default = "10DSObv0Awqaa8Wz4d3K"
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
   default = "latest"
   description = "Docker component versions"
}

variable "dataone_url" {
   default = "https://cn-stage-2.test.dataone.org/cn"
   description = "DataONE member node URL"
}
