provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

locals {
  appenv       = "${var.app}-${var.env}"
  s3_origin_id = var.app 
}


#-------------------------------------------------------------------------------
# S3 Bucket for logs
#-------------------------------------------------------------------------------

resource "aws_s3_bucket" "log-bucket" {
  bucket = "${local.appenv}-log-bucket"
  acl    = "private"
}

#-------------------------------------------------------------------------------
# S3 Bucket for uploading the src code
#-------------------------------------------------------------------------------

# S3 bucket
resource "aws_s3_bucket" "www-bucket" {
  bucket = "${local.appenv}-web-bucket"
  acl    = "private"

  website {
    index_document = "index.html"
  }

  tags = {
    Name        = "${local.appenv}-www-bucket"
    Environment = var.env
  }
}

#data "archive_file" "source" {
#  type        = "zip"
#  source_dir  = "../src"
#  output_path = "../tmp/src.zip"
#}
#
#resource "aws_s3_bucket_object" "file_upload" {
#  bucket = aws_s3_bucket.www-bucket.id
#  key    = "src.zip"
#  source = data.archive_file.source.output_path
#}

resource "aws_s3_bucket_object" "dist" {
  for_each = fileset("../src", "*")

  bucket = aws_s3_bucket.www-bucket.id
  key    = each.value
  source = "../src/${each.value}"
  etag   = filemd5("../src/${each.value}")
  content_type = "text/html"
  content_encoding = "UTF-8"
}

# ACL

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
}

data "aws_iam_policy_document" "www_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.www-bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.www-bucket.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.www-bucket.id
  policy = data.aws_iam_policy_document.www_s3_policy.json
}

#-------------------------------------------------------------------------------
# Enable CDN 
#-------------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.www-bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.log-bucket.bucket_domain_name
    prefix          = ""
  }

  #aliases = ["mysite.example.com", "yoursite.example.com"]

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"] #["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["HEAD", "GET"] #["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    realtime_log_config_arn = aws_cloudfront_realtime_log_config.cloudfront-rt-log-config.arn
  }

#  ordered_cache_behavior {
#    path_pattern     = "/content/immutable/*"
#    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#    cached_methods   = ["GET", "HEAD", "OPTIONS"]
#    target_origin_id = local.s3_origin_id
#
#    forwarded_values {
#      query_string = false
#      headers      = ["Origin"]
#
#      cookies {
#        forward = "none"
#      }
#    }
#
#    min_ttl                = 0
#    default_ttl            = 86400
#    max_ttl                = 31536000
#    compress               = true
#    viewer_protocol_policy = "allow-all" #"redirect-to-https"
#  }
#
#  ordered_cache_behavior {
#    path_pattern     = "/content/*"
#    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#    cached_methods   = ["GET", "HEAD"]
#    target_origin_id = local.s3_origin_id
#
#    forwarded_values {
#      query_string = false
#
#      cookies {
#        forward = "none"
#      }
#    }
#
#    min_ttl                = 0
#    default_ttl            = 3600
#    max_ttl                = 86400
#    compress               = true
#    viewer_protocol_policy = "redirect-to-https"
#  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none" #"whitelist"
      #locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = var.env
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

#-------------------------------------------------------------------------------
# Kinesis Data Stream to Lambda
#-------------------------------------------------------------------------------

resource "aws_kinesis_stream" "cloudfront-kstream" {
  name             = "cloudfront-kstream"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = {
    Environment = var.env
  }
}

resource "aws_cloudfront_realtime_log_config" "cloudfront-rt-log-config" {
  name = "test_realtime_log_config"
  sampling_rate = 50

  fields = [
    "timestamp",
    "c-ip",
    "time-to-first-byte",
    "sc-status",
  ]

  endpoint {
     stream_type = "Kinesis"
     kinesis_stream_config {
       role_arn = aws_iam_role.cloudfront-realtime-log-config-role.arn
       stream_arn = aws_kinesis_stream.cloudfront-kstream.arn
     }
  }

}

resource "aws_iam_policy" "policy" {
  name        = "test_policy"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStreamSummary",
                "kinesis:DescribeStream",
                "kinesis:ListStreams",
                "kinesis:PutRecord",
                "kinesis:PutRecords"
            ],
            "Resource": [
                "${aws_kinesis_stream.cloudfront-kstream.arn}"
            ]
        }
    ]
  })
}

resource "aws_iam_role" "cloudfront-realtime-log-config-role" {
  name = "CloudFrontRealtimeLogConfigRole-App"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Environment = var.env
  }
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.cloudfront-realtime-log-config-role.name
  policy_arn = aws_iam_policy.policy.arn
}

#-------------------------------------------------------------------------------
# Kinesis Data Analytics App - Pushes data from Kinesis to Timestream 
#-------------------------------------------------------------------------------

resource "aws_s3_bucket" "src-bucket" {
  bucket = "${local.appenv}-src-bucket"
  acl    = "private"

  tags = {
    Name        = "${local.appenv}-src-bucket"
    Environment = var.env
  }
}

resource "aws_s3_bucket_object" "kinesis-app-zip" {
  bucket = aws_s3_bucket.src-bucket.id
  key    = "aws-kinesis-analytics-java-apps-1.0.jar"
  source = "../DataStream/target/aws-kinesis-analytics-java-apps-1.0.jar"
}

resource "aws_iam_role" "kinesis-app-iam-role" {
  name = "kinesis-app-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "kinesisanalytics.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Environment = var.env
  }
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_policy-01" {
  role       = aws_iam_role.kinesis-app-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_policy-02" {
  role       = aws_iam_role.kinesis-app-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonTimestreamFullAccess"
}


resource "aws_iam_role_policy_attachment" "terraform_lambda_policy-03" {
  role       = aws_iam_role.kinesis-app-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_kinesisanalyticsv2_application" "kinesis-app" {
  name                   = "kinesis-app"
  runtime_environment    = "FLINK-1_11"
  service_execution_role = aws_iam_role.kinesis-app-iam-role.arn

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = aws_s3_bucket.src-bucket.arn
          file_key   = aws_s3_bucket_object.kinesis-app-zip.key
        }
      }

      code_content_type = "ZIPFILE"
    }

#    environment_properties {
#      property_group {
#        property_group_id = "PROPERTY-GROUP-1"
#
#        property_map = {
#          Key1 = "Value1"
#        }
#      }
#
#      property_group {
#        property_group_id = "PROPERTY-GROUP-2"
#
#        property_map = {
#          KeyA = "ValueA"
#          KeyB = "ValueB"
#        }
#      }
#    }
#
    flink_application_configuration {
      checkpoint_configuration {
        configuration_type = "DEFAULT"
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "DEBUG"
        metrics_level      = "TASK"
      }

      parallelism_configuration {
        auto_scaling_enabled = true
        configuration_type   = "CUSTOM"
        parallelism          = 10
        parallelism_per_kpu  = 4
      }
    }
  }

  tags = {
    Environment = var.env
  }
}

#-------------------------------------------------------------------------------
# Timestream DB
#-------------------------------------------------------------------------------

#resource "aws_timestreamwrite_database" "timestream-db" {
#  database_name = "${local.appenv}-timestream-db"
#  kms_key_id    = "string"
#  tags = {
#      Name = "value"
#  }
#}
#
#resource "aws_timestreamwrite_table" "cloudfront_timestream" {
#  database_name = aws_timestreamwrite_database.database_name
#  table_name    = "string"
#  retention_properties {
#    magnetic_store_retention_period_in_days = 10
#    memory_store_retention_period_in_hours  = 10
#  }
#  tags = {
#    Name = "value"
#  }
#}
