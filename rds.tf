resource "aws_rds_cluster" "this" {
  cluster_identifier_prefix       = "${var.id}-"
  final_snapshot_identifier       = "${var.id}-${timestamp()}"
  copy_tags_to_snapshot           = true
  engine                          = "aurora"
  engine_mode                     = "serverless"
  master_password                 = random_string.this.result
  backup_retention_period         = 5     # days
  backtrack_window                = 86400 # 24 hours
  snapshot_identifier             = var.snapshot_identifier
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_subnet_group_name            = aws_db_subnet_group.this.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.id
  deletion_protection             = var.protection
  enable_http_endpoint            = true
  tags                            = var.tags

  scaling_configuration {
    min_capacity = 1
    max_capacity = var.max_capacity
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "this" {
  length  = 32
  special = false
}

resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.id}-"
  subnet_ids  = tolist(var.private_subnet_ids)
  tags        = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  name_prefix = "mb-"
  family      = "aurora5.6"
  tags        = var.tags

  parameter {
    name         = "lower_case_table_names"
    value        = "1"
    apply_method = "pending-reboot"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.id}-rds-"
  vpc_id      = var.vpc_id
  tags        = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "rds_ingress_ecs" {
  description              = "ECS"
  type                     = "ingress"
  from_port                = aws_rds_cluster.this.port
  to_port                  = aws_rds_cluster.this.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.alb.id
}
