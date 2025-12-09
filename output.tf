output "fqdns" {
  value = [ for i in range(var.node_count): { "${local.fqdns[i]}" = "${openstack_compute_instance_v2.nodes[i].access_ip_v4}" } ]
}

output "cluster_id" {
  value = "cfg-${random_id.cluster_id.hex}"
}
