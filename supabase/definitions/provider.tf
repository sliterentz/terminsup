terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.16.0"
    }
  }
}

# DO NOT MODIFY ANYTHING ABOVE THIS LINE

resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "random_password" "watchtower_http_api_token" {
  length  = 128
  special = false
}

resource "random_password" "postgres_password" {
  length  = 96
  special = false
}

resource "kubernetes_namespace" "supabase" {
  metadata {
    name = "supabase-playground"
  }
}

resource "kubernetes_secret" "supabase_secrets" {
  metadata {
    name      = "supabase-secrets"
    namespace = "supabase-playground"
  }

  data = {
    jwt_secret       = random_password.jwt_secret.result
    postgres_password = random_password.postgres_password.result
    watchtower_http_api_token = random_password.watchtower_http_api_token.result
  }

  type = "Opaque"
}