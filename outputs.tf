output "healthchecks" {
  value = [for i, v in local.healthchecks :
    {
      name   = v.name
      region = v.region
      id = coalesce(
        v.is_regional && !v.is_legacy ? google_compute_region_health_check.default[v.index_key].id : null,
        !v.is_regional && !v.is_legacy ? google_compute_health_check.default[v.index_key].id : null,
        v.is_legacy && v.is_http ? google_compute_http_health_check.default[v.index_key].id : null,
        v.is_legacy && v.is_https ? google_compute_https_health_check.default[v.index_key].id : null,
        "unknown"
      )
      self_link = coalesce(
        v.is_regional && !v.is_legacy ? google_compute_region_health_check.default[v.index_key].self_link : null,
        !v.is_regional && !v.is_legacy ? google_compute_health_check.default[v.index_key].self_link : null,
        v.is_legacy && v.is_http ? google_compute_http_health_check.default[v.index_key].self_link : null,
        v.is_legacy && v.is_https ? google_compute_https_health_check.default[v.index_key].self_link : null,
        "unknown"
      )
    }
  ]
}
output "id" {
  value = coalesce(
    local.is_regional && !local.is_legacy ? one([google_compute_region_health_check.default[one(local.healthchecks).index_key].id]) : null,
    !local.is_regional && !local.is_legacy ? one([google_compute_health_check.default[one(local.healthchecks).index_key].id]) : null,
    local.is_legacy && local.is_http ? one([google_compute_http_health_check.default[one(local.healthchecks).index_key].id]) : null,
    local.is_legacy && local.is_https ? one([google_compute_https_health_check.default[one(local.healthchecks).index_key].id]) : null,
    "error"
  )
}
output "self_link" {
  value = coalesce(
    local.is_regional && !local.is_legacy ? one([google_compute_region_health_check.default[one(local.healthchecks).index_key].self_link]) : null,
    !local.is_regional && !local.is_legacy ? one([google_compute_health_check.default[one(local.healthchecks).index_key].self_link]) : null,
    local.is_legacy && local.is_http ? one([google_compute_http_health_check.default[one(local.healthchecks).index_key].self_link]) : null,
    local.is_legacy && local.is_https ? one([google_compute_https_health_check.default[one(local.healthchecks).index_key].self_link]) : null,
    "error"
  )
}
