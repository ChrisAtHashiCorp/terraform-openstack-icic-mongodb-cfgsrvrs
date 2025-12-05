resource "random_id" "cluster_id" {
  byte_length = 8
}

resource "random_id" "node_id" {
  count       = var.node_count
  byte_length = 8
}

locals {
  fqdns = [for i in range(var.node_count) : "${var.name_prefix}-${random_id.node_id[i].hex}.${var.domain}"]

  mongod-config = [for i in range(var.node_count) : templatefile("${path.module}/provision/mongod.conf.tftpl",
    {
      fqdn       = local.fqdns[i]
      cluster_id = random_id.cluster_id.hex
    }
  )]

  replicaset-config = templatefile("${path.module}/provision/replicaset-cfg.js.tftpl",
    {
      cluster_id = random_id.cluster_id.hex
      nodes      = { for k in range(var.node_count) : k => local.fqdns[k] }
    }
  )

  user-data = [for i in range(var.node_count) : templatefile("${path.module}/provision/cloud-init.yml.tftpl",
    {
      fqdn              = local.fqdns[i]
      mongod-config     = base64encode(local.mongod-config[i])
      replicaset-config = base64encode(local.replicaset-config)
    }
  )]
}

resource "openstack_compute_keypair_v2" "sshkey" {
  name = "${var.sshkey_prefix}-${random_id.cluster_id.hex}"
}

resource "openstack_compute_instance_v2" "nodes" {
  count = var.node_count

  name        = local.fqdns[count.index]
  image_id    = var.image_id
  flavor_name = var.flavor
  key_pair    = openstack_compute_keypair_v2.sshkey.name
  user_data   = local.user-data[count.index]

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
  hosts_file      = [for i in range(var.node_count) : "${openstack_compute_instance_v2.nodes[i].access_ip_v4} ${local.fqdns[i]}"]
  hosts_file_cmds = [for i in local.hosts_file : "echo \"${i}\" | sudo tee -a /etc/hosts"]
}

resource "ssh_resource" "node-hostfile" {
  count = var.node_count

  bastion_host     = var.ssh_bastion.host
  bastion_user     = var.ssh_bastion.user
  bastion_password = var.ssh_bastion.password

  host     = openstack_compute_instance_v2.nodes[count.index].access_ip_v4
  user     = var.ssh_conn.user
  password = var.ssh_conn.password

  timeout = "30s"

  commands = local.hosts_file_cmds
}
