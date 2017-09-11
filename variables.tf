variable "region" {
    default = "RegionOne"
}

variable "image" {
    default = "Container-Linux (1451.2.0)"
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

variable "num_slaves" {
    default = 3
    description = "Number of slave nodes"
}
