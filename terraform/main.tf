provider "aws" {
  region = "us-west-2" # Modify this to your desired AWS region
}

# Define Route53 for DNS
resource "aws_route53_zone" "main" {
  name = "example.com." # Replace with your domain name
}

resource "aws_route53_record" "dns" {
  zone_id = aws_route53_zone.main.id
  name    = "app.example.com." # Replace with your subdomain
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Define Application Load Balancer (ELB)
resource "aws_lb" "main" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public.*.id

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.logs.bucket
    enabled = true
  }
}

# Define ECS services
resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster"
}

resource "aws_ecs_service" "login" {
  name            = "login-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.login.arn
  desired_count   = 1
  launch_type     = "EC2"
}

resource "aws_ecs_task_definition" "login" {
  family                = "login-task"
  container_definitions = jsonencode([{
    name      = "login"
    image     = "your-login-service-image"
    memory    = 512
    cpu       = 256
    essential = true
  }])
}

# Repeat for other ECS services (GetDogInfo, UpdateVaccines, GetVaccines)

# Define RDS databases
resource "aws_db_instance" "userdb" {
  identifier = "userdb"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  engine = "mysql"
  username = "admin"
  password = "password" # Change this
  db_name = "userdb"
}

resource "aws_db_instance" "dogbd" {
  identifier = "dogbd"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  engine = "mysql"
  username = "admin"
  password = "password" # Change this
  db_name = "dogbd"
}

resource "aws_db_instance" "vaccinesbd" {
  identifier = "vaccinesbd"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  engine = "mysql"
  username = "admin"
  password = "password" # Change this
  db_name = "vaccinesbd"
}

# Define ElastiCache Memcached
resource "aws_elasticache_cluster" "memcached" {
  cluster_id           = "memcached-cluster"
  engine               = "memcached"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.memcached1.5"
  port                 = 11211
}

# Define security groups (examples)
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  description = "Security group for load balancer"
}

resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  description = "Security group for ECS services"
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Security group for databases"
}

resource "aws_security_group" "cache_sg" {
  name        = "cache-sg"
  description = "Security group for ElastiCache"
}

# Outputs
output "lb_dns_name" {
  value = aws_lb.main.dns_name
}

output "rds_userdb_endpoint" {
  value = aws_db_instance.userdb.endpoint
}

output "rds_dogbd_endpoint" {
  value = aws_db_instance.dogbd.endpoint
}

output "rds_vaccinesbd_endpoint" {
  value = aws_db_instance.vaccinesbd.endpoint
}

output "cache_endpoint" {
  value = aws_elasticache_cluster.memcached.cache_nodes.0.address
}
