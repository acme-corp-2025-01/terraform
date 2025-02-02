resource "aws_ecs_cluster" "this" {
    name = var.cluster_name
    tags = var.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
    cluster_name = var.cluster_name
    capacity_providers = ["FARGATE", "FARGATE_SPOT"]
    default_capacity_provider_strategy {
        capacity_provider = "FARGATE"
        weight            = 1
    }
}

resource "aws_ecs_task_definition" "backend" {
    family                   = "${var.cluster_name}-backend"
    container_definitions    = jsonencode([
        {
        essential   = true
        name  = "${var.cluster_name}-backend"
        image = "${var.app_registry}/${var.backend_app_image}:${var.backend_app_image_version}"
        portMappings = [
            {
            containerPort = var.backend_app_port
            }
        ]
        logConfiguration = {
            logDriver = "awslogs"
            options = {
            awslogs-create-group  = "true"
            awslogs-group         = "/ecs/${var.cluster_name}-backend"
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "ecs"
            }
        }
        }
    ])
    requires_compatibilities = ["FARGATE"]
    cpu                      = "256"
    memory                   = "512"
    network_mode             = "awsvpc"
    task_role_arn = aws_iam_role.fastapi_app_backend_container_role.arn
    execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
    tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "name" {
    name              = "/ecs/${var.cluster_name}-backend"
    retention_in_days = 7
}

resource "aws_ecs_service" "backend" {
    count                             = var.deploy_services ? 1 : 0
    name                              = "backend"
    cluster                           = aws_ecs_cluster.this.arn
    task_definition                   = aws_ecs_task_definition.backend.arn
    desired_count                     = var.backend_app_instance_count
    enable_ecs_managed_tags           = true
    wait_for_steady_state             = true

    capacity_provider_strategy {
        capacity_provider = "FARGATE"
        weight            = 1
    }

    network_configuration {
        security_groups  = [aws_security_group.ecs_tasks.id, var.ecs_access_sg_id]
        subnets          = var.private_subnet_ids
        assign_public_ip = false
    }

    load_balancer {
        target_group_arn = aws_alb_target_group.fast-api-backend.id
        container_name   = "${var.cluster_name}-backend"
        container_port   = var.backend_app_port
    }

    tags = var.common_tags
}
