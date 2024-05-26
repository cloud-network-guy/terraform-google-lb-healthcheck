
# If no name provided, generate a random one
resource "random_string" "name" {
  count   = var.name == null ? 1 : 0
  length  = 8
  lower   = true
  upper   = false
  special = false
  numeric = false
}

locals {
  create           = coalesce(var.create, true)
  project_id       = lower(trimspace(var.project_id))
  name             = var.name != null ? lower(trimspace(var.name)) : one(random_string.name).result
  description      = trimspace(coalesce(var.description, "Managed by Terraform"))
  region           = local.is_regional ? var.region : "global"
  protocol         = upper(coalesce(var.protocol, var.request_path != null || var.response != null ? "http" : "tcp"))
  is_regional      = var.region != null && var.region != "global" ? true : false
  is_global        = !local.is_regional
  is_legacy        = coalesce(var.legacy, false)
  is_tcp           = local.protocol == "TCP" ? true : false
  is_http          = local.protocol == "HTTP" ? true : false
  is_https         = local.protocol == "HTTPS" ? true : false
  is_http_or_https = local.is_http || local.is_https ? true : false
  is_ssl           = local.protocol == "SSL" ? true : false
  healthchecks = local.create ? [
    {
      project_id          = local.project_id
      region              = local.region
      name                = local.name
      description         = local.description
      protocol            = local.protocol
      request_path        = local.is_http || local.is_https ? coalesce(var.request_path, "/") : null
      response            = local.is_http || local.is_https ? var.response : null
      port                = coalesce(var.port, 80)
      host                = local.is_http_or_https && var.host != null ? trimspace(var.host) : null
      proxy_header        = coalesce(var.proxy_header, "NONE")
      logging             = coalesce(var.logging, false)
      healthy_threshold   = coalesce(var.healthy_threshold, 2)
      unhealthy_threshold = coalesce(var.unhealthy_threshold, 2)
      check_interval_sec  = coalesce(var.interval, 10)
      timeout_sec         = coalesce(var.timeout, 5)
      index_key           = "${local.project_id}/${(local.is_regional ? "${local.region}/" : "")}${local.name}"
    }
  ] : []
}

resource "null_resource" "healthchecks" {
  for_each = { for i, v in local.healthchecks : v.index_key => true }
}

# Regional Health Checks
resource "google_compute_region_health_check" "default" {
  for_each    = { for i, v in local.healthchecks : v.index_key => v if local.is_regional && !local.is_legacy }
  project     = each.value.project_id
  name        = each.value.name
  description = each.value.description
  region      = each.value.region
  dynamic "tcp_health_check" {
    for_each = local.is_tcp ? [true] : []
    content {
      port         = each.value.port
      proxy_header = each.value.proxy_header
    }
  }
  dynamic "http_health_check" {
    for_each = local.is_http ? [true] : []
    content {
      port         = each.value.port
      host         = each.value.host
      request_path = each.value.request_path
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  dynamic "https_health_check" {
    for_each = local.is_https ? [true] : []
    content {
      port         = each.value.port
      host         = each.value.host
      request_path = each.value.request_path
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  dynamic "ssl_health_check" {
    for_each = local.is_ssl ? [true] : []
    content {
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  check_interval_sec  = each.value.check_interval_sec
  timeout_sec         = each.value.timeout_sec
  healthy_threshold   = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold
  log_config {
    enable = each.value.logging
  }
  depends_on = [null_resource.healthchecks]
}

# Global Health Checks
resource "google_compute_health_check" "default" {
  for_each    = { for i, v in local.healthchecks : v.index_key => v if !local.is_regional && !local.is_legacy }
  project     = each.value.project_id
  name        = each.value.name
  description = each.value.description
  dynamic "tcp_health_check" {
    for_each = local.is_tcp ? [true] : []
    content {
      port         = each.value.port
      proxy_header = each.value.proxy_header
    }
  }
  dynamic "http_health_check" {
    for_each = local.is_http ? [true] : []
    content {
      port         = each.value.port
      host         = each.value.host
      request_path = each.value.request_path
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  dynamic "https_health_check" {
    for_each = local.is_https ? [true] : []
    content {
      port         = each.value.port
      host         = each.value.host
      request_path = each.value.request_path
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  dynamic "ssl_health_check" {
    for_each = local.is_ssl ? [true] : []
    content {
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  check_interval_sec  = each.value.check_interval_sec
  timeout_sec         = each.value.timeout_sec
  healthy_threshold   = each.value.healthy_threshold
  unhealthy_threshold = each.value.unhealthy_threshold
  log_config {
    enable = each.value.logging
  }
  depends_on = [null_resource.healthchecks]
}


# Legacy HTTP Health Check
resource "google_compute_http_health_check" "default" {
  for_each           = { for i, v in local.healthchecks : v.index_key => v if local.is_legacy && local.is_http }
  project            = each.value.project_id
  name               = each.value.name
  description        = each.value.description
  port               = each.value.port
  check_interval_sec = each.value.check_interval_sec
  timeout_sec        = each.value.timeout_sec
}

# Legacy HTTPS Health Check
resource "google_compute_https_health_check" "default" {
  for_each           = { for i, v in local.healthchecks : v.index_key => v if local.is_legacy && local.is_https }
  project            = each.value.project_id
  name               = each.value.name
  description        = each.value.description
  port               = each.value.port
  check_interval_sec = each.value.check_interval_sec
  timeout_sec        = each.value.timeout_sec
}
