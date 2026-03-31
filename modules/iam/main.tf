# EC2用IAMロール（AssumeRole信頼ポリシー）
resource "aws_iam_role" "ec2" {
  name = "${var.project}-${var.environment}-role-ec2"

  # EC2サービスがこのロールを引き受けることを許可
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project}-${var.environment}-role-ec2"
  }
}

# SSM Session Manager接続用のAWS管理ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Logs/Metrics出力用のAWS管理ポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# EC2にアタッチするためのインスタンスプロファイル（ロールの器）
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.environment}-profile-ec2"
  role = aws_iam_role.ec2.name

  tags = {
    Name = "${var.project}-${var.environment}-profile-ec2"
  }
}
