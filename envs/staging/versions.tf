terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.61"
    }
  }

  # State окружения лежит отдельным объектом. Ошибка здесь не может задеть
  # production: это физически другой файл, и роль CI для staging получит
  # доступ только к своему префиксу.
  backend "s3" {
    bucket       = "wp-tfstate-756250138234"
    key          = "staging/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:eu-central-1:756250138234:key/8d2b267a-4781-4560-81b9-e78591e3ec36"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  # Навешивается на все ресурсы, поддерживающие теги. По этим тегам потом
  # разбирается счёт AWS и находятся забытые ресурсы.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "wp-infra"
    }
  }
}
