terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.61"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  backend "s3" {
    bucket       = "wp-tfstate-756250138234"
    key          = "production/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    kms_key_id   = "arn:aws:kms:eu-central-1:756250138234:key/8d2b267a-4781-4560-81b9-e78591e3ec36"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "wp-infra"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "wp-infra"
    }
  }
}
