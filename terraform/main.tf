module "network" {
  source = "./modules/network"
  name = var.name
}
module "web" {
  source = "./modules/web"
  name = var.name
  vpc_id = module.network.vpc_id
  subnet_ids = module.network.subnet_ids
  admin_cidr = var.admin_cidr
  key_name = var.key_name
  instance_type = var.instance_type
}
