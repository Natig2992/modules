
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "eu-central-1"
  }
}

locals {
  ssh_port     = 22
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}


resource "aws_security_group" "terraform-sec-instance" {

  name = "${var.cluster_name}-sec-instance"
}

resource "aws_security_group_rule" "allow_8080_for_web" {

  type              = "ingress"
  security_group_id = "aws_security_group.terraform-sec-instance.id"
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "allow_ssh_for_web" {

  type              = "ingress"
  security_group_id = "aws_security_group.terraform-sec-instance.id"
  from_port         = local.ssh_port
  to_port           = local.ssh_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}


resource "aws_security_group_rule" "allow_all_outbound_for_web" {

  type              = "egress"
  security_group_id = "aws_security_group.terraform-sec-instance.id"
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
}

/*
resource "aws_instance" "terraform-example" {
    ami       = "ami-00f22f6155d6d92c5"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.terraform-sec-instance.id]
    user_data     = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
                # EOF
    tags = {
        Name = "terraform-example"
    }
}
*/



#Variables for server-port(8080)

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

# Example of data source:

data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")
  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

#Example of launch configuration:
resource "aws_launch_configuration" "terraform-example-launch" {
  name                        = "${var.cluster_name}-launch"
  image_id                    = "ami-0453cb7b5f2b7fca2"
  instance_type               = var.instance_type
  associate_public_ip_address = false
  security_groups             = [aws_security_group.terraform-sec-instance.id]
  user_data                   = file("user_data.sh")


  lifecycle {
    create_before_destroy = true
  }
}

#Example of Auto Scaling group:
resource "aws_autoscaling_group" "autoscale-example" {

  launch_configuration = aws_launch_configuration.terraform-example-launch.name
  min_size             = var.min_size
  desired_capacity     = var.max_size
  max_size             = 5
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids #Argument for subnet_ids
  target_group_arns    = [aws_lb_target_group.asg.arn]
  health_check_type    = "ELB"
  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-asg-example"
    propagate_at_launch = true
  }
}

#Create an ALB load-balancer for our app servers:

resource "aws_lb" "aws_example" {

  name               = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.aws_example.arn
  port              = local.http_port
  protocol          = "HTTP"

  #By default return empty string with 404 code

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }

}
# Example of a security_group for our ALB:

resource "aws_security_group" "alb" {

  name = "${var.cluster_name}-sg"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips

  tags = {
    Name = "Allow HTTP inbound"
  }
}

resource "aws_security_group_rule" "allow_all_outbound" {

  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
}

#Example of a target_group for out ASG:

resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-asg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }
}

#Example of a create aws-lb-listener-rule:


resource "aws_lb_listener_rule" "asg" {

  listener_arn = aws_lb_listener.http.arn
  priority     = 50
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


/*
This is multi-lune comments for Terraform
*/
