output "alb_security_group_id" {
  description = "ALB用セキュリティグループのID"
  value       = aws_security_group.alb.id
}

output "ec2_security_group_id" {
  description = "EC2(App)用セキュリティグループのID"
  value       = aws_security_group.app.id  # ← ec2 を app に修正
}

output "db_security_group_id" {
  description = "RDS(DB)用セキュリティグループのID"
  value       = aws_security_group.db.id
}
