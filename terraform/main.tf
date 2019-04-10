locals {
  environment = ["test","accept","production"]
  application = ["frontend","backend"]
}

resource "aws_codecommit_repository" "linkitQA-server-repository" {
  repository_name = "linkitQA-server-repository"
  description     = "linkitQA-server-repository"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_codecommit_repository" "linkitQA-client-repository" {
  repository_name = "linkitQA-client-repository"
  description     = "linkitQA-client-repository"
  lifecycle {
    prevent_destroy = true
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.service_name}"
  cidr = "10.88.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]
  private_subnets = ["10.88.1.0/24", "10.88.2.0/24"]
  public_subnets  = ["10.88.11.0/24", "10.88.12.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Name = "${var.service_name}"
    Stage = "${local.environment[0]}"
    Playground = "yes"
    Application = "${var.service_name}"
    Internal = "yes"
    Ephemeral = "no"
  }
}


/*====
ECS cluster
======*/
resource "aws_ecs_cluster" "linkitqa-cluster" {
  name = "${local.environment[0]}-${var.service_name}-ecs-cluster"
}

