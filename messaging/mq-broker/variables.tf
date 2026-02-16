# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The name of the MQ broker."
  type        = string
}

variable "engine_type" {
  description = "Type of broker engine, ActiveMQ or RabbitMQ"
  type        = string
}

variable "engine_version" {
  description = "The version of the broker engine. See https://docs.aws.amazon.com/amazon-mq/latest/developer-guide/broker-engine.html for more details"
  type        = string
}

variable "storage_type" {
  description = "Storage type of the broker. For engine_type ActiveMQ, valid values are efs and ebs (AWS-default is efs). For engine_type RabbitMQ, only ebs is supported. When using ebs, only the mq.m5 broker instance type family is supported."
  type        = string
  default     = "ebs"
}

variable "host_instance_type" {
  description = "The broker's instance type. e.g. mq.t3.micro or mq.m5.large"
  type        = string
}

variable "configuration_id" {
  description = "Configuration ID to apply to the broker"
  type        = string
  default     = null
}

variable "configuration_revision" {
  description = "Configuration revision to apply"
  type        = number
  default     = null
}

variable "admin_user" {
  description = "Admin user configuration for the broker (required)"
  type = object({
    username = string
    password = string
  })
  sensitive = true
}

variable "application_users" {
  description = "List of application users for the broker (at least 1 required). Note: RabbitMQ users don't support console_access or groups."
  type = list(object({
    username         = string
    password         = string
    replication_user = optional(bool, false)
  }))
  sensitive = true

  validation {
    condition     = length(var.application_users) >= 1 && length(var.application_users) <= 3
    error_message = "Must provide at least 1 and at most 3 application users."
  }
}

variable "ldap_server_metadata" {
  description = "Configuration for LDAP server (ActiveMQ only)"
  type = object({
    hosts                    = list(string)
    role_base                = optional(string)
    role_name                = optional(string)
    role_search_matching     = optional(string)
    role_search_subtree      = optional(bool)
    service_account_password = string
    service_account_username = string
    user_base                = optional(string)
    user_role_name           = optional(string)
    user_search_matching     = optional(string)
    user_search_subtree      = optional(bool)
  })
  default   = null
  sensitive = true
}

variable "deployment_mode" {
  description = "Deployment mode of the broker. Valid values are SINGLE_INSTANCE, ACTIVE_STANDBY_MULTI_AZ, and CLUSTER_MULTI_AZ. Default is SINGLE_INSTANCE."
  type        = string
  default     = "SINGLE_INSTANCE"
}

variable "data_replication_mode" {
  description = "Whether this broker is part of a data replication pair. Valid values are CRDR and NONE."
  type        = string
  default     = "NONE"
}

variable "data_replication_primary_broker_arn" {
  description = "ARN of the primary broker used to replicate data in a data replication pair. Required when data_replication_mode is CRDR."
  type        = string
  default     = null
}

variable "apply_immediately" {
  description = "Whether to apply broker modifications immediately."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Whether to automatically upgrade to new minor versions of brokers as Amazon MQ makes releases available."
  type        = bool
  default     = false
}

variable "enable_maintenance_window" {
  description = "Whether to configure a maintenance window on the broker."
  type        = bool
  default     = true
}

variable "maintenance_day_of_week" {
  description = "Day of the week for maintenance window"
  type        = string
  default     = "SUNDAY"
}

variable "maintenance_time_of_day" {
  description = "Time of day for maintenance window in 24-hour format (HH:MM)"
  type        = string
  default     = "02:00"
}

variable "maintenance_time_zone" {
  description = "Time zone for maintenance window"
  type        = string
  default     = "IST"
}

variable "publicly_accessible" {
  description = "Whether to enable connections from applications outside of the VPC that hosts the broker's subnets."
  type        = bool
  default     = false
}

variable "region" {
  description = "The AWS region to create broker in."
  type        = string
  default     = "ap-south-1"
}

variable "authentication_strategy" {
  description = "Authentication strategy used to secure the broker. Valid values are simple and ldap. ldap is not supported for engine_type RabbitMQ."
  type        = string
  default     = "simple"
}

variable "broker_security_group_name" {
  description = "The name of the aws_broker_security_group that is created. Defaults to var.name if not specified."
  type        = string
  default     = null
}

