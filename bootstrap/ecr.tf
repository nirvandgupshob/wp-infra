resource "aws_ecr_repository" "wordpress" {
  name = "${var.project}/wordpress"

  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${var.project}-wordpress" }
}

resource "aws_ecr_lifecycle_policy" "wordpress" {
  repository = aws_ecr_repository.wordpress.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged build leftovers after a week"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the last 20 tagged images for rollback"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = { type = "expire" }
      },
    ]
  })
}
