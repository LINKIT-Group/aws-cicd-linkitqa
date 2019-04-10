## Frontend SETUP ##

module "container_definition_frontend" {
  source = "github.com/cloudposse/terraform-aws-ecs-container-definition"
  container_name  = "${module.ecs_frontend.container_name}"
  container_image = "${module.ecs_frontend.repository_url}"
  container_cpu = 1024
  container_memory = 2048
  port_mappings = [
    {
      containerPort = "${module.ecs_frontend.container_port}"
      hostPort      = "${module.ecs_frontend.container_port}"
      protocol      = "tcp"
    }
  ]
  environment = [
    {
      name  = "REACT_APP_BACKEND_URL"
      value = "http://${module.ecs_backend.alb_dns_name}"
    }
  ]

  log_options = [
    {
    awslogs-region = "${var.region}"
    awslogs-group = "${module.ecs_frontend.cloudwatch_log_group_name}"
    awslogs-stream-prefix = "${module.ecs_frontend.name}"
    }
  ]
}

module "ecs_frontend" {
  source              = "./modules/ecs"
  cluster_id          = "${aws_ecs_cluster.linkitqa-cluster.id}"
  cluster_name        = "${aws_ecs_cluster.linkitqa-cluster.name}"
  name                = "${var.service_name}-${local.application[0]}"
  environment         = "${local.environment[0]}"
  region              = "${var.region}"
  vpc_id              = "${module.vpc.vpc_id}"
  availability_zones  = "${module.vpc.azs}"
  repository_name     = "linkitqa-${local.application[0]}/${local.environment[0]}"
  subnets_ids         = ["${module.vpc.private_subnets}"]
  public_subnet_ids   = ["${module.vpc.public_subnets}"]
  security_groups_ids = [
    "${module.vpc.default_security_group_id}"
  ]
  task_cpu            = "1024"
  task_memory         = "2048"
  container_name  = "linkitqa-${local.application[0]}-${local.environment[0]}"
  container_port  = "3000"
  container_definition = "${module.container_definition_frontend.json}"
  health_check_grace_period_seconds = "320"
  add_loadbalancer = true
}

module "code_pipeline_frontend" {
  name                        = "${var.service_name}-${local.application[0]}"
  environment                 = "${local.environment[0]}"
  source                      = "./modules/code_pipeline"
  repository_url              = "${module.ecs_frontend.repository_url}"
  region                      = "${var.region}"
  ecs_service_name            = "${module.ecs_frontend.service_name}"
  ecs_cluster_name            = "${aws_ecs_cluster.linkitqa-cluster.name}"
  codecommit_repository_name  = "linkitQA-client-repository"
  codecommit_branch_name      = "master"
  container_name              = "${module.ecs_frontend.container_name}"
}
