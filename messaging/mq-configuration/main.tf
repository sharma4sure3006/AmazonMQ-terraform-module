# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN AMAZON MQ CONFIGURATION
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM RUNTIME REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.66.1, < 7.0.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# VALIDATION
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # This will cause terraform to fail during plan if invalid combination is used
  validate_auth_strategy = var.engine_type == "RabbitMQ" && var.authentication_strategy == "ldap" ? error("LDAP authentication strategy is not supported for RabbitMQ engine type") : null
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_mq_configuration" "configuration" {
  name                    = "${var.name}-configuration"
  engine_type             = var.engine_type
  engine_version          = var.engine_version
  description             = var.configuration_description
  data                    = var.configuration_data
  authentication_strategy = var.authentication_strategy
  region                  = var.region
  tags                    = var.tags
}
