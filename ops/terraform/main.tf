provider "google" {
  project = var.gcp_project
  region  = var.region
  zone    = var.zone
}

terraform {
  backend "gcs" {
    # this bucket lives in the bacalhau-infra google project
    # https://console.cloud.google.com/storage/browser/bacalhau-infrastructure-state;tab=objects?project=bacalhau-infra
    bucket = "bacalhau-infrastructure-state"
    prefix = "terraform"
  }
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "bacalhau_vm" {
  name         = "bacalhau-vm-${terraform.workspace}-${count.index}"
  count        = var.instance_count
  machine_type = count.index >= var.instance_count - var.num_gpu_machines ? var.gpu_machine_type : var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = var.boot_disk_size_gb
    }
  }

  metadata_startup_script = <<-EOF
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

sudo mkdir -p /terraform_node

##############################
# export the terraform variables ready for scripts to use
# we write these to a file so the bacalhau startup script
# called by systemd can also source them
##############################

sudo tee /terraform_node/variables > /dev/null <<'EOI'
export TERRAFORM_WORKSPACE="${terraform.workspace}"
export TERRAFORM_NODE_INDEX="${count.index}"
export TERRAFORM_NODE0_IP="${var.public_ip_addresses[0]}"
export TERRAFORM_NODE1_IP="${var.instance_count > 1 ? var.public_ip_addresses[1] : ""}"
export TERRAFORM_NODE2_IP="${var.instance_count > 2 ? var.public_ip_addresses[2] : ""}"
export IPFS_VERSION="${var.ipfs_version}"
export LOG_LEVEL="${var.log_level}"
export BACALHAU_ENVIRONMENT="${var.bacalhau_environment != "" ? var.bacalhau_environment : terraform.workspace}"
export BACALHAU_VERSION="${var.bacalhau_version}"
export BACALHAU_BRANCH="${var.bacalhau_branch}"
export BACALHAU_PORT="${var.bacalhau_port}"
export BACALHAU_UNSAFE_CLUSTER="${var.bacalhau_unsafe_cluster ? "yes" : ""}"
export BACALHAU_NODE_TYPE="${count.index == 0 ? "requester,compute" : "compute"}"
export BACALHAU_NODE_WEBUI="${var.web_ui_enabled && count.index == 0 ? "true" : "false"}"
export BACALHAU_NODE0_UNSAFE_ID="QmUqesBmpC7pSzqH86ZmZghtWkLwL6RRop3M1SrNbQN5QD"
export GPU_NODE="${count.index >= var.instance_count - var.num_gpu_machines ? "true" : "false"}"
export GRAFANA_CLOUD_PROMETHEUS_USER="${var.grafana_cloud_prometheus_user}"
export GRAFANA_CLOUD_PROMETHEUS_ENDPOINT="${var.grafana_cloud_prometheus_endpoint}"
export GRAFANA_CLOUD_LOKI_USER="${var.grafana_cloud_loki_user}"
export GRAFANA_CLOUD_LOKI_ENDPOINT="${var.grafana_cloud_loki_endpoint}"
export LOKI_VERSION="${var.loki_version}"
export GRAFANA_CLOUD_TEMPO_USER="${var.grafana_cloud_tempo_user}"
export GRAFANA_CLOUD_TEMPO_ENDPOINT="${var.grafana_cloud_tempo_endpoint}"
export OTEL_COLLECTOR_VERSION="${var.otel_collector_version}"
export OTEL_EXPORTER_OTLP_ENDPOINT="${var.otel_collector_endpoint}"
export OTEL_RESOURCE_ATTRIBUTES="deployment.environment=${terraform.workspace}"
export BACALHAU_ORCHESTRATORS="${var.internal_ip_addresses[0]}:4222"
export BACALHAU_ORCHESTRATOR_ADVERTISE="${var.public_ip_addresses[count.index]}:4222"
export BACALHAU_LOCAL_PUBLISHER_ADDRESS="${var.public_ip_addresses[count.index]}"

