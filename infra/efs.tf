# EFS Configuration
resource "aws_efs_access_point" "static" {
  file_system_id = aws_efs_file_system.main.id
  
  root_directory {
    path = "/staticfiles"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name = "${local.prefix}-efs-ap-static"
  }
}

resource "aws_efs_access_point" "media" {
  file_system_id = aws_efs_file_system.main.id
  
  root_directory {
    path = "/mediafiles"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name = "${local.prefix}-efs-ap-media"
  }
}
