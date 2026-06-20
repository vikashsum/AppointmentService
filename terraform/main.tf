terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
  }
}

provider "aws" {
  region                  = var.aws_region
  access_key              = var.aws_access_key
  secret_key              = var.aws_secret_key
  shared_credentials_file = [var.aws_shared_credentials_file]
  profile                 = var.aws_profile
}

provider "kubernetes" {
  host                   = aws_eks_cluster.app.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.app.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.app.token
}

resource "aws_vpc" "eks" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "appointmentservice-eks-vpc"
  }
}

resource "aws_subnet" "eks" {
  count                   = 2
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = cidrsubnet(aws_vpc.eks.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "appointmentservice-eks-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id
  tags = {
    Name = "appointmentservice-eks-igw"
  }
}

resource "aws_route_table" "eks" {
  vpc_id = aws_vpc.eks.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }
  tags = {
    Name = "appointmentservice-eks-rt"
  }
}

resource "aws_route_table_association" "eks" {
  count          = length(aws_subnet.eks)
  subnet_id      = aws_subnet.eks[count.index].id
  route_table_id = aws_route_table.eks.id
}

resource "aws_security_group" "eks_cluster" {
  name        = "appointmentservice-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.eks.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "appointmentservice-eks-cluster-sg"
  }
}

resource "aws_eks_cluster" "app" {
  name     = "appointmentservice-eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids         = aws_subnet.eks[*].id
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy]

  tags = {
    Name = "appointmentservice-eks-cluster"
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = "appointmentservice-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role" "worker_node" {
  name = "appointmentservice-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_worker_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "worker_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.worker_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "worker_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.worker_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "worker_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.worker_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_policy" "worker_custom" {
  name        = "appointmentservice-eks-worker-custom-policy"
  description = "Additional permissions for EKS worker nodes"
  policy      = data.aws_iam_policy_document.worker_node_policy.json
}

resource "aws_iam_role_policy_attachment" "worker_custom_policy_attachment" {
  role       = aws_iam_role.worker_node.name
  policy_arn = aws_iam_policy.worker_custom.arn
}

data "aws_iam_policy_document" "worker_node_policy" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeRouteTables"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy_document" "eks_worker_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_eks_node_group" "app_nodes" {
  cluster_name    = aws_eks_cluster.app.name
  node_group_name = "appointmentservice-eks-node-group"
  node_role_arn   = aws_iam_role.worker_node.arn
  subnet_ids      = aws_subnet.eks[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = var.ec2_key_name
  }

  tags = {
    Name = "appointmentservice-eks-node-group"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_eks_cluster_auth" "app" {
  name = aws_eks_cluster.app.name
}
