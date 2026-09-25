output "app_url" { value = "http://${module.web.alb_dns}" }
output "instance_ip" { value = module.web.instance_ip }
output "instance_id" { value = module.web.instance_id }
