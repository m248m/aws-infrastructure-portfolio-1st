output "ec2_instance_profile_name" {
  description = "EC2インスタンスプロファイルの名前（Computeモジュールで使用）"
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_role_name" {
  description = "EC2用IAMロール名（参照用）"
  value       = aws_iam_role.ec2.name
}
