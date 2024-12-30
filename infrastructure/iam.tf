resource "aws_iam_role" "lambda_role" {
  name               = "${local.stack_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.allow_assume_role.json
}

data "aws_iam_policy_document" "allow_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.iam_user_arn]
    }
  }
}

data "aws_iam_policy_document" "access_policy" {
  statement {
    effect  = "Allow"
    actions = ["execute-api:Invoke"]
    resources = [
      "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*",
    ]
  }
}

resource "aws_iam_policy" "access_policy" {
  name       = "${local.stack_name}-access-policy"
  policy     = data.aws_iam_policy_document.access_policy.json
  depends_on = [aws_api_gateway_rest_api.api]
}

resource "aws_iam_role" "access_role" {
  name               = "${local.stack_name}-access-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy_attachment" "access_role_attachment" {
  name       = "${local.stack_name}-access-role-attachment"
  policy_arn = aws_iam_policy.access_policy.arn
  roles      = [aws_iam_role.access_role.name]
}