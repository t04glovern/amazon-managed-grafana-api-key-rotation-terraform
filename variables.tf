variable "name" {
  type        = string
  description = "Named identifier for the workspace and related resources"
}

variable "grafana_workspace_id" {
  type        = string
  description = "The ID of the Grafana workspace to manage"
}
