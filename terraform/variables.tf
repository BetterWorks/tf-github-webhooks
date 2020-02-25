variable "config_parameter_name" {
  type        = string
  description = "ssm parameter name"
}

variable "debug" {
  type        = string
  description = "node debug flag"
  default     = ""
}

variable "log_level" {
  type        = string
  description = "log verbosity"
  default     = "info"
}

variable "memory_size" {
  type        = string
  description = "lambda function memory limit"
  default     = 128
}

variable "name" {
  type        = string
  description = "stack name"
}

variable "node_env" {
  type        = string
  description = "node environment"
  default     = "production"
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}

variable "s3_bucket" {
  type        = string
  description = "name of artifact s3 bucket"
}

variable "s3_key" {
  type        = string
  description = "name of artifact s3 key"
}

variable "timeout" {
  type        = string
  description = "lambda function time limit"
  default     = 10
}

