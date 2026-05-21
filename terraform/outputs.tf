output "api_gateway_public_ip" {
  description = "Public IP address of the API gateway VM."
  value       = google_compute_instance.api_gateway.network_interface[0].access_config[0].nat_ip
}

output "python_worker_private_ip" {
  description = "Private IP address of the Python worker VM."
  value       = google_compute_instance.python_worker.network_interface[0].network_ip
}

output "node_worker_private_ip" {
  description = "Private IP address of the Node worker VM."
  value       = google_compute_instance.node_worker.network_interface[0].network_ip
}

output "vpc_name" {
  description = "Name of the shared VPC network."
  value       = google_compute_network.private_vpc.name
}
