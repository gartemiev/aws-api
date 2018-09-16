provider "aws" {
  version = "~> 1.36"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "eu-central-1"
  token = ""
}

provider "aws" {
  alias  = "west"
  region = "eu-west-1"
}

resource "aws_iam_role" "replication" {
  name = "tf-iam-role-replication-12345"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  name = "tf-iam-role-policy-replication-12345"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.source.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.source.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.destination.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "tf-iam-role-attachment-replication-12345"
  roles      = ["${aws_iam_role.replication.name}"]
  policy_arn = "${aws_iam_policy.replication.arn}"
}

resource "aws_s3_bucket" "destination" {
  bucket   = "devbucket3-2018"
  region   = "eu-central-1"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "source" {
  provider = "aws.west"
  bucket   = "devbucket2-2018"

  versioning {
    enabled = true
  }

  replication_configuration {
    role = "${aws_iam_role.replication.arn}"

    rules {
      prefix = "test"
      status = "Enabled"

      destination {
        bucket        = "${aws_s3_bucket.destination.arn}"
        storage_class = "ONEZONE_IA"
      }
    }
  }
}
