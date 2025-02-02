resource "aws_vpc" "this" {
    cidr_block = local.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = local.project_name
    }
}

resource "aws_subnet" "public" {
    count             = length(local.azs)
    vpc_id            = aws_vpc.this.id
    cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index)
    availability_zone = local.azs[count.index]
    map_public_ip_on_launch = false
    tags = {
        Name = "public-${local.azs[count.index]}"
    }
}

resource "aws_subnet" "private" {
    count             = length(local.azs)
    vpc_id            = aws_vpc.this.id
    cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index + 3)
    availability_zone = local.azs[count.index]
    tags = {
        Name = "private-${local.azs[count.index]}"
    }
}

resource "aws_internet_gateway" "this" {
    vpc_id = aws_vpc.this.id
    tags = {
        Name = "igw-${local.project_name}"
    }
}

resource "aws_eip" "nat_eip" {
    depends_on = [aws_internet_gateway.this]
    tags = {
        Name = "nat-eip-${local.project_name}"
    }
}


resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id
    route {
        cidr_block     = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.this.id
    }
    tags = {
        Name = "public-${local.project_name}"
    }
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.this.id
    tags = {
        Name = "private-${local.project_name}"
    }
}

resource "aws_route_table_association" "public" {
    count          = length(local.azs)
    subnet_id      = element(aws_subnet.public.*.id, count.index)
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    count          = length(local.azs)
    subnet_id      = element(aws_subnet.private.*.id, count.index)
    route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "vpc_endpoint_ecs_sg" {
    name        = "allow-ecs-vpc-endpoint"
    description = "Allow ECS VPC Endpoint access within the VPC"
    vpc_id = aws_vpc.this.id
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = true
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_vpc_endpoint" "ecr-api" {
    vpc_id = aws_vpc.this.id
    service_name = "com.amazonaws.${local.aws_region}.ecr.api"
    subnet_ids = aws_subnet.private[*].id
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    security_group_ids = [aws_security_group.vpc_endpoint_ecs_sg.id]
    tags = {
        Name = "${local.project_name}-ecr-api-vpc-endpoint"
    }
}

resource "aws_vpc_endpoint" "ecr-dkr" {
    vpc_id = aws_vpc.this.id
    service_name = "com.amazonaws.${local.aws_region}.ecr.dkr"
    subnet_ids = aws_subnet.private[*].id
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    security_group_ids = [aws_security_group.vpc_endpoint_ecs_sg.id]
    tags = {
        Name = "${local.project_name}-ecr-dkr-vpc-endpoint"
    }
}

resource "aws_vpc_endpoint" "logs-api" {
    vpc_id = aws_vpc.this.id
    service_name = "com.amazonaws.${local.aws_region}.logs"
    subnet_ids = aws_subnet.private[*].id
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    security_group_ids = [aws_security_group.vpc_endpoint_ecs_sg.id]
    tags = {
        Name = "${local.project_name}-logs-vpc-endpoint"
    }
}

resource "aws_vpc_endpoint" "secretsmanager" {
    vpc_id = aws_vpc.this.id
    service_name = "com.amazonaws.${local.aws_region}.secretsmanager"
    subnet_ids = aws_subnet.private[*].id
    vpc_endpoint_type = "Interface"
    private_dns_enabled = true
    security_group_ids = [aws_security_group.vpc_endpoint_ecs_sg.id]
    tags = {
        Name = "${local.project_name}-secretsmanager-vpc-endpoint"
    }
  
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id = aws_vpc.this.id
    service_name = "com.amazonaws.${local.aws_region}.s3"
    route_table_ids = aws_route_table.private[*].id
    tags = {
        Name = "${local.project_name}-s3-vpc-endpoint"
    }
}