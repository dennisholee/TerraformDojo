provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

locals {
  appenv = "${var.app}-${var.env}"
}

#-------------------------------------------------------------------------------
# SQS
#-------------------------------------------------------------------------------

resource "aws_sqs_queue" "terraform_queue" {
  name                        = "${local.appenv}-jobs.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

#-------------------------------------------------------------------------------
# Network 
#-------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/24"

  tags = {
    Name = "${local.appenv}-vpc"
    env  = var.env
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "192.168.0.0/26"
  availability_zone = "us-west-2a"

  tags = {
    Name = "${local.appenv}-subnet"
    env  = var.env
  }
}

#-------------------------------------------------------------------------------
# Compute Resource
#-------------------------------------------------------------------------------

# Job Processor
resource "aws_instance" "processor" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet.id

#  network_interface {
#    network_interface_id = aws_network_interface.foo.id
#    device_index         = 0
#  }

  tags = {
    Name = "${local.appenv}-processor"
    env  = var.env
    scheduler-queue = "scheduler-queue"
  }
}

#-------------------------------------------------------------------------------
# CloudWatch Event Notification
#-------------------------------------------------------------------------------

# Processor Instance Event Rule
resource "aws_cloudwatch_event_rule" "processor-launch-event-rule" {
  name        = "processor-launch"
  description = "Capture processor's EC2 is launched"

  event_pattern = <<EOF
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "running"
    ]
  }
}
EOF

  tags = {
    Name = "${local.appenv}-processor-launch-notification"
    env  = var.env
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_job_trigger" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.job-trigger-lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.processor-launch-event-rule.arn
}


resource "aws_cloudwatch_event_target" "processor-launch-event-target" {
  rule      = aws_cloudwatch_event_rule.processor-launch-event-rule.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.job-trigger-lambda.arn
}

#-------------------------------------------------------------------------------
# S3 Bucket for uploading the src code
#-------------------------------------------------------------------------------

# S3 bucket
resource "aws_s3_bucket" "src-bucket" {
  bucket = "${local.appenv}-src-bucket"
  acl    = "private"

  tags = {
    Name        = "${local.appenv}-src-bucket"
    Environment = var.env
  }
}

#-------------------------------------------------------------------------------
# Deploy Job Trigger Lambda 
#-------------------------------------------------------------------------------

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "../job-processor-app/hello-world"
  output_path = "../tmp/processor.zip"
}

resource "aws_s3_bucket_object" "file_upload" {
  bucket = aws_s3_bucket.src-bucket.id
  key    = "lambda-functions/processor.zip"
  source = data.archive_file.source.output_path 
}

resource "aws_iam_role" "role" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_policy" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# resource "aws_iam_role_policy" "frontend_lambda_role_policy" {
#   name   = "frontend-lambda-role-policy"
#   role   = aws_iam_role.role.id
#   policy = data.aws_iam_policy_document.lambda_log_and_invoke_policy.json
# }
# 
# data "aws_iam_policy_document" "lambda_log_and_invoke_policy" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "logs:CreateLogStream",
#       "logs:PutLogEvents"
#     ]
#     resources = [
#       "arn:aws:logs:*:*:*"
#     ]
#   }
# }

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.job-trigger-lambda.function_name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "job-trigger-lambda" {
  function_name = "process-trigger"
  description   = "Dequeue processor running notification to trigger job"
  s3_bucket   = "${local.appenv}-src-bucket"
  s3_key      = aws_s3_bucket_object.file_upload.key 
  memory_size = 1024
  timeout     = 900
  timeouts {
    create = "30m"
  }
  runtime          = "nodejs12.x"
  role             = aws_iam_role.role.arn
  source_code_hash = base64sha256(data.archive_file.source.output_path)
  handler          = "index.handler"
}
