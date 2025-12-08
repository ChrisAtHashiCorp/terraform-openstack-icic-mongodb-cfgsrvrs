output "fqdns" {
  value = [ for i in range(var.node_count): { "${i}" = "${openstack_compute_instance_v2.nodes[i].access_ip_v4}" } ]
}
