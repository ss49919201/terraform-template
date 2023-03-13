module "ecs_task" {
  source                   = "./modules/ecs"
  vpc_id                   = module.vpc.vpc_id
  ecr_repository_url       = module.ecr_repository.ecr_repository_url
  ecs_cluster_name         = "example"
  ecs_task_definition_name = "example"
  aws_account_id           = local.aws_account_id
}
