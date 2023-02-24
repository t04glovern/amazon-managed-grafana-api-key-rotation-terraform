data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "api_key_rotation_lambda_assume_role_policy_document" {
  statement {
    sid    = "AWSLambdaCanAssumeThisRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "api_key_rotation_lambda_execution_role_policy_document" {
  statement {
    sid    = "AllowSecretsManagerGrafanaApiKey"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
      "secretsmanager:UpdateSecret"
    ]
    resources = [
      aws_secretsmanager_secret.api_key.arn
    ]
  }

  statement {
    sid    = "AllowManagedGrafanaApiKeyManagement"
    effect = "Allow"
    actions = [
      "grafana:CreateWorkspaceApiKey",
      "grafana:DeleteWorkspaceApiKey"
    ]
    resources = [
      "arn:aws:grafana:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:/workspaces/${var.grafana_workspace_id}"
    ]
  }
}
