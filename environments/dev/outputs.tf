output "alb_dns_name" {
  description = "ブラウザアクセス用URL"
  value       = "http://${module.compute.alb_dns_name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "rds_endpoint" {
  description = "RDSエンドポイント"
  value       = module.database.db_endpoint
  sensitive   = true
}
