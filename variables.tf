/*
Required Variables
These must be provided at runtime.
*/

variable "zone" {
  description = "The zone in which to create the Kubernetes cluster. Must match the region"
  type        = "string"
  default     = "us-west2-a"
}

variable "orgid" {
  description = "org id"
  type        = "string"
  default     = "315039004509"
}

variable "project" {
  description = "The name of the project."
  type        = "string"
  default     = "forseti-dv"
}

variable "dataset" {
  description = "A name for the GCP BigQuery Dataset"
  type        = "string"
  default     = "gcp_logs"
}

variable "location" {
  description = "The location for the GCP BigQuery dataset"
  type        = "string"
  default     = "US"
}

variable "table_expiration" {
  description = "When should tables expire in microseconds"
  type        = "string"
  default     = "86400000" # set to 24 hours, adjust to match your policy/requirements
}