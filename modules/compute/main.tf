# 最新のAmazon Linux 2023 AMIを動的に取得
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#######################
# Application Load Balancer（インターネット接続層）
#######################
resource "aws_lb" "this" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  # 削除保護は開発環境では無効化
  enable_deletion_protection = false

  tags = {
    Name = "${var.project}-${var.environment}-alb"
  }
}

#######################
# Target Group（EC2へのルーティングとヘルスチェック）
#######################
resource "aws_lb_target_group" "app" {
  name     = "${var.project}-${var.environment}-tg-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # 詳細なヘルスチェック設定
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    path                = "/"
    matcher             = "200"
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  # インスタンス登録時の遅延を考慮
  deregistration_delay = 60

  tags = {
    Name = "${var.project}-${var.environment}-tg-app"
  }
}

#######################
# ALB Listener（HTTP通信の受信とルーティング）
#######################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

#######################
# Launch Template（EC2インスタンスの設計図）
#######################
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project}-${var.environment}-lt-app-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # IAMロールの適用（SSM・CloudWatch用）
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  # セキュリティグループの適用
  vpc_security_group_ids = [var.ec2_security_group_id]

  # IMDSv2対応 + CloudWatch Agent統合のUser Data
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -xe
    
    # システム更新とパッケージインストール
    dnf update -y
    dnf install -y httpd amazon-cloudwatch-agent
    systemctl start httpd
    systemctl enable httpd
    
    # IMDSv2トークンの取得（セキュリティ強化対応）
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    
    # トークンを使用してメタデータを取得
    INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
      -s http://169.254.169.254/latest/meta-data/instance-id)
    AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
      -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    
    # テストページの作成
    cat << EOL > /var/www/html/index.html
    <!DOCTYPE html>
    <html>
    <head>
        <title>Portfolio Infrastructure - ${var.environment}</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background-color: #333; color: #fff; }
            .container { max-width: 600px; margin: 0 auto; }
            .info { background: #444; padding: 20px; border-radius: 5px; border-left: 4px solid #0099cc; }
            .status { color: #0099cc; font-weight: bold; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Portfolio Infrastructure (${var.environment})</h1>
            <div class="info">
                <p><strong>Instance ID:</strong> <span class="status">$INSTANCE_ID</span></p>
                <p><strong>Availability Zone:</strong> <span class="status">$AVAILABILITY_ZONE</span></p>
                <p><strong>Environment:</strong> <span class="status">${var.environment}</span></p>
                <p><strong>Instance Type:</strong> <span class="status">t3.micro</span></p>
                <p>This page is served by an EC2 instance behind ALB and AutoScaling.</p>
                <p><em>Powered by Terraform IaC with comprehensive logging integration</em></p>
            </div>
        </div>
    </body>
    </html>
    EOL

    # CloudWatch Agent設定ファイル作成（Apacheアクセスログ転送用）
    cat << 'EOCW' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/httpd/access_log",
                "log_group_name": "/aws/ec2/${var.project}-${var.environment}/apache/access",
                "log_stream_name": "{instance_id}",
                "timezone": "Local",
                "timestamp_format": "%d/%b/%Y:%H:%M:%S %z"
              }
            ]
          }
        }
      }
    }
    EOCW

    # CloudWatch Agentの起動
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  EOF
  )


  # インスタンスに適用されるタグ
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-${var.environment}-ec2-app"
    }
  }

  # Launch Templateの更新時の動作制御
  lifecycle {
    create_before_destroy = true
  }
}

#######################
# Auto Scaling Group（Multi-AZ冗長化とインスタンス管理）
#######################
resource "aws_autoscaling_group" "app" {
  name                = "${var.project}-${var.environment}-asg-app"
  vpc_zone_identifier = var.private_app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.min_size

  health_check_type         = "ELB"
  health_check_grace_period = 120
  default_instance_warmup   = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.environment}-ec2-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

#######################
# Auto Scaling Policy（負荷に応じた自動スケール）
#######################
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project}-${var.environment}-asp-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
