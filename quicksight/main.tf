terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.12.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = ""

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

variable "email" {
  type     = string
  nullable = false
}

resource "aws_quicksight_account_subscription" "subscription" {
  account_name          = "ExampleEnterprise"
  authentication_method = "IAM_AND_QUICKSIGHT"
  edition               = "ENTERPRISE"
  notification_email    = var.email
}

resource "aws_quicksight_data_source" "default" {
  data_source_id = "example-id"
  name           = "Updated"

  parameters {
    s3 {
      manifest_file_location {
        bucket = "ss49919201"
        key    = "data.json"
      }
    }
  }

  type = "S3"

  ssl_properties {
    disable_ssl = false
  }
}

resource "aws_quicksight_data_set" "test" {
  data_set_id = "test-id"
  name        = "test-name"
  import_mode = "SPICE"

  physical_table_map {
    physical_table_map_id = "test"
    s3_source {
      data_source_arn = ""
      input_columns {
        name = "Name"
        type = "STRING"
      }
      upload_settings {
        format = "CSV"
      }
    }
  }

  data_set_parameters {
    string_dataset_parameter {
      id         = "StringID1"
      name       = "StringName1"
      value_type = "SINGLE_VALUED"
      default_values {
        static_values = ["a", "b"]
      }
    }
    string_dataset_parameter {
      id         = "StringID2"
      name       = "StringName2"
      value_type = "MULTI_VALUED"
      default_values {
        static_values = ["a", "b"]
      }
    }
    integer_dataset_parameter {
      id         = "IntegerID1"
      name       = "IntegerName1"
      value_type = "SINGLE_VALUED"
      default_values {
        static_values = [1]
      }
    }
    integer_dataset_parameter {
      id         = "IntegerID2"
      name       = "IntegerName2"
      value_type = "MULTI_VALUED"
      default_values = {
        static_values = [1, 2]
      }
    }
    decimal_dataset_parameter {
      id         = "DecimalID1"
      name       = "DecimalName1"
      value_type = "SINGLE_VALUED"
      default_values = {
        static_values = [1.5]
      }
    }
    decimal_dataset_parameter {
      id         = "DecimalID2"
      name       = "DecimalName2"
      value_type = "MULTI_VALUED"
      default_values = {
        static_values = [1.5, 2.5]
      }
    }
    date_time_dataset_parameter {
      id         = "DateTimeID1"
      name       = "DateTimeName2"
      value_type = "SINGLE_VALUED"
      default_values = {
        static_values = ["1970-01-01"]
      }
      time_granularity_day = "DAY"
    }
    date_time_dataset_parameter {
      id         = "DateTimeID2"
      name       = "DateTimeName2"
      value_type = "MULTI_VALUED"
      default_values = {
        static_values = ["1970-01-01", "1970-01-02"]
      }
      time_granularity_day = "DAY"
    }
  }

  permissions {
    actions = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:UpdateDataSet",
      "quicksight:DeleteDataSet",
      "quicksight:CreateIngestion",
      "quicksight:CancelIngestion",
    "quicksight:UpdateDataSetPermissions"]
    principal = ""
  }
}

resource "aws_quicksight_user" "example" {
  email         = var.email
  namespace     = "default"
  identity_type = "IAM"
  iam_arn       = ""
  user_role     = "AUTHOR"
}
