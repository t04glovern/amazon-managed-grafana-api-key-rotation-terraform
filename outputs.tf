output "workspace_api_key" {
  description = "The API key for the AWS Managed Grafana workspace"
  value       = data.aws_secretsmanager_secret_version.api_key.secret_string
  sensitive   = true
}
