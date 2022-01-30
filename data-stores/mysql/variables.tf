variable "db_identifier_prefix" {
  description = "DB instance identifier prefix"
  type  = string
}

variable "db_name" {
  description = "DB name"
  type = string
}

variable "db_username" {
  description = "DB username"
  type = string
}

variable "db_password" {
  description = "DB password"
  type = string
}

variable "db_remote_state_bucket" {
  description = "Remote state S3 bucket"
  type = string
}

variable "db_remote_state_key" {
  description = "Path for remote state"
  type = string
}

