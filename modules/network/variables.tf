variable "project" {
  description = "プロジェクト名（命名規則用）"
  type        = string
}

variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Multi-AZ配置用のAZリスト"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネットのCIDR（ALB用）"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "アプリ用プライベートサブネットのCIDR"
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "DB用プライベートサブネットのCIDR"
  type        = list(string)
}
