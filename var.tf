variable "machine_type" {
    type = string
    description = "describe your variable type"
    default = "f1-micro"
}

variable "name" {
    type = string
    description = "name used on each of the modules created"
    default = "single-lb"
}

variable "image" {
    type = string
    description = "image that will run on the machine"
}

variable "port" {
    type = number
    description = "port to route the traffic to"
    default = 80
}

variable "domain" {
    type = string
    description = "Domain which will be registered on the ssl cert"
}