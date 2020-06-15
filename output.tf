output "public_ip_server" {
value="${aws_instance.server.public_ip}"
}

output "private_ip_server" {
value="${aws_instance.server.private_ip}"
}

output "public_ip_worker" {
value="${aws_instance.worker.public_ip}"
}