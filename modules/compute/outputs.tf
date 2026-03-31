output "alb_dns_name" {
  description = "ALBのDNS名（ブラウザアクセス用URL）"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ALBのARN（他リソースでの参照用）"
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "Target GroupのARN"
  value       = aws_lb_target_group.app.arn
}
