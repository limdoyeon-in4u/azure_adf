variable "location" {
  default = "koreacentral"
}

variable "project" {
  default = "arar"  # accounts receivable
}

variable "environment" {
  default = "dev"
}

variable "sql_admin_login" {
  default = "sqladmin"
}

variable "sql_admin_password" {
  description = "Azure SQL 관리자 비밀번호"
  type        = string
  sensitive   = true
}

variable "my_ip" {
  description = "로컬 개발 IP (SQL 방화벽 허용)"
  type        = string
  default     = ""
}
