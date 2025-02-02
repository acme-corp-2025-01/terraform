data "aws_iam_policy_document" "ecs_task_execution_role" {
    version = "2012-10-17"
    statement {
        sid     = ""
        effect  = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ecs-tasks.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "ecs_task_execution_role" {
    name               = "fastapi-ecs-task-execution-role"
    assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
    tags               = var.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_ecs" {
    role        = aws_iam_role.ecs_task_execution_role.name
    policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "fastapi_app_backend_container_role" {
    name = "fastapi_app_backend_container_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Effect = "Allow",
            Principal = {
            Service = "ecs-tasks.amazonaws.com"
            },
            Action = "sts:AssumeRole"
        }]
    })
    tags = var.common_tags
}


# =============================================================================
# Github Pusher
# =============================================================================

resource "aws_iam_policy" "github-pusher" {
    name = "github-ecr-pusher"
    description = "Allow pushing images to ECR from Github Actions"

    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
            Effect = "Allow",
            Action = [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage"
            ],
            Resource = [
                "arn:aws:ecr:*:*:repository/${var.backend_app_image}"
            ]
        },
        {
            Effect = "Allow",
            Action = [
                "ecr:GetAuthorizationToken"
            ],
            Resource = "*"
        }]
    })
}
