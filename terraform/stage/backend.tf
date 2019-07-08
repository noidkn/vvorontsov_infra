terraform {
  backend "gcs" {
    bucket = "infra244120-tfstate-stage"
    prefix = "stage"
  }
}
