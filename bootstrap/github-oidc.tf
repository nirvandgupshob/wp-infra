locals {
  github_owner = "${var.github_owner.name}@${var.github_owner.id}"
  infra_repo   = "repo:${local.github_owner}/${var.infra_repository.name}@${var.infra_repository.id}"
  app_repo     = "repo:${local.github_owner}/${var.app_repository.name}@${var.app_repository.id}"

  github_subjects = {
    terraform-plan = {
      subjects = ["${local.infra_repo}:pull_request", "${local.infra_repo}:ref:refs/heads/main"]
      apply    = false
    }
    terraform-apply-staging = {
      subjects = ["${local.infra_repo}:environment:staging"]
      apply    = true
    }
    terraform-apply-production = {
      subjects = ["${local.infra_repo}:environment:production"]
      apply    = true
    }
  }

  github_deploy_roles = {
    deploy-staging    = ["${local.app_repo}:environment:staging"]
    deploy-production = ["${local.app_repo}:environment:production"]
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []

  tags = { Name = "${var.project}-github" }
}

data "aws_iam_policy_document" "github_assume" {
  for_each = merge(
    { for k, v in local.github_subjects : k => v.subjects },
    local.github_deploy_roles,
  )

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}

resource "aws_iam_role" "github" {
  for_each = data.aws_iam_policy_document.github_assume

  name                 = "${var.project}-gh-${each.key}"
  assume_role_policy   = each.value.json
  max_session_duration = 3600

  tags = { Name = "${var.project}-gh-${each.key}" }
}

resource "aws_iam_role_policy_attachment" "terraform_plan_readonly" {
  role       = aws_iam_role.github["terraform-plan"].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_apply_poweruser" {
  for_each = toset([for k, v in local.github_subjects : k if v.apply])

  role       = aws_iam_role.github[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "terraform_apply_iam" {
  statement {
    sid    = "ManageProjectRoles"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:PassRole",
    ]

    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-*"]
  }

  statement {
    sid       = "ReadStateEncryptionKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.tfstate.arn]
  }
}

resource "aws_iam_role_policy" "terraform_apply_iam" {
  for_each = toset([for k, v in local.github_subjects : k if v.apply])

  name   = "manage-project-iam"
  role   = aws_iam_role.github[each.key].id
  policy = data.aws_iam_policy_document.terraform_apply_iam.json
}

data "aws_iam_policy_document" "terraform_plan_state" {
  statement {
    sid       = "ReadStateEncryptionKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.tfstate.arn]
  }
}

resource "aws_iam_role_policy" "terraform_plan_state" {
  name   = "read-state"
  role   = aws_iam_role.github["terraform-plan"].id
  policy = data.aws_iam_policy_document.terraform_plan_state.json
}

data "aws_iam_policy_document" "app_deploy" {
  statement {
    sid       = "GetRegistryToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "PushAndPullImages"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]

    resources = [aws_ecr_repository.wordpress.arn]
  }

  statement {
    sid    = "DeployService"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:DescribeTasks",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:RunTask",
      "ecs:UpdateService",
    ]

    resources = ["*"]
  }

  statement {
    sid       = "PassTaskRoles"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid       = "ReadEnvironmentOutputs"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/*"]
  }

  statement {
    sid       = "DecryptState"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.tfstate.arn]
  }

  statement {
    sid       = "ReadLogs"
    effect    = "Allow"
    actions   = ["logs:GetLogEvents", "logs:FilterLogEvents", "logs:DescribeLogStreams"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "app_deploy" {
  for_each = local.github_deploy_roles

  name   = "deploy-wordpress"
  role   = aws_iam_role.github[each.key].id
  policy = data.aws_iam_policy_document.app_deploy.json
}
