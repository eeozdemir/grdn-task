output "db_instance_endpoint" {
  description = "The connection endpoint"
  value       = aws_db_instance.default.endpoint
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.default.db_name
}