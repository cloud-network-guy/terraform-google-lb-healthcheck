locals {
  create      = coalesce(var.create, true)
  project_id  = lower(trimspace(var.project_id))
  name_prefix = var.name_prefix != null ? lower(trimspace(var.name_prefix)) : null
  name        = var.name != null ? lower(trimspace(var.name)) : null
  description = coalesce(var.description, "Managed by Terraform")
  is_regional = var.region != null ? true : false
  region      = local.is_regional ? var.region : "global"
  legacy      = coalesce(var.legacy, false)
  protocol    = upper(coalesce(var.protocol, var.request_path != null || var.response != null ? "http" : "tcp"))
  _healthchecks = [
    {
      create              = local.create
      project_id          = local.project_id
      is_regional         = local.is_regional
      is_legacy           = local.legacy
      region              = local.region
      name                = local.name
      description         = local.description
      protocol            = local.protocol
      port                = coalesce(var.port, 80)
      host                = var.host != null ? trimspace(var.host) : null
      proxy_header        = coalesce(var.proxy_header, "NONE")
      logging             = coalesce(var.logging, false)
      healthy_threshold   = coalesce(var.healthy_threshold, 2)
      unhealthy_threshold = coalesce(var.unhealthy_threshold, 2)
      check_interval_sec  = coalesce(var.interval, 10)
      timeout_sec         = coalesce(var.timeout, 5)
    }
  ]
}

# If no name yet, generate a random one
resource "random_string" "names" {
  for_each = { for i, v in local._healthchecks : i => true if v.name == null }
  length   = 8
  lower    = true
  upper    = false
  special  = false
  numeric  = false
}

locals {
  __healthchecks = [for i, v in local._healthchecks :
    merge(v, {
      name         = coalesce(var.name, var.name == null ? random_string.names[i].result : "error")
      request_path = startswith(v.protocol, "HTTP") ? coalesce(var.request_path, "/") : null
      response     = startswith(v.protocol, "HTTP") ? var.response : null
      is_tcp       = v.protocol == "TCP" ? true : false
      is_http      = v.protocol == "HTTP" ? true : false
      is_https     = v.protocol == "HTTPS" ? true : false
      is_ssl       = v.protocol == "SSL" ? true : false
    })
  ] 
  healthchecks = [for i, v in local.__healthchecks :
    merge(v, {
      index_key = v.is_regional ? "${v.project_id}/${v.region}/${v.name}" : "${v.project_id}/${v.name}"
    }) if v.create == true
  ]
}

resource "null_resource" "healthchecks" {
  for_each = { for i, v in local.healthchecks : v.index_key => true }
}

# Regional Health Checks
resource "google_compute_region_health_check" "default" {
  for_each    = { for i, v in local.healthchecks : v.index_key => v if v.is_regional && !v.is_legacy }
  project     = each.value.project_id
  name        = each.value.name
  description = each.value.description
  region      = each.value.region
  dynamic "tcp_health_check" {
    for_each = each.value.is_tcp ? [true] : []
    content {
      port         = each.value.port
      proxy_header = each.value.proxy_header
    }
  }
  dynamic "http_health_check" {
    for_each = each.value.is_http ? [true] : []
    content {
      port         = each.value.port
      host         = each.value.host
      request_path = each.value.request_path
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  dynamic "https_health_check" {
    for_each = each.value.is_https ? [true] : []
    content {
      port         = each.value.port
      host         = each.value.host
      request_path = each.value.request_path
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  dynamic "ssl_health_check" {
    for_each = each.value.is_ssl ? [true] : []
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
  for_each    = { for i, v in local.healthchecks : v.index_key => v if !v.is_regional && !v.is_legacy }
  project     = each.value.project_id
  name        = each.value.name
  description = each.value.description
  dynamic "tcp_health_check" {
    for_each = each.value.is_tcp ? [true] : []
    content {
      port         = each.value.port
      proxy_header = each.value.proxy_header
    }
  }
  dynamic "http_health_check" {
    for_each = each.value.is_http ? [true] : []
    content {
      port         = each.value.port
      host         = each.value.host
      request_path = each.value.request_path
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  dynamic "https_health_check" {
    for_each = each.value.is_https ? [true] : []
    content {
      port         = each.value.port
      host         = each.value.host
      request_path = each.value.request_path
      proxy_header = each.value.proxy_header
      response     = each.value.response
    }
  }
  dynamic "ssl_health_check" {
    for_each = each.value.is_ssl ? [true] : []
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
  for_each           = { for i, v in local.healthchecks : v.index_key => v if v.is_legacy && v.is_http }
  project            = each.value.project_id
  name               = each.value.name
  description        = each.value.description
  port               = each.value.port
  check_interval_sec = each.value.check_interval_sec
  timeout_sec        = each.value.timeout_sec
}

# Legacy HTTPS Health Check
resource "google_compute_https_health_check" "default" {
  for_each           = { for i, v in local.healthchecks : v.index_key => v if v.is_legacy && v.is_https }
  project            = each.value.project_id
  name               = each.value.name
  description        = each.value.description
  port               = each.value.port
  check_interval_sec = each.value.check_interval_sec
  timeout_sec        = each.value.timeout
}
