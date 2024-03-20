variable "create" {
  type    = bool
  default = null
}
variable "project_id" {
  description = "GCP Project ID to create resources in"
  type        = string
}
variable "region" {
  description = "GCP region name for the IP address and forwarding rule"
  type        = string
  default     = null
}
variable "name_prefix" {
  type    = string
  default = null
}
variable "name" {
  type    = string
  default = null
}
variable "description" {
  type    = string
  default = null
}
variable "global" {
  type    = bool
  default = null
}
variable "regional" {
  type    = bool
  default = null
}
variable "protocol" {
  type    = string
  default = null
}
variable "host" {
  type    = string
  default = null
}
variable "port" {
  type    = number
  default = null
}
variable "ports" {
  type    = list(number)
  default = null
}
variable "request_path" {
  type    = string
  default = null
}
variable "proxy_header" {
  type    = string
  default = null
}
variable "response" {
  type    = string
  default = null
}
variable "legacy" {
  type    = bool
  default = null
}
variable "logging" {
  type    = bool
  default = null
}
variable "interval" {
  type    = number
  default = null
}
variable "timeout" {
  type    = number
  default = null
}
variable "healthy_threshold" {
  type    = number
  default = null
}
variable "unhealthy_threshold" {
  type    = number
  default = null
}