# ---------------------------------------------------------------------------
# Security groups — вся матрица разрешённого трафика в одном файле.
#
# Ключевой приём: правила ссылаются на ДРУГУЮ группу, а не на диапазон
# адресов. Правило «пускать на 3306 из группы ECS» продолжает работать при
# любом числе задач и любых их адресах и физически не может разрешить
# лишнего. Запись через CIDR потребовала бы либо знать адреса заранее,
# либо открыть всю подсеть.
#
# Цепочка получается такой:
#   мир -> ALB (80, 443) -> ECS (8080) -> Aurora (3306)
#                                      -> EFS (2049)
#
# Правила заведены отдельными ресурсами (aws_vpc_security_group_*_rule),
# а не блоками внутри aws_security_group. Так каждое правило видно в plan
# по отдельности, и добавление одного не переписывает остальные.
#
# ВНИМАНИЕ: поле description уходит в EC2 API, который принимает ТОЛЬКО
# ASCII. Кириллица здесь роняет apply с InvalidParameterValue, причём уже
# после создания половины ресурсов. Поэтому description — латиницей,
# а пояснения — в комментариях.
# ---------------------------------------------------------------------------

# --- ALB --------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb"
  description = "Load balancer: accepts HTTP and HTTPS from the internet"
  vpc_id      = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-alb" }

  # Пересоздание группы возможно только после того, как новая занята вместо
  # старой — иначе Terraform не сможет удалить ту, на которую ссылается ALB.
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

# --- Задачи ECS -------------------------------------------------------------
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

# Исходящий трафик открыт полностью. Сузить нечем: адреса ECR, CloudWatch
# Logs и Secrets Manager динамические и меняются без предупреждения,
# а префикс-листы AWS существуют только для S3 и DynamoDB.
# Ограничение делается на другом уровне — WordPress запрещено ходить
# наружу константой WP_HTTP_BLOCK_EXTERNAL.
resource "aws_vpc_security_group_egress_rule" "ecs_all" {
  security_group_id = aws_security_group.ecs.id
  description       = "Egress to AWS services (ECR, Logs, Secrets Manager) via NAT"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# --- Aurora -----------------------------------------------------------------
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

# Исходящих правил у базы нет намеренно: соединения инициирует клиент,
# сама Aurora никуда не ходит. Отсутствие правил = запрет всего исходящего.

# --- EFS --------------------------------------------------------------------
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
