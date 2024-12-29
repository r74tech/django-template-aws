[
  {
    "name": "app",
    "command": [
      "gunicorn",
      "app.wsgi:application",
      "--bind",
      "0.0.0.0:8000",
      "--workers",
      "4",
      "--threads",
      "4"
    ],
    "image": "${ecr_image_app}",
    "essential": true,
    "cpu": 768,
    "memory": 1536,
    "portMappings": [
      {
        "containerPort": 8000,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "DATABASE",
        "value": "postgres"
      },
      {
        "name": "DEBUG",
        "value": "False"
      }
    ],
    "secrets": [
      {
        "name": "DB_ENGINE",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/DB_ENGINE"
      },
      {
        "name": "DB_HOST",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/DB_HOST"
      },
      {
        "name": "DB_PORT",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/DB_PORT"
      },
      {
        "name": "SECRET_KEY",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/SECRET_KEY"
      },
      {
        "name": "DB_NAME",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/DB_NAME"
      },
      {
        "name": "DB_USER",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/DB_USER"
      },
      {
        "name": "DB_PASSWORD",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/DB_PASSWORD"
      },
      {
        "name": "DJANGO_ALLOWED_HOSTS",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/DJANGO_ALLOWED_HOSTS"
      },
      {
        "name": "CSRF_TRUSTED_PORTS",
        "valueFrom": "arn:aws:ssm:${region}:${account_id}:parameter/${prefix}/CSRF_TRUSTED_PORTS"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name_app}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "app"
      }
    },
    "mountPoints": [
      {
        "sourceVolume": "static_volume",
        "containerPath": "/usr/src/app/staticfiles",
        "readOnly": false
      },
      {
        "sourceVolume": "media_volume",
        "containerPath": "/usr/src/app/mediafiles",
        "readOnly": false
      }
    ]
  },
  {
    "name": "nginx",
    "image": "${ecr_image_web}",
    "essential": true,
    "cpu": 256,
    "memory": 512,
    "portMappings": [
      {
        "containerPort": 8080,
        "protocol": "tcp"
      }
    ],
    "dependsOn": [
      {
        "containerName": "app",
        "condition": "START"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${log_group_name_web}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "nginx"
      }
    },
    "mountPoints": [
      {
        "sourceVolume": "static_volume",
        "containerPath": "/usr/src/app/staticfiles",
        "readOnly": true
      },
      {
        "sourceVolume": "media_volume",
        "containerPath": "/usr/src/app/mediafiles",
        "readOnly": true
      }
    ]
  }
]