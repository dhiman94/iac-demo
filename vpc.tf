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

# create bucket policy to allow ec2 codedeploy role
resource "aws_s3_bucket_policy" "s3_codedeploy_policy" {
  bucket = aws_s3_bucket.codedeploy_artifacts.id

  policy = <<POLICY
{
     
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": ""arn:aws:iam::748658621424:role/codedeploy_service_role""
            },
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:PutObject"
            ],
            "Resource": "arn:aws:s3:::dhiman-codedeploy-artifacts/*"
        }
    ]
   }
   POLICY
}


output "codedeploy_bucket_name" {
    value =  aws_s3_bucket.codedeploy_artifacts.id 
}  

# create codedeploy application
resource "aws_codedeploy_app" "spring_maven" {
  compute_platform = "Server"
  name             = "HelloWorldMaven"
}

# create codedeploy deployment group
resource "aws_codedeploy_deployment_group" "spring_maven_deployment_group"{
  app_name = aws_codedeploy_app.spring_maven.name
  deployment_group_name = "HelloWorldMavenDeployGrp" 
  service_role_arn      = "arn:aws:iam::748658621424:role/codedeploy_service_role"

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "Tomcat"
    }

    ec2_tag_filter {
      key   = "Deployment"
      type  = "KEY_AND_VALUE"
      value = "Codedeploy"
    }
  }

}

