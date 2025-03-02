resource "aws_cloudwatch_log_group" "viz_brayns" {
  name              = "viz_brayns"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "viz_brayns"
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_task_definition" "viz_brayns" {
  family       = "viz_brayns_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 2048
      cpu         = 1024
      networkMode = "awsvpc"
      family      = "viz_brayns"
      essential   = true
      image       = var.viz_brayns_docker_image_url
      name        = "viz_brayns"
      repositoryCredentials = {
        credentialsParameter = data.aws_secretsmanager_secret.dockerhub_creds.arn
      }
      environment = []
      volumesFrom = []
      portMappings = [
        {
          hostPort      = 5000
          containerPort = 5000
          protocol      = "tcp"
        }
      ]
      command = [
        "/app/mount_s3.sh",
        "braynsService",
        "--uri",
        "0.0.0.0:5000",
        "--log-level",
        "debug",
        "--plugin",
        "braynsCircuitExplorer",
        "--plugin",
        "braynsAtlasExplorer"
      ]
      healthcheck = {
        interval = 30
        retries  = 3
        timeout  = 5
        command  = ["CMD-SHELL", "/usr/bin/curl localhost:5000/healthz || exit 1"]
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.viz_brayns_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "viz_brayns"
        }
      }
      linuxParameters = {
        "capabilities" = {
          "add"  = ["SYS_ADMIN"],
          "drop" = []
        }
        "devices" = [
          {
            "containerPath" = "/dev/fuse",
            "hostPath"      = "/dev/fuse",
            "permissions"   = null
          }
      ] }
    }
  ])
  memory                   = 2560
  cpu                      = 2048
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.viz_brayns_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.viz_brayns_ecs_task_role.arn

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role" "ecs_viz_service_role" {
  name = "ecs_viz_service_role"
  tags = {
    SBO_Billing = "viz"
  }
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = "sts:AssumeRole",
        "Principal" = {
          "Service" = "ecs.amazonaws.com"
        },
        "Effect" = "Allow",
        "Sid"    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  role   = aws_iam_role.ecs_viz_service_role.id
  policy = data.aws_iam_policy_document.brayns_ecs_service_role_policy.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "brayns_ecs_service_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "ec2:DescribeTags",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutSubscriptionFilter",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "viz_brayns_ecs_task_execution_role" {
  name = "viz_brayns-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = "sts:AssumeRole",
        "Principal" = {
          "Service" = "ecs-tasks.amazonaws.com"
        },
        "Effect" = "Allow",
        "Sid"    = ""
      }
    ]
  })
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role_policy_attachment" "viz_brayns_ecs_task_execution_role" {
  role       = aws_iam_role.viz_brayns_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "viz_brayns_ecs_task_role" {
  name = "viz_brayns-ecsTaskRole"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = "sts:AssumeRole",
        "Principal" = {
          "Service" = "ecs-tasks.amazonaws.com"
        },
        "Effect" = "Allow",
        "Sid"    = ""
      }
    ]
  })
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role_policy_attachment" "viz_brayns_ecs_task_role_dockerhub" {
  role       = aws_iam_role.viz_brayns_ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.selected.arn
}

resource "aws_iam_role_policy_attachment" "viz_brayns_ecs_task_role_s3" {
  role       = aws_iam_role.viz_brayns_ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy" "viz_brayns_ecs_exec" {
  name = "viz_brayns_ecs_exec_policy"
  role = aws_iam_role.viz_brayns_ecs_task_role.id
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" = "*"
      }
    ]
  })
}
