variable "project" {
  description = "プロジェクト名（命名規則用）"
  type        = string
}

variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "vpc_id" {
  description = "Target Group作成用のVPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALBを配置するPublic SubnetのID一覧"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "EC2を配置するPrivate App SubnetのID一覧（Multi-AZ）"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB用セキュリティグループID"
  type        = string
}

variable "ec2_security_group_id" {
  description = "EC2(App)用セキュリティグループID"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "EC2にアタッチするIAMインスタンスプロファイル名"
  type        = string
}

variable "min_size" {
  description = "AutoScaling Group の最小インスタンス数"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "AutoScaling Group の最大インスタンス数"
  type        = number
  default     = 4
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
}

