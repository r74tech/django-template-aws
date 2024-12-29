# ------------------------------
# ECS Configuration
# ------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.prefix}-ecs-cluster"
  }
}


# タスク定義
data "template_file" "container_definitions" {
  template = file("${path.module}/templates/ecs/taskdef.json.tpl")

  vars = {
    ecr_image_app      = var.ecr_image_app
    ecr_image_web      = var.ecr_image_web
    region            = var.region
    account_id       = data.aws_caller_identity.current.account_id
    prefix           = local.prefix
    log_group_name_app = aws_cloudwatch_log_group.app.name
    log_group_name_web = aws_cloudwatch_log_group.web.name
    db_host          = aws_db_instance.main.endpoint
    efs_id           = aws_efs_file_system.main.id
    execution_role_arn = var.execution_role_arn
    task_role_arn     = var.task_role_arn
  }
}

resource "aws_ecs_task_definition" "app" {
  family                    = "${local.prefix}-app"
  container_definitions     = data.template_file.container_definitions.rendered
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = "1024"
  memory                    = "2048"
  execution_role_arn        = var.execution_role_arn
  task_role_arn             = var.task_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture       = "X86_64"
  }

  volume {
    name = "static_volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.main.id
      root_directory = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.static.id
      }
    }
  }

  volume {
    name = "media_volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.main.id
      root_directory = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.media.id
      }
    }
  }


  tags = {
    Name = "${local.prefix}-ecs-task-def"
  }
}

# EFS
resource "aws_efs_file_system" "main" {
  creation_token = "${local.prefix}-efs"
  encrypted      = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "${local.prefix}-efs"
  }
}

resource "aws_efs_mount_target" "main" {
  count           = 2
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = element([aws_subnet.private_a.id, aws_subnet.private_c.id], count.index)
  security_groups = [aws_security_group.efs.id]
}

# セキュリティグループ
resource "aws_security_group" "ecs_sg" {
  name        = "${local.prefix}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-ecs-sg"
  }
}

resource "aws_security_group" "efs" {
  name        = "${local.prefix}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-efs-sg"
  }
}

resource "aws_security_group" "alb" {
  name        = "${local.prefix}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-alb-sg"
  }
}


# ALB
resource "aws_lb" "main" {
  name               = "${local.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = [aws_subnet.public_a.id, aws_subnet.public_c.id]

  tags = {
    Name = "${local.prefix}-alb"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  certificate_arn = aws_acm_certificate.app_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  depends_on = [aws_lb_target_group.main]
}

resource "aws_lb_target_group" "main" {
  name        = "${local.prefix}-tg-v2"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 60
    matcher            = "200,400"
    path                = "/admin/login/"
    timeout             = 30
    unhealthy_threshold = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.prefix}-tg"
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name                               = "${local.prefix}-service"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.app.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 120

  deployment_minimum_healthy_percent= 50
  deployment_maximum_percent = 200


  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_c.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "nginx"
    container_port   = 8080
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.https]

  tags = {
    Name = "${local.prefix}-ecs-service"
  }
}

# Auto Scaling
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${local.prefix}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80.0
  }
}
