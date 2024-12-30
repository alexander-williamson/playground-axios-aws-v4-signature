resource "time_static" "example" {}

locals {
  stack_name            = "${var.environment}-aws-signature-playground"
  created_readable_date = formatdate("YYYY-MM-DD_hh-mm-ss", time_static.example.rfc3339)
  build_version         = "v${local.created_readable_date}"
}