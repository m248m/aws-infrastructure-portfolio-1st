#######################
# ALB用セキュリティグループ（インターネット接続層）
#######################
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-sg-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # インターネットからのHTTP(80)アクセスを許可
  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 全てのアウトバウンド通信を許可（ターゲットへの転送用）
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-sg-alb"
  }
}

#######################
# EC2(App)用セキュリティグループ（アプリケーション層）
#######################
resource "aws_security_group" "app" {
  name        = "${var.project}-${var.environment}-sg-app"
  description = "Security group for App EC2 instances"
  vpc_id      = var.vpc_id

  # ALBからのHTTP(80)アクセスのみ許可（セキュリティグループ参照）
  ingress {
    description     = "Allow HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # SSM Manager接続・パッケージダウンロード用にアウトバウンドは全許可
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-sg-app"
  }
}

#######################
# RDS(DB)用セキュリティグループ（データベース層）
#######################
resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-sg-db"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  # EC2(App)からのMySQL(3306)アクセスのみ許可
  ingress {
    description     = "Allow MySQL access from App EC2 only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # データベースからのアウトバウンド通信（レプリケーション等）
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-sg-db"
  }
}