### secrets are installed in the install-node.sh script
export SECRETS_GRAFANA_CLOUD_PROMETHEUS_API_KEY="${var.grafana_cloud_prometheus_api_key}"
export SECRETS_GRAFANA_CLOUD_TEMPO_API_KEY="${var.grafana_cloud_tempo_api_key}"
export SECRETS_GRAFANA_CLOUD_LOKI_API_KEY="${var.grafana_cloud_loki_api_key}"
export SECRETS_AWS_ACCESS_KEY_ID="${var.aws_access_key_id}"
export SECRETS_AWS_SECRET_ACCESS_KEY="${var.aws_secret_access_key}"
export SECRETS_DOCKER_USERNAME="${var.docker_username}"
export SECRETS_DOCKER_PASSWORD="${var.docker_password}"
EOI

##############################
# Install and configure Ops Agent
##############################

# Install the Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install

# Configure Ops Agent
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null << EOA
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]
EOA

# Restart Ops Agent to apply configuration
sudo systemctl restart google-cloud-ops-agent"*"

##############################
# write the local files to the node filesystem
##############################

#########
# node scripts
#########

sudo mkdir -p /terraform_node

sudo tee /terraform_node/bacalhau-unsafe-private-key > /dev/null <<'EOI'
${var.bacalhau_unsafe_cluster ? file("${path.module}/remote_files/configs/unsafe-private-key") : ""}
EOI

sudo tee /terraform_node/install-node.sh > /dev/null <<'EOI'
${file("${path.module}/remote_files/scripts/install-node.sh")}
EOI

sudo tee /terraform_node/start-bacalhau.sh > /dev/null <<'EOI'
${file("${path.module}/remote_files/scripts/start-bacalhau.sh")}
EOI

sudo tee /terraform_node/apply-http-allowlist.sh > /dev/null <<'EOI'
${file("${path.module}/remote_files/scripts/apply-http-allowlist.sh")}
EOI
chmod +x /terraform_node/apply-http-allowlist.sh

sudo tee /terraform_node/http-domain-allowlist.txt > /dev/null <<'EOI'
${file("${path.module}/remote_files/scripts/http-domain-allowlist.txt")}
EOI

#########
# health checker
#########

sudo mkdir -p /var/www/health_checker

# this will be copied to the correct location once openresty has installed to avoid
# an interactive prompt warning about the file existing blocking the headless install
sudo tee /terraform_node/nginx.conf > /dev/null <<'EOI'
${file("${path.module}/remote_files/health_checker/nginx.conf")}
EOI

sudo tee /var/www/health_checker/livez.sh > /dev/null <<'EOI'
${file("${path.module}/remote_files/health_checker/livez.sh")}
EOI

sudo tee /var/www/health_checker/healthz.sh > /dev/null <<'EOI'
${file("${path.module}/remote_files/health_checker/healthz.sh")}
EOI

sudo tee /var/www/health_checker/network_name.txt > /dev/null <<EOI
${var.auto_subnets ? google_compute_network.bacalhau_network[0].name : google_compute_network.bacalhau_network_manual[0].name}
EOI

sudo tee /var/www/health_checker/address.txt > /dev/null <<EOI
${var.protect_resources ? google_compute_address.ipv4_address[count.index].address : google_compute_address.ipv4_address_unprotected[count.index].address}
EOI

