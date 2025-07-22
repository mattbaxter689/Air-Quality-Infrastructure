provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_compute_instance" "default_vm" {
  depends_on   = [google_project_service.compute_api]
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["ssh", "image-access"]

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/scripts/startup.sh.tpl", {
    DOCKER_COMPOSE_VERSION = "v2.23.0"
  })
}


resource "google_compute_firewall" "allow_image_access" {
  depends_on = [google_project_service.compute_api]
  name       = "allow-image-access"
  network    = "default"

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["3000", "5000", "8000", "9000", "9001"]
  }

  source_ranges = [var.user_ip]

  target_tags = ["image-access"]
}

resource "google_compute_firewall" "allow_ssh" {
  depends_on = [google_project_service.compute_api]
  name       = "allow-ssh"
  network    = "default"

  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.user_ip]

  target_tags = ["ssh"]
}

output "vm_external_ip" {
  description = "The external IP address of the VM"
  value       = google_compute_instance.default_vm.network_interface[0].access_config[0].nat_ip
}
