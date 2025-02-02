data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {

}


terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 4.16"
        }
    }

    backend "s3" {
        bucket = "acme-corp-terraform-state-prod" 
        key    = "current.tfstate"
        region = "us-west-2"
    }

    required_version = ">= 1.10.0"
}

locals {
    common_tags = {
        Owner       = "DevOps Team"
        Environment = "Production"
    }

    aws_region = "us-west-2"
    aws_account_id = data.aws_caller_identity.current.account_id
    project_name = "fastapi-app-example"
    vpc_cidr = "10.0.0.0/16"
    azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}


################################################################################
# FastAPI cluster
################################################################################

module "fastapi-app-cluster" {
    source = "./modules/fastapi-app"

    deploy_services = false

    app_registry = "${local.aws_account_id}.dkr.ecr.${local.aws_region}.amazonaws.com"

    backend_app_image = "acme-corp-2025-01/fastapi-app-example"
    backend_app_image_version = "20250202031130"

    cluster_name = local.project_name
    common_tags = local.common_tags

    aws_region = local.aws_region
    vpc_id = aws_vpc.this.id
    ecs_access_sg_id = aws_security_group.vpc_endpoint_ecs_sg.id
    public_subnet_ids = aws_subnet.public[*].id
    private_subnet_ids = aws_subnet.private[*].id
}
