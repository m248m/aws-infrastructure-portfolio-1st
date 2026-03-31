variable "project" {
  description = "プロジェクト名（命名規則用）"
  type        = string
}

variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "private_db_subnet_ids" {
  description = "RDS用プライベートサブネットのID一覧（Multi-AZ要件で2つ以上必要）"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "RDS用セキュリティグループのID"
  type        = string
}

variable "db_name" {
  description = "データベース名"
  type        = string
}

variable "db_username" {
  description = "マスターユーザー名"
  type        = string
}

variable "db_password" {
  description = "マスターパスワード"
  type        = string
  sensitive   = true
}
