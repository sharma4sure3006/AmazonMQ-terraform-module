# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN AMAZON MQ BROKER
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
# LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  broker_security_group_name        = var.broker_security_group_name == null ? var.name : var.broker_security_group_name
  broker_security_group_description = var.broker_security_group_description == null ? "Security group for the ${var.name} broker" : var.broker_security_group_description

  # Validation
  validate_rabbitmq_ldap = var.engine_type == "RabbitMQ" && var.authentication_strategy == "ldap" ? error("LDAP not supported for RabbitMQ") : null
  validate_storage       = var.engine_type == "RabbitMQ" && var.storage_type != "ebs" ? error("RabbitMQ only supports EBS storage") : null
  validate_crdr          = var.data_replication_mode == "CRDR" && var.data_replication_primary_broker_arn == null ? error("Primary broker ARN required for CRDR mode") : null
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE BROKER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_mq_broker" "broker" {
  broker_name = "${var.name}-broker"

  dynamic "configuration" {
    for_each = var.configuration_id != null ? [1] : []
    content {
      id       = var.configuration_id
      revision = var.configuration_revision
    }
  }

  engine_type        = var.engine_type
  engine_version     = var.engine_version
  storage_type       = var.storage_type
  host_instance_type = var.host_instance_type

  # ADMIN USER
  user {
    username         = var.admin_user.username
    password         = var.admin_user.password
    console_access   = var.engine_type == "ActiveMQ" ? true : null
    groups           = var.engine_type == "ActiveMQ" ? [] : null
    replication_user = false
  }

  dynamic "ldap_server_metadata" {
    for_each = var.ldap_server_metadata != null && var.engine_type == "ActiveMQ" ? [var.ldap_server_metadata] : []
    content {
      hosts                    = ldap_server_metadata.value.hosts
      role_base                = ldap_server_metadata.value.role_base
      role_name                = ldap_server_metadata.value.role_name
      role_search_matching     = ldap_server_metadata.value.role_search_matching
      role_search_subtree      = ldap_server_metadata.value.role_search_subtree
      service_account_password = ldap_server_metadata.value.service_account_password
      service_account_username = ldap_server_metadata.value.service_account_username
      user_base                = ldap_server_metadata.value.user_base
      user_role_name           = ldap_server_metadata.value.user_role_name
      user_search_matching     = ldap_server_metadata.value.user_search_matching
      user_search_subtree      = ldap_server_metadata.value.user_search_subtree
    }
  }

  deployment_mode = var.deployment_mode

  data_replication_mode               = var.data_replication_mode
  data_replication_primary_broker_arn = var.data_replication_primary_broker_arn

  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  dynamic "maintenance_window_start_time" {
    for_each = var.enable_maintenance_window ? [1] : []
    content {
      day_of_week = var.maintenance_day_of_week
      time_of_day = var.maintenance_time_of_day
      time_zone   = var.maintenance_time_zone
    }
  }

  publicly_accessible = var.publicly_accessible

  authentication_strategy = var.authentication_strategy
  security_groups = concat(
    [aws_security_group.broker.id],
    var.additional_broker_security_group_ids,
  )

  dynamic "encryption_options" {
    for_each = var.enable_encryption ? [1] : []
    content {
      use_aws_owned_key = var.use_aws_owned_key
      kms_key_id        = var.use_aws_owned_key ? null : var.kms_key_id
    }
  }

  dynamic "logs" {
    for_each = var.logs ? [1] : []
    content {
      audit   = var.enable_audit_logs
      general = var.enable_general_logs
    }
  }

  subnet_ids = var.subnet_ids
  tags       = var.tags

  timeouts {
    create = var.creating_timeout
    update = var.updating_timeout
    delete = var.deleting_timeout
  }
}

# --------------------------------------------------------------------------------
# CREATE THE SECURITY GROUP THAT CONTROLS WHAT TRAFFIC CAN CONNECT TO THE BROKER
# --------------------------------------------------------------------------------

resource "aws_security_group" "broker" {
  name        = local.broker_security_group_name
  description = local.broker_security_group_description
  vpc_id      = var.vpc_id
  tags        = var.custom_tags
}

resource "aws_security_group_rule" "allow_connections_from_cidr_blocks" {
  count             = signum(length(var.allow_connections_from_cidr_blocks))
  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = var.allow_connections_from_cidr_blocks
  security_group_id = aws_security_group.broker.id
}

resource "aws_security_group_rule" "allow_https_connections_from_cidr_blocks" {
  count             = signum(length(var.allow_https_connections_from_cidr_blocks))
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allow_https_connections_from_cidr_blocks
  security_group_id = aws_security_group.broker.id
}

resource "aws_security_group_rule" "allow_connections_from_security_group" {
  count                    = length(var.allow_connections_from_security_groups)
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = element(var.allow_connections_from_security_groups, count.index)
  security_group_id        = aws_security_group.broker.id
}

resource "aws_security_group_rule" "allow_https_connections_from_security_group" {
  count                    = length(var.allow_https_connections_from_security_groups)
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = element(var.allow_https_connections_from_security_groups, count.index)
  security_group_id        = aws_security_group.broker.id
}

resource "aws_security_group_rule" "allow_outbound_traffic_from_broker" {
  count             = signum(length(var.allow_outbound_connections_to_cidr_blocks))
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.broker.id
  cidr_blocks       = var.allow_outbound_connections_to_cidr_blocks
}

# ---------------------------------------------------------------------------------------------------------------------
# ADD CLOUDWATCH ALARMS FOR THE MQ BROKER
# ---------------------------------------------------------------------------------------------------------------------

module "mq_alarms" {
  source           = "git::git@github.com:aubank-io/terraform-aubank-service-catalog.git//modules/monitoring/alarms/mq-alarms?ref=v0.49.1"
  create_resources = var.enable_cloudwatch_alarms

  mq_broker_ids                         = [aws_mq_broker.broker.id]
  num_mq_broker_ids                     = 1
  high_system_cpu_utilization_threshold = var.high_system_cpu_utilization_threshold
  high_memory_utilization_threshold     = var.high_memory_utilization_threshold
  low_disk_free_threshold               = var.low_disk_free_threshold
  alarm_sns_topic_arns                  = var.alarms_sns_topic_arns

  tags = var.custom_tags
}
