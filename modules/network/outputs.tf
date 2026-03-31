output "vpc_id" {
  description = "作成されたVPCのID"
  value       = aws_vpc.this.id
}

output "internet_gateway_id" {
  description = "Internet GatewayのID"
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "Private DB subnet IDs"
  value       = aws_subnet.private_db[*].id
}
