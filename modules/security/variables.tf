variable "project" {
  description = "プロジェクト名（命名規則用）"
  type        = string
}

variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "vpc_id" {
  description = "セキュリティグループを作成するVPCのID"
  type        = string
}
