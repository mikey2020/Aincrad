provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "sm-ascentregtech-terraform"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "sm-ascentregtech-terraform-table"
    encrypt = true
  }
}

locals {
  http_port = 80
  any_port  = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips  = ["0.0.0.0/0"]
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "S3 bucket ARN"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name 
  description = "DynamoDB table"
}

variable "server_port" {
  description = "Port used by server for HTTP requests"
  type = number
  default = 8080
}

variable "desired_capacity" {
  description = "Number of instances needed for ASG"
  type = number
  default = 2
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "my_sg" {
  name = "${var.cluster_name}-sg"

  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "my_launch" {
  image_id = "ami-0c55b159cbfafe1f0"
  instance_type = var.instance_type
  security_groups = [aws_security_group.my_sg.id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my_launch" {
  launch_configuration = aws_launch_configuration.my_launch.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  desired_capacity = 2
  max_size = var.max_size

  tag {
    key = "Name"
    value = "${var.cluster_name}-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "my_elb" {
  name = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.my_elb.arn
  port = local.http_port
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Are you sure this page exists ?"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type  = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

  ingress {
    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb.id

  egress {
    from_port = local.any_port
    to_port = local.any_port
    protocol = lcoal.any_protocol
    cidr_blocks = local.any_protocol
  }
}


resource "aws_lb_target_group" "asg" {
  name = "${var.cluster_name}-target-group"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  } 
}

output "public_ip" {
  description = "Public IP address of server"
  value = aws_instance.my_first.public_ip
}

output "alb_dns_name" {
  description = "The domain name of load balancer"
  value = aws_lb.my_elb.dns_name
}

output "asg_name" {
  value       = aws_autoscaling_group.example.name
  description = "The name of the Auto Scaling Group"
}
