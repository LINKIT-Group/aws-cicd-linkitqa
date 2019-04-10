## Use custom policy for backend container. Container needs access to DynomoDB
data "template_file" "ecs_task_execution_role_policy" {
  template = "${file("policies/ecs-task-execution-role-policy.json")}"

  vars {
    dynamodb-prefix = "*"
  }
}

## BACKEND SETUP ##

module "container_definition_backend" {
  source = "github.com/cloudposse/terraform-aws-ecs-container-definition"
  container_name  = "${module.ecs_backend.container_name}"
  container_image = "${module.ecs_backend.repository_url}"
  container_cpu = 1024
  container_memory = 2048
  port_mappings = [
    {
      containerPort = "${module.ecs_backend.container_port}"
      hostPort      = "${module.ecs_backend.container_port}"
      protocol      = "tcp"
    }
  ]
  environment = [
    {
      name  = "AWS_REGION",
      value = "${var.region}"
    },
    {
      name  = "ENDPOINT",
      value = "http://dynamodb.${var.region}.amazonaws.com"
    },
    {
      name  = "HASHSALT",
      value = "!23#4^2!@"
    },
    {
      name  = "NODE_ENV",
      value = "${local.environment[0]}"
    }
  ]

  log_options = [
    {
    awslogs-region = "${var.region}"
    awslogs-group = "${module.ecs_backend.cloudwatch_log_group_name}"
    awslogs-stream-prefix = "${module.ecs_backend.name}"
    }
  ]
}

module "ecs_backend" {
  source              = "./modules/ecs"
  cluster_id          = "${aws_ecs_cluster.linkitqa-cluster.id}"
  cluster_name        = "${aws_ecs_cluster.linkitqa-cluster.name}"
  name                = "${var.service_name}-${local.application[1]}"
  environment         = "${local.environment[0]}"
  region              = "${var.region}"
  vpc_id              = "${module.vpc.vpc_id}"
  availability_zones  = "${module.vpc.azs}"
  repository_name     = "linkitqa-${local.application[1]}/${local.environment[0]}"
  subnets_ids         = ["${module.vpc.private_subnets}"]
  public_subnet_ids   = ["${module.vpc.public_subnets}"]
  security_groups_ids = [
    "${module.vpc.default_security_group_id}"
  ]
  task_cpu            = "1024"
  task_memory         = "2048"
  container_name  = "linkitqa-${local.application[1]}"
  container_port  = "4000"
  container_definition = "${module.container_definition_backend.json}"
  health_check_grace_period_seconds = "320"
  add_loadbalancer = true
  ecs_task_execution_role_policy = "${data.template_file.ecs_task_execution_role_policy.rendered}"
  health_check_matcher = "200,404"
}

module "code_pipeline_backend" {
  name                        = "${var.service_name}-backend"
  environment                 = "${local.environment[0]}"
  source                      = "./modules/code_pipeline"
  repository_url              = "${module.ecs_backend.repository_url}"
  region                      = "${var.region}"
  ecs_service_name            = "${module.ecs_backend.service_name}"
  ecs_cluster_name            = "${aws_ecs_cluster.linkitqa-cluster.name}"
  codecommit_repository_name  = "linkitQA-server-repository"
  codecommit_branch_name      = "master"
  container_name              = "${module.ecs_backend.container_name}"
}

