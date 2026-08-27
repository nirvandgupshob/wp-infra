output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "availability_zones" {
  description = "Availability zones in subnet order"
  value       = local.azs
}

output "public_subnet_ids" {
  description = "Load balancer subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Task subnets"
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "Database and EFS subnets"
  value       = aws_subnet.isolated[*].id
}

output "alb_security_group_id" {
  description = "Load balancer security group"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Task security group"
  value       = aws_security_group.ecs.id
}

output "db_security_group_id" {
  description = "Database security group"
  value       = aws_security_group.db.id
}

output "efs_security_group_id" {
  description = "EFS security group"
  value       = aws_security_group.efs.id
}

output "nat_public_ips" {
  description = "NAT public addresses"
  value       = aws_eip.nat[*].public_ip
}

output "flow_logs_log_group" {
  description = "VPC flow logs group"
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
