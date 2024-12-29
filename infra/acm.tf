# ------------------------------
# Cloudflare Configuration
# ------------------------------

# Cloudflare DNSレコードの作成（アプリケーション用CNAME）
resource "cloudflare_record" "app" {
  zone_id = var.cloudflare_zone_id
  name    = replace(var.domain, ".${data.cloudflare_zone.main.name}", "")
  type    = "CNAME"
  content   = aws_lb.main.dns_name
  proxied = true
}

# ACM証明書の作成（DNS検証）
resource "aws_acm_certificate" "app_cert" {
  domain_name       = var.domain
  validation_method = "DNS"

  tags = merge(
    {
      Name = "${local.prefix}-app-cert"
    },
    local.common_tags
  )
}

# ACM証明書のDNS検証レコードをCloudflareに作成
resource "cloudflare_record" "app_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app_cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  type    = each.value.type
  content   = each.value.value
  ttl     = 60
  proxied = false  # 検証レコードはプロキシを無効化
}

# ACM証明書の検証
resource "aws_acm_certificate_validation" "app_cert_validation" {
  certificate_arn         = aws_acm_certificate.app_cert.arn
  validation_record_fqdns = [for record in cloudflare_record.app_cert_validation : record.hostname]
}

# Cloudflareゾーンデータソースの定義
data "cloudflare_zone" "main" {
  zone_id = var.cloudflare_zone_id
}