variable "broker_security_group_description" {
  description = "The description of the aws_broker_security_group that is created. Defaults to 'Security group for the var.name broker' if not specified."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "The id of the VPC in which this Broker should be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs in which to launch the broker. A SINGLE_INSTANCE deployment requires one subnet. An ACTIVE_STANDBY_MULTI_AZ deployment requires multiple subnets."
  type        = list(string)
}

variable "additional_broker_security_group_ids" {
  description = "List of IDs of AWS Security Groups to attach to the MQ broker."
  type        = list(string)
  default     = []
}

variable "enable_encryption" {
  description = "Whether to enable encryption for the MQ broker"
  type        = bool
  default     = true
}

variable "use_aws_owned_key" {
  description = "Whether to enable an AWS-owned KMS CMK not in your account"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "ARN of KMS CMK to use for encryption at rest. Required when use_aws_owned_key is false. When kms_key_id = null, it creates an AWS-managed key with alias aws/mq."
  type        = string
  default     = null
}

variable "logs" {
  description = "Whether to enable logs for the MQ broker"
  type        = bool
  default     = false
}

variable "enable_audit_logs" {
  description = "Whether to enable audit logging. Only possible for engine_type of ActiveMQ. Logs user management actions via JMX or ActiveMQ Web Console. Defaults to false."
  type        = bool
  default     = false
}

variable "enable_general_logs" {
  description = " Whether to enable general logging via CloudWatch. Defaults to false."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags to assign to the broker. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(string)
  default     = {}
}

variable "creating_timeout" {
  description = "Duration to wait before timing out when creating the MQ broker. Default is 30m"
  type        = string
  default     = "30m"
}

variable "updating_timeout" {
  description = "Duration to wait before timing out when updating the MQ broker. Default is 30m"
  type        = string
  default     = "30m"
}

variable "deleting_timeout" {
  description = "Duration to wait before timing out when deleting the MQ broker. Default is 30m"
  type        = string
  default     = "30m"
}

variable "custom_tags" {
  description = "A map of custom tags to apply to the Broker and the Security Group created for it. The key is the tag name and the value is the tag value."
  type        = map(string)
  default     = {}
}

variable "port" {
  description = "The port on which the broker is accessible."
  type        = number
  default     = 5671
}

variable "allow_connections_from_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that can connect to this Broker. Should typically be the CIDR blocks of the private app subnet in this VPC plus the private subnet in the mgmt VPC."
  type        = list(string)
  default     = []
}

variable "allow_https_connections_from_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that can connect to this Broker. Should typically be the CIDR blocks of the private app subnet in this VPC plus the private subnet in the mgmt VPC."
  type        = list(string)
  default     = []
}

variable "allow_outbound_connections_to_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges that the broker is allowed to send traffit to. Should typically be the CIDR blocks of the private app subnet in this VPC plus the private subnet in the mgmt VPC."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allow_connections_from_security_groups" {
  description = "A list of Security Groups that can connect to this Broker."
  type        = list(string)
  default     = []
}

variable "allow_https_connections_from_security_groups" {
  description = "A list of Security Groups that can connect to this Broker."
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_alarms" {
  description = "Set to true to enable several basic CloudWatch alarms around CPU usage, memory usage, and disk space usage. If set to true, make sure to specify SNS topics to send notifications to using var.alarms_sns_topic_arn."
  type        = bool
  default     = true
}

variable "high_system_cpu_utilization_threshold" {
  description = "Trigger an alarm if the Broker has a System CPU utilization percentage above this threshold"
  type        = number
  default     = 90
}

variable "high_memory_utilization_threshold" {
  description = "Trigger an alarm if the Rabbit MQ Broker has a Memory utilization percentage above this threshold"
  type        = number
  default     = 90
}

variable "low_disk_free_threshold" {
  description = "Trigger an alarm if the Rabbit MQ Broker has Disk Free space below this threshold (in bytes)"
  type        = number
  default     = 53687091200 # 50 GiB
}

variable "alarms_sns_topic_arns" {
  description = "List of SNS topic ARNs to which CloudWatch alarm notifications should be sent."
  type        = list(string)
  default     = []
}
