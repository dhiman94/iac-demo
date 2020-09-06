resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "demo-vpc"
    Purpose = "Jenkins Demo"
  }
}

output "vpc_id" {
  value = aws_vpc.main.id 
}

# create one s3 bucket for storing artifacts
resource "aws_s3_bucket" "codedeploy_artifacts" {
  bucket = "dhiman-codedeploy-artifacts"
  acl    = "private"

  lifecycle_rule {
    id      = "delete_old_artifacts"
    enabled = true

    expiration {
        days = 30
    }

  }

  
  tags = {
    Name        = "Codedeploy Artifacts"
    Environment = "Dev"
  }
}

output "codedeploy_bucket_name" {
    value =  aws_s3_bucket.codedeploy_artifacts.id 
}  
