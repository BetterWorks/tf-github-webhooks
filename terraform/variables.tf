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
  default     = "us-east-1"
}

variable "timeout" {
  type        = string
  description = "lambda function time limit"
  default     = 10
}

variable "aws_assume_role_arn" {}

variable "namespace" {
  type        = string
  description = "Namespace (e.g. `cp` or `cloudposse`)"
}

variable "stage" {
  type        = string
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
}