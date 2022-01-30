output "address" {
  value = aws_db_instance.example.address
  description = "Database address"
}

output "port" {
  value = aws_db_instance.example.port
  description = "The port of the databsase is listening on"
}
