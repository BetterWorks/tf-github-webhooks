variable "name" {
  type        = "string"
  description = "stack name"
}

variable "region" {
  type        = "string"
  description = "AWS region"
  default     = "us-west-2"
}
