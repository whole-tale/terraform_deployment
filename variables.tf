variable "region" {
    default = "RegionOne"
}

variable "image" {
    default = "Container-Linux (1562.0.0)"
    description = "openstack image list : Name"
}

variable "flavor" {
    default = "m1.small"
    description = "openstack flavor list : Name"
}

variable "ssh_key_file" {
    default = "~/.ssh/id_rsa"
    description = "Path to pub key (assumes it ends with .pub)"
}

variable "ssh_user_name" {
    default = "core"
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

variable "cluster_name" {
    default = "wt-dev"
    description = "Cluster name"
}

variable "num_slaves" {
    default = 3
    description = "Number of slave nodes"
}

variable "docker_mtu" {
    default = "1454"
    description = "Docker MTU"
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

variable "nfs_volume_size" {
    default =  40
    description = "Fileserver volume size in GB"
}
