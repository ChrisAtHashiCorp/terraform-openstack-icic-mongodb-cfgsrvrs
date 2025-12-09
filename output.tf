output "fqdns" {
  value = { for i, k in local.fqdns : k => "${openstack_compute_instance_v2.nodes[i].access_ip_v4}" }
}

output "cluster_id" {
  value = "cfg-${random_id.cluster_id.hex}"
}
