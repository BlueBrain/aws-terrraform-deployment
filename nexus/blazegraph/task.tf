locals {
  blazegraph_cpu    = 1024
  blazegraph_memory = 6144
}

resource "aws_ecs_task_definition" "blazegraph_ecs_definition" {
  family       = "blazegraph_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = local.blazegraph_memory
      networkMode = "awsvpc"
      cpu         = local.blazegraph_cpu
      family      = "blazegraph"
      portMappings = [
        {
          hostPort      = 9999
          containerPort = 9999
          protocol      = "tcp"
          name          = "blazegraph"
        }
      ]
      essential = true
      name      = "blazegraph"
      image     = var.blazegraph_docker_image_url
      environment = [
        {
          name  = "JAVA_OPTS"
          value = " -Dlog4j.configuration=/var/lib/blazegraph/log4j/log4j.properties -Djava.awt.headless=true -Djava.awt.headless=true -XX:MaxDirectMemorySize=600m -Xms3g -Xmx3g -XX:+UseG1GC "
        },
        {
          name  = "JETTY_START_TIMEOUT"
          value = "120"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.blazegraph_app_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "blazegraph_app"
        }
      }
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: not exit 0
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      mountPoints = [
        {
          sourceVolume  = "efs-blazegraph-data"
          containerPath = "/var/lib/blazegraph/data"
          readOnly      = false
        },
        {
          sourceVolume  = "efs-blazegraph-log4j"
          containerPath = "/var/lib/blazegraph/log4j"
          readOnly      = false
        }
      ]
    }
  ])

  cpu                      = local.blazegraph_cpu
  memory                   = local.blazegraph_memory
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.ecs_task_execution_role_arn

  volume {
    name = "efs-blazegraph-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blazegraph.id
      root_directory     = var.efs_blazegraph_data_dir
      transit_encryption = "ENABLED"
    }
  }
  volume {
    name = "efs-blazegraph-log4j"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blazegraph.id
      root_directory     = var.efs_blazegraph_log4j_dir
      transit_encryption = "ENABLED"
    }
  }
  tags = {
    SBO_Billing = "nexus"
  }
}
