# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator when calling this terraform module
# ---------------------------------------------------------------------------------------------------------------------
variable "name" {
  description = "Name of the configuration."
  type        = string
}

variable "engine_type" {
  description = "Type of broker engine. Valid values are ActiveMQ and RabbitMQ."
  type        = string
}

variable "engine_version" {
  description = "Version of the broker engine."
  type        = string
}

variable "configuration_description" {
  description = "Description of the configuration."
  type        = string
  default     = "Managed by Terraform"
}

variable "configuration_data" {
  description = "Broker configuration in XML format for ActiveMQ or Cuttlefish format for RabbitMQ. See AWS documentation for supported parameters and format of the XML."
  type        = string
}

variable "authentication_strategy" {
  description = "Authentication strategy associated with the configuration. Valid values are simple and ldap. ldap is not supported for RabbitMQ engine type."
  type        = string
  default     = null
}

variable "region" {
  description = "The AWS region where the MQ configuration will be created. If not provided, the provider region will be used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Key-value map of tags to assign to the resource. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(string)
  default     = {}
}
