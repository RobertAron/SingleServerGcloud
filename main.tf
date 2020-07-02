resource "google_compute_instance" "server_instance" {
  name     = "${var.name}-compute-instance"
  provider = google-beta
  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable-72-11316-171-0"
    }
  }
  machine_type = var.machine_type
  zone         = "us-central1-a"

  network_interface {
    network = "default"

  }
  metadata = {
    gce-container-declaration = "spec:\n  containers:\n    - image: '${var.image}'\n      stdin: false\n      tty: false\n  restartPolicy: Always\n"
    google-logging-enabled    = "true"
  }
#   tags = ["http-server", "https-server"]
  labels = {
    "container-vm" : "cos-stable-63-10032-88-0"
  }
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
}

# Probably remove this

resource "google_compute_firewall" "default" {
  provider = google-beta
  name     = "allow-web-traffic"
  network  = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_instance_group" "instance_group" {
  provider  = google-beta
  name      = "${var.name}-instance-group"
  instances = [google_compute_instance.server_instance.self_link]

  lifecycle {
    create_before_destroy = true
  }

  named_port {
    name = "http"
    port = var.port
  }
}

resource "google_compute_http_health_check" "default" {
  provider           = google-beta
  name               = "${var.name}-http-health-check"
  request_path       = "/"
  check_interval_sec = 30
  timeout_sec        = 30
}

resource "google_compute_backend_service" "default" {
  provider    = google-beta
  name        = "${var.name}-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 86400 # let people stay connected for 5 hours
  backend {
    group = google_compute_instance_group.instance_group.self_link
  }

  health_checks = [google_compute_http_health_check.default.self_link]
}

// This is the actual load balancer
resource "google_compute_url_map" "default" {
  name            = "${var.name}-url-map"
  provider        = google-beta
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_global_address" "default" {
  name         = "${var.name}-global-address"
  provider     = google-beta
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

####################################################
#################################################### 
# HTTPS
####################################################
####################################################
resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta
  name     = "${var.name}-cert"
  managed {
    domains = [var.domain]
  }
}

resource "google_compute_target_https_proxy" "target_https" {
  provider         = google-beta
  name             = "${var.name}-https-target-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}


// Frontend config
resource "google_compute_global_forwarding_rule" "forward_rule_https" {
  provider   = google-beta
  name       = "${var.name}-forward-https-rule"
  target     = google_compute_target_https_proxy.target_https.self_link // connection to the connection to the load balancer
  ip_address = google_compute_global_address.default.address            // input ip adress
  port_range = "443"
}

####################################################
#################################################### 
# HTTP
####################################################
####################################################

resource "google_compute_target_http_proxy" "target_http" {
  provider = google-beta
  name     = "${var.name}-https-target-proxy"
  url_map  = google_compute_url_map.default.id
}


// Frontend config
resource "google_compute_global_forwarding_rule" "forward_rule_http" {
  provider   = google-beta
  name       = "${var.name}-forward-http-rule"
  target     = google_compute_target_http_proxy.target_http.self_link // connection to the connection to the load balancer
  ip_address = google_compute_global_address.default.address          // input ip adress
  port_range = "80"
}
