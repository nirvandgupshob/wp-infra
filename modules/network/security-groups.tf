resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb"
  description = "Load balancer: accepts HTTP and HTTPS from the internet"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-alb" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from internet, answers with redirect to HTTPS"

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from internet"

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id = aws_security_group.alb.id
  description       = "To ECS tasks on container port only, nowhere else"

  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group" "ecs" {
  name        = "${var.name_prefix}-ecs"
  description = "WordPress tasks: traffic from the load balancer only"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-ecs" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id = aws_security_group.ecs.id
  description       = "From load balancer security group only"

  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs.id
  description       = "Egress to AWS services (ECR, Logs, Secrets Manager) via NAT"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_security_group" "db" {
  name        = "${var.name_prefix}-db"
  description = "Aurora: connections from ECS tasks only"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-db" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_ecs" {
  security_group_id = aws_security_group.db.id
  description       = "MySQL from ECS tasks security group"

  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.ecs.id
}

resource "aws_security_group" "efs" {
  name        = "${var.name_prefix}-efs"
  description = "EFS: mount targets reachable from ECS tasks only"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-efs" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_ecs" {
  security_group_id = aws_security_group.efs.id
  description       = "NFS from ECS tasks security group"

  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.ecs.id
}
