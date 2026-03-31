terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "network" {
  source = "../../modules/network"

  project                  = var.project
  environment              = var.environment
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

module "security" {
  source = "../../modules/security"

  project     = var.project
  environment = var.environment
  vpc_id      = module.network.vpc_id
}

# IAMロール・プロファイル（SSM, CloudWatch Logs用）
module "iam" {
  source = "../../modules/iam"

  project     = var.project
  environment = var.environment
}

# コンピュートリソース（ALB + AutoScaling + EC2）
module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment

  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_app_subnet_ids = module.network.private_app_subnet_ids

  alb_security_group_id     = module.security.alb_security_group_id
  ec2_security_group_id     = module.security.ec2_security_group_id
  ec2_instance_profile_name = module.iam.ec2_instance_profile_name

  # AutoScaling設定（要件：最小1、最大4）
  min_size = 2
  max_size = 4
}

# データベース（RDS Multi-AZ）
module "database" {
  source = "../../modules/database"
  
  project     = var.project
  environment = var.environment
  
  private_db_subnet_ids = module.network.private_db_subnet_ids
  db_security_group_id  = module.security.db_security_group_id
  
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}
