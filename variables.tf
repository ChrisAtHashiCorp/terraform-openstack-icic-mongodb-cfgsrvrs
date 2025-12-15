variable "name_prefix" {
  type    = string
  default = "mongodb-cfg"
}

variable "domain" {
  type = string
}

variable "node_count" {
  type    = number
  default = 3
}

variable "image_id" {
  type = string
}

variable "flavor" {
  type    = string
  default = "tiny"
}

variable "network" {
  type = string
}

variable "sshkey_prefix" {
  type    = string
  default = "mongodb"
}

variable "ssh_conn" {
  sensitive = true
  type = object({
    user     = optional(string, "root")
    password = optional(string, "HashiPass123")
  })
  default = {user = "root", password = "HashiPass123!"}
}

variable "ssh_bastion" {
  sensitive = true
  type = object({
    host     = optional(string, null)
    port     = optional(string, "22")
    user     = optional(string, null)
    password = optional(string, null)
  })
  default = {}
}
