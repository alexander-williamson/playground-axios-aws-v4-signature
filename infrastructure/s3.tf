resource "aws_s3_bucket" "assets" {
  bucket = "${local.stack_name}-assets"
}