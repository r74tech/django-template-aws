# ------------------------------
# Database Configuration
# ------------------------------
resource "aws_db_subnet_group" "main" {
  name = "${local.prefix}-main"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_c.id,
  ]


  tags = {
    Name = "${local.prefix}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.prefix}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol  = "tcp"
    from_port = 5432
    to_port   = 5432
    security_groups = [
      # ECSからRDSへのアクセスを許可する
      aws_security_group.ecs_sg.id
    ]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-rds-sg"
  }
}

resource "aws_db_instance" "main" {
  identifier        = "${local.prefix}-db"
  db_name           = "app"

  engine            = "postgres"
  engine_version    = "17"
  instance_class    = "db.t3.small"
  allocated_storage = 20
  storage_type      = "gp2"

  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  tags = {
    Name = "${local.prefix}-rds-instance"
  }
}

