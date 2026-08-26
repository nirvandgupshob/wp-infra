resource "aws_efs_file_system" "this" {
  creation_token = var.name_prefix

  encrypted = true

  performance_mode = "generalPurpose"

  throughput_mode = "elastic"

  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = { Name = var.name_prefix }
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids
}

resource "aws_efs_access_point" "uploads" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = var.posix_uid
    gid = var.posix_gid
  }

  root_directory {
    path = var.root_directory

    creation_info {
      owner_uid   = var.posix_uid
      owner_gid   = var.posix_gid
      permissions = "0755"
    }
  }

  tags = { Name = "${var.name_prefix}-uploads" }
}

data "aws_iam_policy_document" "this" {
  count = var.enforce_tls ? 1 : 0

  statement {
    sid    = "AllowMountThroughMountTargets"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]

    resources = [aws_efs_file_system.this.arn]

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }
  }

  statement {
    sid    = "DenyUnencryptedTransport"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["*"]
    resources = [aws_efs_file_system.this.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  count = var.enforce_tls ? 1 : 0

  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.this[0].json

  bypass_policy_lockout_safety_check = false
}
