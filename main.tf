# ///////////////////////////////////////////////////////////////////////////////////////
# // Create resources needed for the Stackdriver Export Sinks
# ///////////////////////////////////////////////////////////////////////////////////////

// Create a BigQuery Dataset for storage of logs
// Note: only the most recent hour's data will be stored based on the table expiration
resource "google_bigquery_dataset" "gcp-bigquery-dataset" {
  dataset_id                  = "${var.dataset}"
  location                    = "${var.location}"
  default_table_expiration_ms = "${var.table_expiration}"
  labels {
    env = "default"
  }
}

# ///////////////////////////////////////////////////////////////////////////////////////
# // Configure the stackdriver sinks and necessary roles.
# // To enable writing to the various export sinks we must grant additional permissions.
# // Refer to the following URL for details:
# // https://cloud.google.com/logging/docs/export/configure_export_v2#dest-auth
# ///////////////////////////////////////////////////////////////////////////////////////

resource "google_logging_organization_sink" "bigquery-sink" {
  name   = "gcp_bigquery_sink"
  org_id = "${var.orgid}"

  # Can export to pubsub, cloud storage, or bigtable
  # destination = "storage.googleapis.com/${google_storage_bucket.gcp-log-bucket.name}"
  //TODO needs a "Protected project to host the logs"
  destination = "bigquery.googleapis.com/projects/${var.project}/datasets/${google_bigquery_dataset.gcp-bigquery-dataset.dataset_id}"

  # Log all WARN or higher severity messages relating to instances
  #filter = "resource.type = bigquery_resource protoPayload.methodName != tabledataservice.list protoPayload.methodName !=jobservice.jobcompleted protoPayload.methodName!= jobservice.getqueryresults"
  filter = "protoPayload.@type = type.googleapis.com/google.cloud.audit.AuditLog"
}


//Grant object creator role for org level big query sink
resource "google_project_iam_binding" "log-writer" {
  # for GCS buckets  # role = "roles/storage.objectCreator"
  # for BigQuery tables
  role = "roles/bigquery.dataEditor"

  members = [
    "${google_logging_organization_sink.bigquery-sink.writer_identity}",
  ]
}
