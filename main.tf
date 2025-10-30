terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

########################
# Variables
########################
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "auditor_user_name" {
  description = "IAM user name for the auditor"
  type        = string
  default     = "auditor"
}

########################
# Identity data & locals
########################
data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  auditor_user_arn  = "arn:aws:iam::${local.account_id}:user/${var.auditor_user_name}"
  account_root_arn  = "arn:aws:iam::${local.account_id}:root"
}

########################
# Read-only policy
########################
resource "aws_iam_policy" "custom_readonly" {
  name        = "CustomReadOnlyAccess"
  description = "Allows only read access to resources"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ReadOnly",
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*",
          "iam:Get*",
          "iam:List*",
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ],
        Resource = "*"
      }
    ]
  })
}

########################
# Role trust policy 
########################
resource "aws_iam_role" "auditor_role" {
  name        = "AuditorReadOnlyRole"
  description = "Role with read-only permissions for auditor"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = "sts:AssumeRole",
        Principal = { AWS = local.account_root_arn },
        Condition = {
          StringEquals = {
            "aws:PrincipalArn" = local.auditor_user_arn
          }
        }
      }
    ]
  })
}

########################
# 3) Attach policy to role
########################
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.auditor_role.name
  policy_arn = aws_iam_policy.custom_readonly.arn
}

########################
# Outputs
########################
output "role_arn" {
  description = "role"
  value       = aws_iam_role.auditor_role.arn
}

output "policy_arn" {
  description = "policy"
  value       = aws_iam_policy.custom_readonly.arn
}

