# EXPLANATION: Create the customer managed-vpc and security group rules

# Data source for S3 Prefix List
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.region}.s3"
}

# VPC and other assets - skipped entirely in custom mode, some assets skipped for firewall and isolated
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"
  count   = var.network_configuration != "custom" ? 1 : 0

  name = "${var.resource_prefix}-classic-compute-plane-vpc"
  cidr = var.vpc_cidr_range
  azs  = data.aws_availability_zones.available.names

  enable_dns_hostnames   = true
  enable_nat_gateway     = (var.enable_controlled_egress || var.enable_internet_gateway || var.enable_nat_gateway) ? true : false
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = (var.enable_controlled_egress || var.enable_internet_gateway || var.enable_nat_gateway) ? (!var.single_nat_gateway) : false
  create_igw             = (var.enable_controlled_egress || var.enable_internet_gateway || var.enable_nat_gateway) ? true : false

  private_subnet_names = [for az in data.aws_availability_zones.available.names : format("%s-private-%s", var.resource_prefix, az)]
  private_subnets      = var.private_subnets_cidr

  public_subnet_names = (var.enable_controlled_egress || var.enable_internet_gateway || var.enable_nat_gateway) ? [for az in data.aws_availability_zones.available.names : format("%s-public-%s", var.resource_prefix, az)] : []
  public_subnets      = (var.enable_controlled_egress || var.enable_internet_gateway || var.enable_nat_gateway) ? var.public_subnets_cidr : []

  intra_subnet_names = [for az in data.aws_availability_zones.available.names : format("%s-privatelink-%s", var.resource_prefix, az)]
  intra_subnets      = var.privatelink_subnets_cidr

  tags = {
    Project = var.resource_prefix
  }
}

# Optional VPC Flow Logs (only when VPC is created here)
resource "aws_iam_role" "vpc_flow_logs" {
  count = var.network_configuration != "custom" && local.effective_enable_vpc_flow_logs ? 1 : 0
  name  = "${var.resource_prefix}-vpc-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.network_configuration != "custom" && local.effective_enable_vpc_flow_logs ? 1 : 0
  name  = "${var.resource_prefix}-vpc-flow-logs-policy"
  role  = aws_iam_role.vpc_flow_logs[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogGroups", "logs:DescribeLogStreams"],
      Resource = "*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.network_configuration != "custom" && local.effective_enable_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc/flow-logs/${var.resource_prefix}"
  retention_in_days = 90
}

resource "aws_flow_log" "vpc" {
  count                = var.network_configuration != "custom" && local.effective_enable_vpc_flow_logs ? 1 : 0
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  iam_role_arn         = aws_iam_role.vpc_flow_logs[0].arn
  traffic_type         = "ALL"
  vpc_id               = module.vpc[0].vpc_id
}


# Security group - skipped in custom mode
resource "aws_security_group" "sg" {
  count  = var.network_configuration != "custom" ? 1 : 0
  name   = "${var.resource_prefix}-workspace-sg"
  vpc_id = module.vpc[0].vpc_id


  dynamic "ingress" {
    for_each = ["tcp", "udp"]
    content {
      description = "Databricks - Workspace SG - Internode Communication"
      from_port   = 0
      to_port     = 65535
      protocol    = ingress.value
      self        = true
    }
  }

  dynamic "egress" {
    for_each = ["tcp", "udp"]
    content {
      description = "Databricks - Workspace SG - Internode Communication"
      from_port   = 0
      to_port     = 65535
      protocol    = egress.value
      self        = true
    }
  }

  dynamic "egress" {
    for_each = var.databricks_gov_shard == "civilian" || var.databricks_gov_shard == "dod" ? [for port in var.sg_egress_ports : port if port != 6666] : var.sg_egress_ports
    content {
      description = "Databricks - Workspace SG - REST (443), Secure Cluster Connectivity (2443/6666), Lakebase PostgreSQL (5432), Compute Plane to Control Plane Internal Calls (8443), Unity Catalog Logging and Lineage Data Streaming (8444), Future Extendability (8445-8451)"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr_range]
    }
  }

  dynamic "egress" {
    for_each = var.network_configuration != "custom" ? [1] : []
    content {
      description     = "S3 Gateway Endpoint - SG"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      prefix_list_ids = [data.aws_prefix_list.s3.id]
    }
  }

  # Optional internet egress rules (when IGW/NAT enabled)
  dynamic "egress" {
    for_each = (var.enable_controlled_egress || var.enable_internet_gateway || var.enable_nat_gateway) && length(var.allowed_outbound_tcp_ports) > 0 && length(var.allowed_outbound_cidrs) > 0 ? toset(var.allowed_outbound_tcp_ports) : []
    content {
      description = "Internet egress TCP"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_outbound_cidrs
    }
  }

  dynamic "egress" {
    for_each = (var.enable_controlled_egress || var.enable_internet_gateway || var.enable_nat_gateway) && length(var.allowed_outbound_udp_ports) > 0 && length(var.allowed_outbound_cidrs) > 0 ? toset(var.allowed_outbound_udp_ports) : []
    content {
      description = "Internet egress UDP"
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "udp"
      cidr_blocks = var.allowed_outbound_cidrs
    }
  }

  tags = {
    Name    = "${var.resource_prefix}-workspace-sg"
    Project = var.resource_prefix
  }
  depends_on = [module.vpc]
}