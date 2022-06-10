# Setup the AWS provider | provider.tf

terraform {
  # cloud {
  # organization = "thebigdummycorp"
  #  workspaces {
  #    name = "dev-Workspace"
  #  }
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.7.0"
    }
  }

  #required_version = ">= 0.14.9"
}

