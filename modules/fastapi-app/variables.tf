variable "cluster_name" {
    description = "Name that identifies the cluster"
    type        = string
}

variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "us-west-2" 
}

variable "vpc_id" {
    description = "VPC ID"
    type        = string
}

variable "private_subnet_ids" {
    description = "List of private subnet IDs"
    type        = list(string)
}

variable "public_subnet_ids" {
    description = "List of public subnet IDs"
    type        = list(string)
}

variable "ecs_access_sg_id" {
    description = "ID of the security group that allows access to the ECS tasks"
    type        = string
}

variable "app_registry" {
    description = "Docker registry"
    type        = string
    default     = "example.com"
}

variable "backend_app_image" {
    description = "Docker image name"
    type = string
    default     = "acme-corp-2025-01/fastapi-app-example"
}

variable "backend_app_image_version" {
    description = "Docker image version"
    type = string
    default     = "latest"
}

variable "backend_app_port" {
    description = "Port exposed by the docker image"
    default     = 8000
}

variable "backend_app_instance_count" {
    description = "Number of instances to run"
    default     = 2
}

variable "common_tags" {
    description = "Tags to apply to all resources"
    type        = map(string)
    default     = {
        Owner       = "DevOps Team"
        Environment = "Production"
    } 
}

variable "deploy_services" {
    description = "Deploy the ECS services"
    type        = bool
    default     = true
}