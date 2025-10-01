#<-- VPC -->
resource "aws_vpc" "microtodo_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "microtodo_vpc"
  }
}
#<-- END VPC -->



#<-- Subnets -->
resource "aws_subnet" "microtodo_public_subnets" {
  for_each = local.subnets.public

  vpc_id            = aws_vpc.microtodo_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${local.region}${each.key}"

  tags = {
    Name = each.value.name
    "kubernetes.io/cluster/microtodo_eks_cluster" = "shared"
    "kubernetes.io/role/elb"                       = "1"
  }
}

resource "aws_subnet" "microtodo_private_subnets" {
  for_each = local.subnets.private

  vpc_id            = aws_vpc.microtodo_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = "${local.region}${each.key}"

  tags = {
    Name = each.value.name
    "kubernetes.io/cluster/microtodo_eks_cluster"     = "shared"
    "kubernetes.io/role/internal-elb"                 = "1"
  }
}
#<-- END Subnets -->



#<-- Internet Gateway -->
resource "aws_internet_gateway" "microtodo_igw" {
  vpc_id = aws_vpc.microtodo_vpc.id
  tags = {
    Name = "microtodo_igw"
  }
}
#<-- END Internet Gateway -->



#<-- Elastic IP -->
resource "aws_eip" "microtodo_eip" {
  domain = "vpc"
  tags = {
    Name = "microtodo_eip"
  }
}
#<-- END Elastic IP -->



#<-- NAT Gateway -->
# In a serious production scenario, you should have a NAT Gateway in each AZ. 
# Then each private subnet should have a route to the NAT Gateway in its own AZ.
# This provides better HA and avoids cross-AZ traffic (can be quite expensive).
# But for the purposes of this example, we'll only have one NAT Gateway ($$$).
resource "aws_nat_gateway" "microtodo_nat_gateway" {
  allocation_id = aws_eip.microtodo_eip.id
  subnet_id     = aws_subnet.microtodo_public_subnets["a"].id

  depends_on = [aws_internet_gateway.microtodo_igw]
  tags = {
    Name = "microtodo_nat_gateway"
  }
}
#<-- END NAT Gateway -->



#<-- Private Route Table -->
resource "aws_route_table" "microtodo_private_route_table" {
  vpc_id = aws_vpc.microtodo_vpc.id

  tags = {
    Name = "microtodo_private_route_table"
  }
}

resource "aws_route" "microtodo_private_route" {
  route_table_id         = aws_route_table.microtodo_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.microtodo_nat_gateway.id
}

resource "aws_route_table_association" "microtodo_private_route_table_association" {
  for_each = local.subnets.private

  route_table_id = aws_route_table.microtodo_private_route_table.id
  subnet_id      = aws_subnet.microtodo_private_subnets[each.key].id
}
#<-- END Private Route Table -->



#<-- Public Route Table -->
resource "aws_route_table" "microtodo_public_route_table" {
  vpc_id = aws_vpc.microtodo_vpc.id

  tags = {
    Name = "microtodo_public_route_table"
  }
}

resource "aws_route" "microtodo_public_route" {
  route_table_id         = aws_route_table.microtodo_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.microtodo_igw.id
}

resource "aws_route_table_association" "microtodo_public_route_table_association" {
  for_each = local.subnets.public

  route_table_id = aws_route_table.microtodo_public_route_table.id
  subnet_id      = aws_subnet.microtodo_public_subnets[each.key].id
}
#<-- END Public Route Table -->
