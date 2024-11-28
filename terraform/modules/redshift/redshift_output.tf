output "dwh-output" {
  value = aws_redshift_cluster.redshift_cluster.dns_name
}