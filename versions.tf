terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = "~> 2.7"
    }
  }
}
