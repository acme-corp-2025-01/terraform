resource "aws_security_group" "ecs_tasks" {
    name        = "fastapi-backend"
    description = "allow inbound access from the ALB only"
    vpc_id      = var.vpc_id

    ingress {
        protocol        = "tcp"
        from_port       = var.backend_app_port
        to_port         = var.backend_app_port
        # security_groups = [data.aws_security_group.backend.id]
        self = true
    }

    egress {
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = var.common_tags
}

resource "aws_security_group" "alb" {
    name        = "fastapi-alb"
    description = "allow inbound access from the ALB only"
    vpc_id      = var.vpc_id

    ingress {
        protocol        = "tcp"
        from_port       = 80
        to_port         = 80
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_alb" "fast-api-backend" {
    name                             = var.cluster_name
    internal                         = false
    subnets                          = var.public_subnet_ids
    security_groups                  = [aws_security_group.ecs_tasks.id, aws_security_group.alb.id]
    enable_cross_zone_load_balancing = true
    tags                             = var.common_tags

    lifecycle {
        ignore_changes = [access_logs]
    }
}

resource "aws_alb_target_group" "fast-api-backend" {
    name     = "backend"
    port     = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id   = var.vpc_id
    tags = var.common_tags
}

resource "aws_alb_listener" "internal" {
    load_balancer_arn = aws_alb.fast-api-backend.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_alb_target_group.fast-api-backend.arn
    }
}
