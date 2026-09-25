variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "admin_cidr" { type = string }
variable "key_name" { type = string }
variable "instance_type" { type = string }
data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  vpc_id = var.vpc_id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "web" {
  name_prefix = "${var.name}-web-"
  vpc_id = var.vpc_id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.admin_cidr]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_iam_role" "web" {
  name_prefix = "${var.name}-"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "web" { role = aws_iam_role.web.name }
resource "aws_instance" "web" {
  ami = data.aws_ssm_parameter.ami.value
  instance_type = var.instance_type
  subnet_id = var.subnet_ids[0]
  associate_public_ip_address = true
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile = aws_iam_instance_profile.web.name
  metadata_options { http_tokens = "required" }
  root_block_device { encrypted = true }
  tags = { Name = "${var.name}-web" }
}
resource "aws_lb" "web" {
  name = "${var.name}-alb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets = var.subnet_ids
}
resource "aws_lb_target_group" "web" {
  name = "${var.name}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
  health_check {
    path = "/health.html"
    matcher = "200"
  }
}
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id = aws_instance.web.id
  port = 80
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port = "80"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
output "alb_dns" { value = aws_lb.web.dns_name }
output "instance_ip" { value = aws_instance.web.public_ip }
output "instance_id" { value = aws_instance.web.id }
