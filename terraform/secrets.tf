resource "aws_secretsmanager_secret" "secrets" {
  name        = "microtodo/secrets"
  description = "Secrets and credentials for MicroTodo services"

  # This should be 6 or 7 days in a real production setup
  recovery_window_in_days = 0

  tags = {
    Name        = "microtodo-secrets"
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Store the actual secret values
resource "aws_secretsmanager_secret_version" "secrets" {
  secret_id = aws_secretsmanager_secret.secrets.id

  secret_string = jsonencode({
    postgres-username = var.postgres_username
    postgres-password = var.postgres_password
    rabbitmq-username = var.rabbitmq_username
    rabbitmq-password = var.rabbitmq_password
    jwt-access-secret = var.jwt_secret
  })
}
