resource "google_service_account" "github_actions_service_account" {
  account_id = var.service_account
  project    = var.project_id
}

locals {
  service_account_roles = [
    "roles/compute.admin",
    "roles/compute.instanceAdmin.v1",
    "roles/compute.osAdminLogin",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin"
  ]
  user_roles = [
    "roles/compute.osLogin",
    "roles/compute.osAdminLogin",
  ]
}

resource "google_project_iam_member" "user_standard_roles" {
  for_each = toset(local.user_roles)

  project = var.project_id
  role    = each.value
  member  = "user:${var.user_email}"
}

resource "google_project_iam_member" "service_account_assigned_roles" {
  for_each = toset(local.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions_service_account.email}"
}

resource "google_service_account_key" "service_account_key" {
  service_account_id = google_service_account.github_actions_service_account.name

  keepers = {
    last_rotation = timestamp()
  }

  private_key_type = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "local_file" "service_account_key_file" {
  content  = base64decode(google_service_account_key.service_account_key.private_key)
  filename = "${path.module}/service_account_key.json"
}
