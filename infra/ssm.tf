# ------------------------------
# SSM Parameters
# ------------------------------

# データベース接続情報
resource "aws_ssm_parameter" "db_engine" {
  name        = "/${local.prefix}/DB_ENGINE"
  description = "Database engine type"
  type        = "SecureString"
  value       = var.db_engine
  tier        = "Standard"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_host" {
  name        = "/${local.prefix}/DB_HOST"
  description = "Database host address"
  type        = "SecureString"
  value       = aws_db_instance.main.address
  tier        = "Standard"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/${local.prefix}/DB_PORT"
  description = "Database port number"
  type        = "SecureString"
  value       = var.db_port
  tier        = "Standard"

  tags = local.common_tags
}

# Django設定
resource "aws_ssm_parameter" "secret_key" {
  name        = "/${local.prefix}/SECRET_KEY"
  description = "Django secret key for cryptographic signing"
  type        = "SecureString"
  value       = var.secret_key
  tier        = "Standard"

  tags = local.common_tags
}

# データベース認証情報
resource "aws_ssm_parameter" "db_name" {
  name        = "/${local.prefix}/DB_NAME"
  description = "Database name"
  type        = "SecureString"
  value       = var.db_name
  tier        = "Standard"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_user" {
  name        = "/${local.prefix}/DB_USER"
  description = "Database username"
  type        = "SecureString"
  value       = var.db_username
  tier        = "Standard"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${local.prefix}/DB_PASSWORD"
  description = "Database password"
  type        = "SecureString"
  value       = var.db_password
  tier        = "Standard"

  tags = local.common_tags

  lifecycle {
    ignore_changes = [value]  # パスワードの手動更新を許可
  }
}

# Django セキュリティ設定
resource "aws_ssm_parameter" "django_allowed_hosts" {
  name        = "/${local.prefix}/DJANGO_ALLOWED_HOSTS"
  description = "Django allowed hosts configuration"
  type        = "SecureString"
  value       = var.django_allowed_hosts
  tier        = "Standard"

  tags = local.common_tags
}

resource "aws_ssm_parameter" "csrf_trusted_ports" {
  name        = "/${local.prefix}/CSRF_TRUSTED_PORTS"
  description = "Django CSRF trusted ports"
  type        = "SecureString"
  value       = var.csrf_trusted_ports
  tier        = "Standard"

  tags = local.common_tags
}