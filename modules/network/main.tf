# ---------------------------------------------------------------------------
# Сеть: VPC, три яруса подсетей, маршрутизация, S3-эндпоинт, flow logs.
#
# Ярусы различаются ровно тем, какой у них маршрут по умолчанию:
#   public   -> Internet Gateway   (вход и выход) — только ALB и NAT
#   private  -> NAT Gateway        (только выход) — задачи ECS
#   isolated -> маршрута наружу нет                — Aurora и EFS
#
# То есть изоляция базы обеспечена не только security group, но и самим
# отсутствием маршрута: даже ошибочно выданный публичный адрес не сделает
# её достижимой.
# ---------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"

  # Зоны, требующие явного включения в аккаунте, отсеиваем: обращение
  # к ним упало бы уже на этапе создания подсети.
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_region" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Раскладка /24 внутри /16. Индексы разнесены по десяткам, чтобы ярус
  # читался прямо из адреса: 10.0.0.x — public, 10.0.1x.x — private,
  # 10.0.2x.x — isolated. Диагностировать по логам заметно легче.
  public_subnets   = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 10 + i)]
  isolated_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, 20 + i)]

  nat_count = var.single_nat_gateway ? 1 : var.az_count
}

# --- VPC --------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # Нужны обе опции: без них не резолвятся приватные DNS-имена сервисов AWS
  # и эндпоинт Aurora.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name_prefix }
}

# --- Подсети ----------------------------------------------------------------
resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.public_subnets[count.index]
  availability_zone = local.azs[count.index]

  # Автоматический публичный адрес не нужен: у ALB свои адреса,
  # у NAT — явный Elastic IP. Ничего другого сюда не попадает.
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.name_prefix}-private-${local.azs[count.index]}"
    Tier = "private"
  }
}

resource "aws_subnet" "isolated" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.isolated_subnets[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.name_prefix}-isolated-${local.azs[count.index]}"
    Tier = "isolated"
  }
}

# --- Выход в интернет -------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = var.name_prefix }
}

resource "aws_eip" "nat" {
  count = local.nat_count

  domain = "vpc"

  tags = { Name = "${var.name_prefix}-nat-${count.index}" }

  # EIP бесполезен, пока не создан IGW: NAT без него не заработает.
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "${var.name_prefix}-${local.azs[count.index]}" }

  depends_on = [aws_internet_gateway.this]
}

# --- Маршрутизация ----------------------------------------------------------
# Public: одна таблица на все зоны — маршрут в IGW везде одинаковый.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-public" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private: таблица на каждую зону, даже когда NAT один.
# Так переключение single_nat_gateway в false меняет только адресата
# маршрута, а не структуру ресурсов — то есть не пересоздаёт подсети.
resource "aws_route_table" "private" {
  count = var.az_count

  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-private-${local.azs[count.index]}" }
}

resource "aws_route" "private_default" {
  count = var.az_count

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  # При одном NAT все зоны ходят через него; при NAT на зону — каждая через свой.
  nat_gateway_id = aws_nat_gateway.this[var.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private" {
  count = var.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Isolated: таблица без маршрута по умолчанию. Работает только local-маршрут
# внутри VPC, который AWS добавляет сам. Это и есть изоляция.
resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.name_prefix}-isolated" }
}

resource "aws_route_table_association" "isolated" {
  count = var.az_count

  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}

# --- S3 gateway endpoint ----------------------------------------------------
# Бесплатен и берётся всегда: слои образов ECR лежат в S3, и это основной
# объём исходящего трафика задач. Через эндпоинт он идёт по внутренней сети
# AWS, минуя NAT — то есть не тарифицируется как обработка трафика.
#
# Это gateway-эндпоинт: он не создаёт сетевых интерфейсов и не стоит денег,
# в отличие от интерфейсных эндпоинтов для ECR/Logs/Secrets Manager.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    aws_route_table.private[*].id,
    [aws_route_table.isolated.id],
  )

  tags = { Name = "${var.name_prefix}-s3" }
}

# --- Flow logs --------------------------------------------------------------
# Журнал разрешённых и отброшенных соединений. Без него на вопрос «почему
# задача не достучалась до базы» отвечать нечем: security group молча
# отбрасывает пакет, приложение видит только таймаут.
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.name_prefix}/flow-logs"
  retention_in_days = var.flow_logs_retention_days

  tags = { Name = "${var.name_prefix}-flow-logs" }
}

data "aws_iam_policy_document" "flow_logs_assume" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]

    # Права ограничены одной конкретной группой логов, а не всеми.
    resources = ["${aws_cloudwatch_log_group.flow_logs[0].arn}:*"]
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name               = "${var.name_prefix}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume[0].json
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name   = "write-flow-logs"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs[0].json
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = { Name = var.name_prefix }
}
