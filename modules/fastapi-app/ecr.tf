resource "aws_ecr_repository" "backend" {
    name = var.backend_app_image
    image_tag_mutability = "IMMUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }
}

resource "aws_ecr_lifecycle_policy" "backend" {
    repository = aws_ecr_repository.backend.name
    policy = jsonencode({
        rules = [
        {
            rulePriority = 1,
            description  = "Expire images older than 14 days",
            selection    = {
                tagStatus = "untagged",
                countType = "sinceImagePushed",
                countUnit = "days",
                countNumber = 14
            },
            action = {
                type = "expire"
            }
        }
        ]
    })
}