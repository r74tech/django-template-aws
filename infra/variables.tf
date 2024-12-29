# ------------------------------
# Variables
# ------------------------------

# プロジェクト基本情報
variable "prefix" {
  description = "Prefix for resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.prefix))
    error_message = "Prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be in the format: xx-xxxx-#"
  }
}

# データベース設定
variable "db_username" {
  description = "Username for RDS PostgreSQL Instance"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_username) >= 3 && length(var.db_username) <= 63
    error_message = "Database username must be between 3 and 63 characters."
  }
}

variable "db_password" {
  description = "Password for RDS PostgreSQL Instance"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters."
  }
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "app"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "database" {
  description = "Database type"
  type        = string
  default     = "postgres"
  validation {
    condition     = contains(["postgres", "mysql"], var.database)
    error_message = "Database type must be either 'postgres' or 'mysql'."
  }
}

variable "db_engine" {
  description = "Database engine"
  type        = string
}

# Djangoアプリケーション設定
variable "django_settings_module" {
  description = "Django settings module path"
  type        = string
  default     = "app.settings"
}

variable "secret_key" {
  description = "Django secret key"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.secret_key) >= 32
    error_message = "Secret key must be at least 32 characters long for security."
  }
}

variable "app_debug" {
  description = "Django debug mode"
  type        = bool
  default     = false
}

variable "django_allowed_hosts" {
  description = "Django ALLOWED_HOSTS setting"
  type        = string
  validation {
    condition     = length(var.django_allowed_hosts) > 0
    error_message = "ALLOWED_HOSTS cannot be empty."
  }
}

variable "csrf_trusted_ports" {
  description = "Django CSRF_TRUSTED_PORTS setting (space-separated list of ports)"
  type        = string
  default     = "443 80"
  validation {
    # スペース区切りの数字のみを許可
    condition     = can(regex("^[0-9]+(\\s+[0-9]+)*$", var.csrf_trusted_ports))
    error_message = "csrf_trusted_ports must be a space-separated list of port numbers (e.g., '443 80')"
  }
}

# コンテナイメージ設定
variable "ecr_image_app" {
  description = "ECR Image URI for Django App"
  type        = string
  validation {
    condition = can(regex(
      "^\\d+\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/[a-zA-Z0-9._-]+(?:/[a-zA-Z0-9._-]+)*:[a-zA-Z0-9._-]+$",
      var.ecr_image_app
    ))
    error_message = "ECR image URI must be in the correct format."
  }
}

variable "ecr_image_web" {
  description = "ECR Image URI for Nginx"
  type        = string
  validation {
    condition = can(regex(
      "^\\d+\\.dkr\\.ecr\\.[a-z0-9-]+\\.amazonaws\\.com/[a-zA-Z0-9._-]+(?:/[a-zA-Z0-9._-]+)*:[a-zA-Z0-9._-]+$",
      var.ecr_image_web
    ))
    error_message = "ECR image URI must be in the correct format."
  }

}

# IAMロール設定
variable "execution_role_arn" {
  description = "ECS Task Execution Role ARN"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::\\d{12}:role/.+$", var.execution_role_arn))
    error_message = "Invalid execution role ARN format."
  }
}

variable "task_role_arn" {
  description = "ECS Task Role ARN"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::\\d{12}:role/.+$", var.task_role_arn))
    error_message = "Invalid task role ARN format."
  }
}

# Cloudflare設定
variable "domain" {
  description = "The domain name for ACM certificate"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-\\.]{1,61}[a-z0-9]\\.[a-z]{2,}$", var.domain))
    error_message = "Invalid domain name format."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}