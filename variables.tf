variable "create" {
  type    = bool
  default = null
}
variable "project_id" {
  type = string
}
variable "region" {
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