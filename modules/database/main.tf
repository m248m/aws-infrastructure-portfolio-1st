# DBサブネットグループ（RDS Multi-AZの前提条件）
resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  }
}

# RDSインスタンス（MySQL Multi-AZ構成）
resource "aws_db_instance" "this" {
  identifier = "${var.project}-${var.environment}-db-mysql"

  # エンジン設定
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro" # 無料枠対象

  # ストレージ設定（ポートフォリオ用最小構成）
  allocated_storage     = 20
  max_allocated_storage = 100 # 自動拡張上限
  storage_type          = "gp2"

  # データベース・認証設定
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # ネットワーク・セキュリティ設定
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false

  # 高可用性設定（要件：Multi-AZ）
  multi_az = true

  # バックアップ・メンテナンス設定
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # CloudWatch Logsへのログエクスポート設定
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  # Destroy対応
  skip_final_snapshot = true
  apply_immediately   = true

  tags = {
    Name = "${var.project}-${var.environment}-db-mysql"
  }
}
