provider "aws" {
  region = var.region

  assume_role {
    role_arn     = var.aws_assume_role_arn
    session_name = var.aws_assume_role_session_name
    external_id  = var.aws_assume_role_external_id
  }
}

data "aws_caller_identity" "current" {
}

resource "random_pet" "e2e" {
}

resource "random_password" "windows_admin_password" {
  length           = 20
  special          = true
  override_special = "_%@"
}

locals {
  random_name = "${var.name}-${random_pet.e2e.id}"
}

# Generates keys to use for provisioning and access
module "keys" {
  name    = local.random_name
  path    = "${path.root}/keys"
  source  = "mitchellh/dynamic-keys/aws"
  version = "v2.0.0"
}

# Explicit local_file with permissions
resource "local_file" "private_key" {
  content         = module.keys.private_key_pem
  filename        = module.keys.private_key_filepath
  file_permission = "0600"
}

# Store keys in SSM
resource "aws_ssm_parameter" "ssm_private_key_pem" {
  name  = "${local.random_name}-private_key"
  type  = "SecureString"
  value = module.keys.private_key_pem
}

resource "aws_ssm_parameter" "ssm_public_key_openssh" {
  name  = "${local.random_name}-public_key"
  type  = "String"
  value = module.keys.public_key_openssh
}
