# ------------------------------
# CloudWatch Logs Configuration
# ------------------------------

# CloudWatchロググループの設定をマップで定義
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.prefix}/app"
  retention_in_days = 30

  tags = merge(
    {
      Name = "${local.prefix}-app-logs"
    },
    local.common_tags
  )
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${local.prefix}/nginx"
  retention_in_days = 30

  tags = merge(
    {
      Name = "${local.prefix}-nginx-logs"
    },
    local.common_tags
  )
}