terraform {
  backend "s3" {
    region         = "eu-central-1"
    bucket         = "softuni-meto-terraform-states"
    key            = "envs/aws-examp/exam-03-08-25.tfstate"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}