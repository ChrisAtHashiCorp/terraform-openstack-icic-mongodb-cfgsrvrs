resource "random_id" "cluster_id" {
  byte_length = 8
}

resource "random_id" "node_id" {
  count       = var.node_count
  byte_length = 8
}

locals {
  fqdns = [for i in range(var.node_count) : "${var.name_prefix}-${random_id.node_id[i].hex}.${var.domain}"]

  mongod-config = {
    for fqdn in local.fqdns : fqdn => templatefile("${path.module}/provision/mongod.conf.tftpl",
      {
        cluster_id = random_id.cluster_id.hex
      }
    )
  }
  user-data = {
    for fqdn in local.fqdns : fqdn => templatefile("${path.module}/provision/cloud-init.yml.tftpl", {})
  }
}

resource "openstack_compute_keypair_v2" "sshkey" {
  name = "${var.sshkey_prefix}-${random_id.cluster_id.hex}"
}

resource "openstack_compute_instance_v2" "nodes" {
  for_each = toset(local.fqdns)

  name        = each.value
  image_id    = var.image_id
  flavor_name = var.flavor
  key_pair    = openstack_compute_keypair_v2.sshkey.name
  user_data   = local.user-data[each.key]

  network {
    name = var.network
  }

  tags = ["cluster_id=${random_id.cluster_id.hex}"]

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Add static entries for DNS on nodes

locals {
  hosts_file      = [for i in local.fqdns : "${openstack_compute_instance_v2.nodes[i].access_ip_v4} ${i}"]
  hosts_file_cmds = [for i in local.hosts_file : "echo \"${i}\" | sudo tee -a /etc/hosts"]
}

resource "ssh_resource" "node-hostfile" {
  for_each = toset(local.fqdns)

  bastion_host     = var.ssh_bastion.host
  bastion_user     = var.ssh_bastion.user
  bastion_password = var.ssh_bastion.password

  host     = openstack_compute_instance_v2.nodes[each.key].access_ip_v4
  user     = var.ssh_conn.user
  password = var.ssh_conn.password

  timeout = "30s"

  commands = local.hosts_file_cmds
}
