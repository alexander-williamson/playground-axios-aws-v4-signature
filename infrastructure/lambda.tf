locals {
  stage_name = "*"
}

resource "aws_lambda_function" "any_proxy" {
  function_name = "${local.stack_name}-any-proxy"

  s3_bucket = aws_s3_object.file_upload.bucket
  s3_key    = aws_s3_object.file_upload.key

  runtime = "nodejs20.x"
  handler = "index.handler"

  role    = aws_iam_role.lambda_role.arn
  timeout = 30

  depends_on = [aws_s3_object.file_upload]
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowLambdaInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.any_proxy.function_name
  principal     = "apigateway.amazonaws.com"

  # https://repost.aws/questions/QUizsg_qznQLWKtqUD8Ruszw/api-gateway-lacks-permissions-to-trigger-lambda-when-made-by-terraform
  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/${local.stage_name}/*/*"
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "../app"
  output_path = "./${local.stack_name}.${local.build_version}.zip"
}

resource "aws_s3_object" "file_upload" {
  bucket      = aws_s3_bucket.assets.id
  key         = "${local.stack_name}.${local.build_version}.zip"
  source      = data.archive_file.source.output_path
  source_hash = data.archive_file.source.output_base64sha256
}