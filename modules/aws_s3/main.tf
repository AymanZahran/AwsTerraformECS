resource "aws_s3_bucket" "web_access_logs_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
  lifecycle_rule {
      id      = "log"
      enabled = true

      tags = {
        rule      = "access_log_auto_clean"
        autoclean = "true"
      }

      expiration {
        days = 30
      }
    }
}
