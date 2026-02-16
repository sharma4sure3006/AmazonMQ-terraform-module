output "broker_id" {
  description = "Unique ID that Amazon MQ generates for the broker"
  value       = aws_mq_broker.broker.id
}

output "broker_arn" {
  description = "ARN of the broker"
  value       = aws_mq_broker.broker.arn
}

output "broker_instances" {
  description = "List of information about allocated brokers"
  value       = aws_mq_broker.broker.instances
}

output "broker_console_url" {
  description = "The URL of the broker's web console"
  value       = try(aws_mq_broker.broker.instances[0].console_url, null)
}

output "security_group_id" {
  description = "ID of the security group created for the broker"
  value       = aws_security_group.broker.id
}
