# ///////////////////////////////////////////////////////////////////////////////////////
# // Create resources needed for the Stackdriver Export Sinks
# ///////////////////////////////////////////////////////////////////////////////////////

// Create a BigQuery Dataset for storage of logs
// Note: only the most recent hour's data will be stored based on the table expiration
resource "google_bigquery_dataset" "gcp-bigquery-dataset" {
  dataset_id                  = "${var.dataset}"
  location                    = "${var.location}"
  default_table_expiration_ms = 86400000          # set to 24 hours, adjust to match your policy/requirements

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

//TODO Create org level sinks
resource "google_logging_organization_sink" "gce-instance-sink" {
  name   = "gce-instance-sink"
  org_id = "${var.orgid}"

  # Can export to pubsub, cloud storage, or bigtable
  # destination = "storage.googleapis.com/${google_storage_bucket.gcp-log-bucket.name}"
  destination = "bigquery.googleapis.com/projects/${var.project}/datasets/${google_bigquery_dataset.gcp-bigquery-dataset.dataset_id}"

  # /tables/gce_instance"

  # Log all WARN or higher severity messages relating to instances
  # filter = "*"
  # "resource.type = gce_instance" 
  # severity>=WARNING"
}

resource "google_logging_organization_sink" "bigquery-sink" {
  name   = "gcp_bigquery_sink"
  org_id = "${var.orgid}"

  # Can export to pubsub, cloud storage, or bigtable
  # destination = "storage.googleapis.com/${google_storage_bucket.gcp-log-bucket.name}"
  //TODO needs a "Protected project to host the logs"
  destination = "bigquery.googleapis.com/projects/${var.project}/datasets/${google_bigquery_dataset.gcp-bigquery-dataset.dataset_id}"

  # Log all WARN or higher severity messages relating to instances
  filter = "resource.type = bigquery_resource protoPayload.methodName != tabledataservice.list protoPayload.methodName !=jobservice.jobcompleted protoPayload.methodName!= jobservice.getqueryresults"
}

resource "google_logging_organization_sink" "firewall-rule" {
  name   = "firewall-rule"
  org_id = "${var.orgid}"

  # Can export to pubsub, cloud storage, or bigtable
  # destination = "storage.googleapis.com/${google_storage_bucket.gcp-log-bucket.name}"
  //TODO needs a "Protected project to host the logs"
  destination = "bigquery.googleapis.com/projects/${var.project}/datasets/${google_bigquery_dataset.gcp-bigquery-dataset.dataset_id}"

  # Log all WARN or higher severity messages relating to instances
  filter = "resource.type = firewall-rule"
}

//Grant object creator role for org level big query sink
resource "google_project_iam_binding" "log-writer" {
  # for GCS buckets  # role = "roles/storage.objectCreator"

  # for BigQuery tables
  role = "roles/bigquery.dataEditor"

  members = [
    "${google_logging_organization_sink.gce-instance-sink.writer_identity}",
    "${google_logging_organization_sink.firewall-rule.writer_identity}",
    "${google_logging_organization_sink.bigquery-sink.writer_identity}",
  ]
}
