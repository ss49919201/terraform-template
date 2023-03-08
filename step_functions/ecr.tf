module "ecr_repository" {
  source              = "./modules/ecr"
  ecr_repository_name = "example"
}
