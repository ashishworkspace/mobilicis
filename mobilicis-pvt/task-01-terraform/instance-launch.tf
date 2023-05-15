resource "random_integer" "subnet_index" {
  min = 0
  max = length(module.vpc.public_subnets) - 1
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "key_pair" {
  depends_on = [module.vpc]
  source     = "terraform-aws-modules/key-pair/aws"

  key_name   = "tmp"
  public_key = trimspace(file("./ssh/tmp.pub"))
}

module "instace_sg" {
  depends_on = [module.vpc]
  source     = "terraform-aws-modules/security-group/aws"

  name        = "ec2-sg"
  description = "Allow all Traffic"
  vpc_id      = module.vpc.vpc_id
  egress_with_cidr_blocks =  [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from anywhere"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access from anywhere"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

variable "instance_count" {
  description = "Number of EC2 instances to create and attach to the load balancer"
  type        = number
  default     = 2 # Set the desired number of instances here
}
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name                   = "instance-${count.index}"
  count                  = 2
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = module.key_pair.key_pair_name
  monitoring             = true
  vpc_security_group_ids = [module.instace_sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[random_integer.subnet_index.result]
  associate_public_ip_address = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "instance-${count.index}"
  }
}



resource "aws_lb" "alb_lb" {
  depends_on         = [module.vpc, module.ec2_instance]
  name               = "alb-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.instace_sg.security_group_id]
  subnets            = module.vpc.public_subnets
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}

resource "aws_lb_target_group" "alb_target_group" {
  depends_on = [module.vpc, module.ec2_instance]
  name       = "alb-target-group"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = module.vpc.vpc_id
}



resource "aws_lb_target_group_attachment" "alb_attachment0" {
  count            = var.instance_count
  depends_on       = [module.vpc, module.ec2_instance]
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = module.ec2_instance[0].id
  port             = 80
}
resource "aws_lb_target_group_attachment" "alb_attachment1" {
  count            = var.instance_count
  depends_on       = [module.vpc, module.ec2_instance]
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = module.ec2_instance[1].id
  port             = 80
}

resource "aws_lb_listener" "alb_listener" {
  depends_on        = [aws_lb.alb_lb, aws_lb_target_group.alb_target_group]
  load_balancer_arn = aws_lb.alb_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}
