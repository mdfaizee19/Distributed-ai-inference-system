# Main Terraform configuration for GCP infrastructure.
# Defines VPC, subnet, firewall, and compute instance provisioning.

resource "google_compute_network" "private_vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
  description             = "Private VPC for API gateway and internal workers."
}

resource "google_compute_subnetwork" "public_api_subnet" {
  name          = "${var.project_id}-api-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.private_vpc.id
  description   = "Public subnet for the API gateway VM."
}

resource "google_compute_subnetwork" "private_worker_subnet" {
  name          = "${var.project_id}-worker-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.private_vpc.id
  description   = "Private subnet for internal worker VMs."
}

resource "google_compute_firewall" "allow_api_public" {
  name        = "${var.project_id}-allow-api-public"
  network     = google_compute_network.private_vpc.name
  description = "Allow external HTTP/HTTPS traffic to the API gateway VM (targeted)."

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["api-gateway"]
}

resource "google_compute_firewall" "allow_internal_worker" {
  name        = "${var.project_id}-allow-internal-worker"
  network     = google_compute_network.private_vpc.name
  description = "Allow internal traffic between API gateway and worker VMs on private IPs only (targeted)."

  allow {
    protocol = "tcp"
    ports    = ["5000-5010"]
  }

  # Restrict to the explicitly defined subnets instead of a /16.
  source_ranges = [google_compute_subnetwork.public_api_subnet.ip_cidr_range, google_compute_subnetwork.private_worker_subnet.ip_cidr_range]
  target_tags   = ["worker"]
}

resource "google_compute_instance" "api_gateway" {
  name         = "${var.project_id}-api-gateway"
  machine_type = var.api_machine_type
  zone         = var.zone
  tags         = ["api-gateway"]

  boot_disk {
    initialize_params {
      image = var.instance_image
    }
  }

  network_interface {
    network    = google_compute_network.private_vpc.id
    subnetwork = google_compute_subnetwork.public_api_subnet.id
    access_config {
      # Public external IP for the API gateway VM.
    }
  }

  service_account {
    email  = google_service_account.api_gateway.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    repo_url      = var.repo_url
    startup-script = <<-EOT
      #!/bin/bash
      set -e
      REPO_URL="${var.repo_url}"
      # Install runtime
      apt-get update -y
      apt-get install -y python3 python3-pip python3-venv git

      # Ensure code is present
      if [ -n "$REPO_URL" ] && [ ! -d /opt/distributed-ai-inference-system ]; then
        git clone "$REPO_URL" /opt/distributed-ai-inference-system || true
      fi

      # Install API dependencies if present
      if [ -f /opt/distributed-ai-inference-system/api/requirements.txt ]; then
        pip3 install --upgrade pip
        pip3 install -r /opt/distributed-ai-inference-system/api/requirements.txt
      fi

      # Create a simple systemd unit
      cat > /etc/systemd/system/api.service <<-UNIT
      [Unit]
      Description=API Gateway Service
      After=network.target

      [Service]
      Type=simple
      ExecStart=/usr/bin/python3 /opt/distributed-ai-inference-system/api/app.py
      Restart=always
      User=root

      [Install]
      WantedBy=multi-user.target
      UNIT

      systemctl daemon-reload
      systemctl enable api.service
      systemctl restart api.service || true
    EOT
  }
}

resource "google_compute_instance" "python_worker" {
  name         = "${var.project_id}-python-worker"
  machine_type = var.worker_machine_type
  zone         = var.zone
  tags         = ["worker"]

  boot_disk {
    initialize_params {
      image = var.instance_image
    }
  }

  network_interface {
    network    = google_compute_network.private_vpc.id
    subnetwork = google_compute_subnetwork.private_worker_subnet.id
    # No access_config block means no external IP on worker VMs.
  }

  service_account {
    email  = google_service_account.python_worker.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    repo_url      = var.repo_url
    startup-script = <<-EOT
      #!/bin/bash
      set -e
      REPO_URL="${var.repo_url}"
      apt-get update -y
      apt-get install -y python3 python3-pip git

      if [ -n "$REPO_URL" ] && [ ! -d /opt/distributed-ai-inference-system ]; then
        git clone "$REPO_URL" /opt/distributed-ai-inference-system || true
      fi

      if [ -f /opt/distributed-ai-inference-system/workers/python-worker/requirements.txt ]; then
        pip3 install --upgrade pip
        pip3 install -r /opt/distributed-ai-inference-system/workers/python-worker/requirements.txt
      fi

      cat > /etc/systemd/system/python-worker.service <<-UNIT
      [Unit]
      Description=Python Worker Service
      After=network.target

      [Service]
      Type=simple
      ExecStart=/usr/bin/python3 /opt/distributed-ai-inference-system/workers/python-worker/worker.py
      Restart=always
      User=root

      [Install]
      WantedBy=multi-user.target
      UNIT

      systemctl daemon-reload
      systemctl enable python-worker.service
      systemctl restart python-worker.service || true
    EOT
  }
}

resource "google_compute_instance" "node_worker" {
  name         = "${var.project_id}-node-worker"
  machine_type = var.worker_machine_type
  zone         = var.zone
  tags         = ["worker"]

  boot_disk {
    initialize_params {
      image = var.instance_image
    }
  }

  network_interface {
    network    = google_compute_network.private_vpc.id
    subnetwork = google_compute_subnetwork.private_worker_subnet.id
    # No external IP for private internal-only Node.js worker.
  }

  service_account {
    email  = google_service_account.node_worker.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata = {
    repo_url      = var.repo_url
    startup-script = <<-EOT
      #!/bin/bash
      set -e
      REPO_URL="${var.repo_url}"
      apt-get update -y
      apt-get install -y curl git
      # Install Node.js 18.x (Nodesource)
      curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
      apt-get install -y nodejs build-essential

      if [ -n "$REPO_URL" ] && [ ! -d /opt/distributed-ai-inference-system ]; then
        git clone "$REPO_URL" /opt/distributed-ai-inference-system || true
      fi

      if [ -d /opt/distributed-ai-inference-system/workers/node-worker ]; then
        cd /opt/distributed-ai-inference-system/workers/node-worker
        npm install --production || true
      fi

      cat > /etc/systemd/system/node-worker.service <<-UNIT
      [Unit]
      Description=Node Worker Service
      After=network.target

      [Service]
      Type=simple
      ExecStart=/usr/bin/node /opt/distributed-ai-inference-system/workers/node-worker/worker.js
      Restart=always
      User=root

      [Install]
      WantedBy=multi-user.target
      UNIT

      systemctl daemon-reload
      systemctl enable node-worker.service
      systemctl restart node-worker.service || true
    EOT
  }
}

# Minimal service accounts for instances
resource "google_service_account" "api_gateway" {
  account_id   = "api-gateway-sa"
  display_name = "API Gateway service account"
}

resource "google_service_account" "python_worker" {
  account_id   = "python-worker-sa"
  display_name = "Python Worker service account"
}

resource "google_service_account" "node_worker" {
  account_id   = "node-worker-sa"
  display_name = "Node Worker service account"
}

# Grant minimal logging and monitoring roles to each service account
resource "google_project_iam_member" "api_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.api_gateway.email}"
}

resource "google_project_iam_member" "api_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.api_gateway.email}"
}

resource "google_project_iam_member" "python_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.python_worker.email}"
}

resource "google_project_iam_member" "python_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.python_worker.email}"
}

resource "google_project_iam_member" "node_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node_worker.email}"
}

resource "google_project_iam_member" "node_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node_worker.email}"
}
