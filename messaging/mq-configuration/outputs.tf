output "configuration_id" {
  description = "The unique ID that Amazon MQ generates for the configuration"
  value       = aws_mq_configuration.configuration.id
}

output "configuration_arn" {
  description = "The ARN of the configuration"
  value       = aws_mq_configuration.configuration.arn
}

output "configuration_latest_revision" {
  description = "The latest revision of the configuration"
  value       = aws_mq_configuration.configuration.latest_revision
}

output "configuration_name" {
  description = "The name of the configuration"
  value       = aws_mq_configuration.configuration.name
}

output "tags_all" {
  description = "Map of tags assigned to the resource, including those inherited from the provider default_tags"
  value       = aws_mq_configuration.configuration.tags_all
}   
