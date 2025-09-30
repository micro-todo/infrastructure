variable "aws_account_id" {
  type        = string
  description = "The AWS account ID to grant Kubernetes admin access"
}

variable "postgres_username" {
  description = "PostgreSQL username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "rabbitmq_username" {
  description = "RabbitMQ username"
  type        = string
  default     = "rabbit"
  sensitive   = true
}

variable "rabbitmq_password" {
  description = "RabbitMQ password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret"
  type        = string
  sensitive   = true
}
