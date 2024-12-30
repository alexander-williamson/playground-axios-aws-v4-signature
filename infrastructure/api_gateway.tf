data "aws_vpc" "default" {
  default = true
}

resource "aws_api_gateway_rest_api" "api" {
  name        = local.stack_name
  description = "Rest API for ${local.stack_name}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.proxy" : true
  }
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_method.proxy.resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.any_proxy.invoke_arn

  request_parameters = {
    "integration.request.path.proxy" : "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha256(jsonencode({
      source_sha = data.archive_file.source.output_base64sha256,
      api_body   = jsonencode(aws_api_gateway_rest_api.api.body)
    }))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.lambda]
}

resource "aws_api_gateway_stage" "default" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "default"
  description   = data.archive_file.source.output_base64sha256 // force a redeploy
  depends_on    = [aws_api_gateway_deployment.api]
}

resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.default.stage_name
  method_path = "*/*"
  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

resource "aws_iam_role" "api_gateway_account_role" {
  name = "${local.stack_name}-gateway-account-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_policy_attachment" {
  role       = aws_iam_role.api_gateway_account_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_account_role.arn
}

resource "random_password" "example_api_key" {
  length = 128
}

resource "aws_api_gateway_api_key" "example_api_key" {
  name    = "${local.stack_name}-example-api-key"
  value   = random_password.example_api_key.result
  enabled = true
}

resource "aws_api_gateway_usage_plan_key" "example_api_key" {
  key_id        = aws_api_gateway_api_key.example_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name        = "${local.stack_name}-usage-plan"
  description = "Usage plan"
  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.default.stage_name
  }
}

data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api_policy" "api_policy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${aws_iam_role.access_role.id}/awsume-cli-role"
        },
        "Action": "execute-api:Invoke",
        "Resource": "${aws_api_gateway_rest_api.api.execution_arn}/default/*"
    }
  ]
}
EOF
  depends_on  = [aws_api_gateway_rest_api.api, aws_iam_role.access_role]
}