sudo chmod u+x /var/www/health_checker/*.sh

#########
# systemd units
#########

sudo tee /etc/systemd/system/ipfs.service > /dev/null <<'EOI'
${file("${path.module}/remote_files/configs/ipfs.service")}
EOI

sudo tee /etc/systemd/system/bacalhau.service > /dev/null <<'EOI'
${file("${path.module}/remote_files/configs/bacalhau.service")}
EOI

sudo tee /etc/systemd/system/otel.service > /dev/null <<'EOI'
${file("${path.module}/remote_files/configs/otel.service")}
EOI

sudo tee /etc/systemd/system/promtail.service > /dev/null <<'EOI'
${file("${path.module}/remote_files/configs/promtail.service")}
EOI

##############################
# run the install script
##############################

sudo bash /terraform_node/install-node.sh 2>&1 | tee -a /tmp/bacalhau.log
EOF
  network_interface {
    network    = var.auto_subnets ? google_compute_network.bacalhau_network[0].name : google_compute_network.bacalhau_network_manual[0].name
    subnetwork = var.auto_subnets ? "" : google_compute_subnetwork.bacalhau_subnetwork_manual[0].name
    network_ip = var.internal_ip_addresses[count.index]
    access_config {
      nat_ip = var.protect_resources ? google_compute_address.ipv4_address[count.index].address : google_compute_address.ipv4_address_unprotected[count.index].address
    }
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }

  # Add service account for Ops Agent
  service_account {
    scopes = ["cloud-platform"]
  }

  allow_stopping_for_update = true

  scheduling {
    // Required for GPU. See https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance#guest_accelerator
    on_host_maintenance = count.index >= var.instance_count - var.num_gpu_machines ? "TERMINATE" : ""
  }

  // GPUs are accelerators
  guest_accelerator {
    type  = count.index >= var.instance_count - var.num_gpu_machines ? var.gpu_type : ""
    count = count.index >= var.instance_count - var.num_gpu_machines ? var.num_gpus_per_machine : 0
  }

  # Add labels for Ops Agent
  labels = {
    managed-by-ops-agent = "true"
    environment          = terraform.workspace
  }
}

# Add IAM role binding for Ops Agent
resource "google_project_iam_binding" "ops_agent_iam" {
  project = var.gcp_project
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_compute_instance.bacalhau_vm[0].service_account[0].email}",
  ]
}

resource "google_compute_address" "ipv4_address" {
  region = var.region
  name   = "bacalhau-ipv4-address-${terraform.workspace}-${count.index}"
  count  = var.protect_resources ? var.instance_count : 0
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_address" "ipv4_address_unprotected" {
  name  = "bacalhau-ipv4-address-${terraform.workspace}-${count.index}"
  count = var.protect_resources ? 0 : var.instance_count
}

output "public_ip_address" {
  value = google_compute_instance.bacalhau_vm.*.network_interface.0.access_config.0.nat_ip
}

resource "google_compute_disk" "bacalhau_disk" {
  name     = "bacalhau-disk-${terraform.workspace}-${count.index}"
  count    = var.protect_resources ? var.instance_count : 0
  type     = "pd-ssd"
  zone     = var.zone
  size     = var.volume_size_gb
  snapshot = var.restore_from_backup
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_disk" "bacalhau_disk_unprotected" {
  name     = "bacalhau-disk-${terraform.workspace}-${count.index}"
  count    = var.protect_resources ? 0 : var.instance_count
  type     = "pd-ssd"
  zone     = var.zone
  size     = var.volume_size_gb
  snapshot = var.restore_from_backup
}

resource "google_compute_disk_resource_policy_attachment" "attachment" {
  name  = google_compute_resource_policy.bacalhau_disk_backups[count.index].name
  disk  = var.protect_resources ? google_compute_disk.bacalhau_disk[count.index].name : google_compute_disk.bacalhau_disk_unprotected[count.index].name
  zone  = var.zone
  count = var.instance_count
}

resource "google_compute_resource_policy" "bacalhau_disk_backups" {
  name   = "bacalhau-disk-backups-${terraform.workspace}-${count.index}"
  region = var.region
  count  = var.instance_count
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "23:00"
      }
    }
    retention_policy {
      max_retention_days    = 30
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      labels = {
        bacalhau_backup = "true"
      }
      # this only works with Windows and looks like it's non-negotiable with gcp
      guest_flush = false
    }
  }
}

resource "google_compute_attached_disk" "default" {
  disk     = var.protect_resources ? google_compute_disk.bacalhau_disk[count.index].self_link : google_compute_disk.bacalhau_disk_unprotected[count.index].self_link
  instance = google_compute_instance.bacalhau_vm[count.index].self_link
  count    = var.instance_count
  zone     = var.zone
}

resource "google_compute_firewall" "bacalhau_ingress_firewall" {
  name    = "bacalhau-ingress-firewall-${terraform.workspace}"
  network = var.auto_subnets ? google_compute_network.bacalhau_network[0].name : google_compute_network.bacalhau_network_manual[0].name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [
      "80",    // web ui
      "4001",  // ipfs swarm
      "1234",  // bacalhau API
      "1235",  // bacalhau swarm
      "6001",  // local publisher httpd - compute nodes
      "13133", // otel collector health_check extension
      "55679", // otel collector zpages extension
      "44443", // nginx is healthy - for running health check scripts
      "44444", // nginx node health check scripts
      "4222",  // nats
      "6222",  // nats cluster
    ]
  }

  allow {
    protocol = "udp"
    ports = [
      "4001", // ipfs swarm
      "1235", // bacalhau swarm
    ]
  }

  source_ranges = var.ingress_cidrs
}

resource "google_compute_firewall" "bacalhau_egress_firewall" {
  name    = "bacalhau-egress-firewall-${terraform.workspace}"
  network = var.auto_subnets ? google_compute_network.bacalhau_network[0].name : google_compute_network.bacalhau_network_manual[0].name

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports = [
      "4001", // ipfs swarm
      "1235", // bacalhau swarm
      "4222", // nats
      "6222", // nats cluster
    ]
  }

  allow {
    protocol = "udp"
    ports = [
      "4001", // ipfs swarm
      "1235", // bacalhau swarm
    ]
  }

  source_ranges = var.egress_cidrs
}

resource "google_compute_firewall" "bacalhau_ssh_firewall" {
  name    = "bacalhau-ssh-firewall-${terraform.workspace}"
  network = var.auto_subnets ? google_compute_network.bacalhau_network[0].name : google_compute_network.bacalhau_network_manual[0].name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    // Port 22   - Provides ssh access to the bacalhau server, for debugging
    ports = ["22"]
  }

  source_ranges = var.ssh_access_cidrs
}

resource "google_compute_network" "bacalhau_network" {
  name                    = "bacalhau-network-${terraform.workspace}"
  auto_create_subnetworks = true
  count                   = var.auto_subnets ? 1 : 0
}

// these are used for short lived clusters where we only make
// 1 subnet otherwise we use up our quota for subnetworks
resource "google_compute_network" "bacalhau_network_manual" {
  name                    = "bacalhau-network-manual-${terraform.workspace}"
  auto_create_subnetworks = false
  count                   = var.auto_subnets ? 0 : 1
}

resource "google_compute_subnetwork" "bacalhau_subnetwork_manual" {
  name          = "bacalhau-subnetwork-manual-${terraform.workspace}"
  ip_cidr_range = "192.168.0.0/16"
  region        = var.region
  network       = google_compute_network.bacalhau_network_manual[0].id
  count         = var.auto_subnets ? 0 : 1
}

# Add firewall rule for Ops Agent
resource "google_compute_firewall" "ops_agent_firewall" {
  name    = "ops-agent-firewall-${terraform.workspace}"
  network = var.auto_subnets ? google_compute_network.bacalhau_network[0].name : google_compute_network.bacalhau_network_manual[0].name

  allow {
    protocol = "tcp"
    ports = [
      "8995", // Ops Agent health check
      "8996", // Ops Agent metrics endpoint
      "20201", // OpenTelemetry collector
    ]
  }

  source_ranges = ["35.199.84.0/22"]  # GCP Health Checking Systems
  target_tags = ["ops-agent"]
}