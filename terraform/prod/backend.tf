terraform {
  backend "gcs" {
    bucket = "infra244120-tfstate-prod"
    prefix = "prod"
  }
}
