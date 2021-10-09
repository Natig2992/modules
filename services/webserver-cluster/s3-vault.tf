
terraform {
  backend "s3" {
    bucket         = "terraform-up-and-running-state-nat"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-up-and-running-locks-nat"
    encrypt        = true
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state-nat"

  # Предотвращаем случайное удаление этого бакета S3
  lifecycle {

    prevent_destroy = true
  }

  # Включаем управление версиями, чтобы вы могли просматривать всю историю ваших файлов состояния
  versioning {

    enabled = true
  }

  # Включаем шифрование по умолчанию на стороне сервера
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform-locks-1" {
  name         = "terraform-up-and-running-locks-nat"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
