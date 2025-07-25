resource "docker_image" "supabase-postgres" {
    name         = "supabase/postgres:15.8.1.060"
    keep_locally = true
}

resource "docker_image" "supabase-storage" {
    name         = "supabase/storage-api:latest"
    keep_locally = true
    count        = var.enable_storage ? 1 : 0
}

resource "docker_image" "supabase-studio" {
    name         = "supabase/studio:latest"
    keep_locally = true
}

resource "docker_image" "supabase-kong" {
    name         = "kong:2.1"
    keep_locally = true
}

resource "docker_image" "pg-meta" {
    name         = "supabase/postgres-meta:v0.89.3"
    keep_locally = true
}

resource "docker_image" "supabase-realtime" {
    name         = "supabase/realtime:latest"
    keep_locally = true
}

resource "docker_image" "supabase-rest" {
    name         = "postgrest/postgrest:latest"
    keep_locally = true
}

resource "docker_image" "supabase-auth" {
    name         = "supabase/gotrue:v2.174.0"
    keep_locally = true
}

# Used to generate JWT's during intial setup
resource "docker_image" "jwt-generator" {
    name         = "ghcr.io/chronsyn/docker-jwt-generator:master"
    keep_locally = true
}