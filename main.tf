resource "aws_secretsmanager_secret" "api_key" {
  name = "${var.name}-api-key"
}

data "archive_file" "api_key_lambda" {
  type        = "zip"
  source_file = "${path.module}/src/rotate.py"
  output_path = "${path.module}/bundle.zip"
}

resource "aws_iam_role" "api_key_rotation_lambda_role" {
  name               = "lambda-api-key-rotation-role-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.api_key_rotation_lambda_assume_role_policy_document.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

resource "aws_iam_role_policy" "api_key_rotation_lambda_policy" {
  policy = data.aws_iam_policy_document.api_key_rotation_lambda_execution_role_policy_document.json
  role   = aws_iam_role.api_key_rotation_lambda_role.id
}

resource "aws_lambda_function" "api_key_rotation" {
  function_name = "${var.name}-api-key-rotation"

  filename         = data.archive_file.api_key_lambda.output_path
  source_code_hash = data.archive_file.api_key_lambda.output_base64sha256

  handler = "rotate.lambda_handler"
  runtime = "python3.9"
  environment {
    variables = {
      GRAFANA_API_SECRET_ARN = aws_secretsmanager_secret.api_key.arn
      GRAFANA_API_KEY_NAME   = "${var.name}-mangement-api-key"
      GRAFANA_WORKSPACE_ID   = var.grafana_workspace_id
    }
  }

  role = aws_iam_role.api_key_rotation_lambda_role.arn
}

resource "aws_lambda_permission" "secrets_manager_api_key_rotation" {
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_key_rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_secretsmanager_secret_rotation" "api_key" {
  secret_id           = aws_secretsmanager_secret.api_key.id
  rotation_lambda_arn = aws_lambda_function.api_key_rotation.arn

  rotation_rules {
    automatically_after_days = 29
  }
}

resource "null_resource" "api_key_delay" {
  provisioner "local-exec" {
    command = "sleep 20"
  }
  triggers = {
    after = aws_secretsmanager_secret_rotation.api_key.id
  }
}

data "aws_secretsmanager_secret" "api_key" {
  depends_on = [
    null_resource.api_key_delay
  ]
  arn = aws_secretsmanager_secret.api_key.arn
}

data "aws_secretsmanager_secret_version" "api_key" {
  secret_id = data.aws_secretsmanager_secret.api_key.id
}
