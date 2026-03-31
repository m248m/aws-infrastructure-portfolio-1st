output "db_endpoint" {
  description = "RDSエンドポイント（アプリケーションからの接続先）"
  value       = aws_db_instance.this.endpoint
}

output "db_port" {
  description = "RDSポート番号"
  value       = aws_db_instance.this.port
}

output "db_identifier" {
  description = "RDSインスタンス識別子"
  value       = aws_db_instance.this.identifier
}
