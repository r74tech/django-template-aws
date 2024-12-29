# ------------------------------
# Terraform configuration
# ------------------------------
terraform {
  # tfstateファイルをS3で管理し、状態ファイルの同時実行を防ぐためにDynamoDBを使用
  backend "s3" {
    bucket         = "terraform-playground-for-cicd-test"
    key            = "terrafrom-playground.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-playground-tf-test-state-lock"
  }

  # AWS・Cloudflareプロバイダーの設定
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  # Terraformのバージョン指定
  required_version = ">= 1.10, < 2.0"
}

# ------------------------------
# Provider
# ------------------------------
provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ------------------------------
# Data Sources
# ------------------------------
# 現在のリージョン情報の取得
data "aws_region" "current" {}

# 現在のAWSアカウント情報の取得
data "aws_caller_identity" "current" {}