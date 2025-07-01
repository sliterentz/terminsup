data "kubernetes_namespace" "supabase_playground" {
  metadata {
    name = "supabase-playground"
  }
}

module "generate_jwt_anon_key" {
  source  = "github.com/matti/terraform-shell-resource"
  command = "docker run --rm ghcr.io/chronsyn/docker-jwt-generator:master -e --role=\"anon\" --secret=\"'${random_password.jwt_secret.result}'\" --issuer=\"supabase\""
}

module "generate_jwt_service_role_key" {
  source  = "github.com/matti/terraform-shell-resource"
  command = "docker run --rm ghcr.io/chronsyn/docker-jwt-generator:master -e --role=\"service_role\" --secret=\"'${random_password.jwt_secret.result}'\" --issuer=\"supabase\""
}

resource "kubernetes_config_map" "postgres-config" {
  metadata {
    name      = "postgres-config"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
  }

  data = {
    "postgresql.conf" = file("${path.module}/volumes/db/config/postgresql.conf")
  }
}

resource "kubernetes_config_map" "postgres-init-scripts" {
  metadata {
    name      = "postgres-init-scripts"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
  }

  data = {
    "00-initial-schema.sql" = file("${path.module}/volumes/db/init/sql/00-initial-schema.sql")
    "01-auth-schema.sql"    = file("${path.module}/volumes/db/init/sql/01-auth-schema.sql")
    "02-storage-schema.sql" = file("${path.module}/volumes/db/init/sql/02-storage-schema.sql")
    "03-post-setup.sql"     = file("${path.module}/volumes/db/init/sql/03-post-setup.sql")
  }
}

resource "kubernetes_stateful_set" "supabase-postgres" {
    metadata {
        name = var.postgres_host
        namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
        labels = {
            app = "supabase-postgres"
        }
    }

    lifecycle {
      ignore_changes = [metadata[0].namespace]
    }
    
    timeouts {
      create = "2m"
      update = "2m"
      delete = "2m"
    }

    spec {
    service_name = "postgres"
    replicas     = 1

    selector {
      match_labels = {
        app = "supabase-postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "supabase-postgres"
        }
      }

      spec {
        init_container {
          name  = "postgres-init"
          image = "busybox:1.35"
          
          command = [
            "sh", "-c", 
            "mkdir -p /var/lib/postgresql/data/pgdata && chown -R 999:999 /var/lib/postgresql/data && chmod -R 700 /var/lib/postgresql/data"
          ]
          
          security_context {
            run_as_user = 0
          }
          
          volume_mount {
            name       = "pgdata"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "pgdata"
          }
        }

        init_container {
          name  = "postgres-config-copy"
          image = "busybox:1.35"
          
          command = [
            "sh", "-c", 
            "mkdir -p /var/lib/postgresql/data/pgdata && cp /etc/postgresql/postgresql.conf /var/lib/postgresql/data/postgresql.auto.conf && chown -R 999:999 /var/lib/postgresql/data"
          ]
          
          security_context {
            run_as_user = 0
          }
          
          volume_mount {
            name       = "pgdata"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "pgdata"
          }
          
          volume_mount {
            name       = "pg-config"
            mount_path = "/etc/postgresql"
          }
        }

        container {
          name  = "postgres"
          image = docker_image.supabase-postgres.name

          env {
            name  = "POSTGRES_PASSWORD"
            value = random_password.postgres_password.result
          }
          env {
            name  = "POSTGRES_DB"
            value = var.postgres_db
          }
          env {
            name  = "POSTGRES_USER"
            value = var.postgres_user
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          # env {
          #   name  = "POSTGRES_HOST_AUTH_METHOD"
          #   value = "trust"
          # }

          env {
            name  = "POSTGRES_INITDB_ARGS"
            value = "--auth-host=trust --auth-local=trust"
          }
          
          security_context {
            run_as_user  = 999
            run_as_group = 999
          }

          volume_mount {
            name       = "pgdata"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "pgdata"
          }

          volume_mount {
            name       = "pg-logs"
            mount_path = "/var/log/postgresql"
          }

          volume_mount {
            name       = "pg-init"
            mount_path = "/docker-entrypoint-initdb.d"
            read_only = true
          }

          volume_mount {
            name       = "pg-init-home"
            mount_path = "/home/init"
            read_only = true
          }

          volume_mount {
            name       = "pg-config"
            mount_path = "/etc/postgresql"
          }

          port {
            container_port = var.postgres_port
          }

          # command = [
          #   "docker-entrypoint.sh", "postgres"
          # ]

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db]
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
          
          readiness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db]
            }
            initial_delay_seconds = 30
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        volume {
          name = "pg-logs"
          empty_dir {
            size_limit = "1Gi"
          }
        }
        volume {
          name = "pg-config"
          config_map {
            name = "postgres-config"  
          }
        }
        volume {
          name = "pg-init"
          config_map {
            name = "postgres-init-scripts"  
          }
        }
        volume {
          name = "pg-init-home"
          config_map {
            name = "postgres-init-scripts"  
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "pgdata"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }

    update_strategy {
      type = "RollingUpdate"
    }
    }
}

resource "kubernetes_stateful_set" "supabase-studio" {
  metadata {
    name = "supabase-studio"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
    labels = {
      app = "supabase-studio"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].namespace]
  }

  spec {
    service_name = "studio"
    replicas     = 1

    selector {
      match_labels = {
        app = "supabase-studio"
      }
    }

    template {
      metadata {
        labels = {
          app = "supabase-studio"
        }
      }

      spec {
        container {
          name  = "studio"
          image = docker_image.supabase-studio.name

          port {
            container_port = 3000
          }

          env {
            name  = "SUPABASE_URL"
            value = "http://kong:8000"
          }

          env {
            name  = "STUDIO_PG_META_URL"
            value = "http://${var.meta_url}:${var.meta_port}"
          }
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_stateful_set.supabase-postgres
  ]
}

resource "kubernetes_config_map" "kong_config" {
  metadata {
    name      = "kong-config"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
  }

  data = {
    "kong.yml" = <<-EOT
      _format_version: "2.1"
      _transform: true

      services:
        - name: auth-v1-open
          url: http://auth:9999/verify
          routes:
            - name: auth-v1-open
              strip_path: true
              paths:
                - /auth/v1/
        - name: auth-v1
          url: http://auth:9999
          routes:
            - name: auth-v1-all
              strip_path: true
              paths:
                - /auth/v1/
        - name: rest-v1
          url: http://rest:3000
          routes:
            - name: rest-v1-all
              strip_path: true
              paths:
                - /rest/v1/
        - name: realtime-v1
          url: http://realtime:4000/socket
          routes:
            - name: realtime-v1-all
              strip_path: true
              paths:
                - /realtime/v1/
        - name: storage-v1
          url: http://storage:5000
          routes:
            - name: storage-v1-all
              strip_path: true
              paths:
                - /storage/v1/
        - name: meta
          url: http://${var.meta_url}:${var.meta_port}
          routes:
            - name: meta-all
              strip_path: true
              paths:
                - /pg/
      plugins:
        - name: cors
          config:
            origins:
            - "*"
            methods:
            - GET
            - POST
            - PUT
            - PATCH
            - DELETE
            - OPTIONS
            headers:
            - Accept
            - Accept-Version
            - Content-Length
            - Content-MD5
            - Content-Type
            - Date
            - X-Auth-Token
            - Authorization
            exposed_headers:
            - X-Auth-Token
            credentials: true
            max_age: 3600
        - name: key-auth
          config:
            key_names:
            - apikey
            - authorization
            hide_credentials: true
        - name: acl
          config:
            hide_groups_header: true
            allow:
            - anon
            - service_role
      consumers:
        - username: anon
          keyauth_credentials:
            - key: ${module.generate_jwt_anon_key.stdout}
        - username: service_role
          keyauth_credentials:
            - key: ${module.generate_jwt_service_role_key.stdout}        
    EOT
  }
}

resource "kubernetes_stateful_set" "supabase-kong" {
  metadata {
    name = "supabase-kong"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
    labels = {
      app = "supabase-kong"
    }
  }

  spec {
    service_name = "kong"
    replicas     = 1

    selector {
      match_labels = {
        app = "supabase-kong"
      }
    }

    template {
      metadata {
        labels = {
          app = "supabase-kong"
        }
      }

      spec {
        container {
          name  = "kong"
          image = docker_image.supabase-kong.name

          port {
            container_port = 8000
          }
          port {
            container_port = 8443
          }

          env {
            name  = "KONG_DATABASE"
            value = "off"
          }
          env {
            name  = "KONG_DECLARATIVE_CONFIG"
            value = "/var/lib/kong/kong.yml"
          }
          env {
            name  = "KONG_DNS_ORDER"
            value = "LAST,A,CNAME"
          }
          env {
            name  = "KONG_PLUGINS"
            value = "request-transformer,cors,key-auth,acl"
          }

          volume_mount {
            name       = "kong-config"
            mount_path = "/var/lib/kong"
          }
        }

        volume {
          name = "kong-config"
          config_map {
            name = kubernetes_config_map.kong_config.metadata[0].name
          }
        }
      }
    }

    # volume_claim_template {
    #   metadata {
    #     name = "kong-config"
    #   }
    #   spec {
    #     access_modes = ["ReadWriteOnce"]
    #     resources {
    #       requests = {
    #         storage = "1Gi"
    #       }
    #     }
    #   }
    # }
  }
}

resource "kubernetes_stateful_set" "pg-meta" {
  metadata {
    name = "pg-meta"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
    labels = {
      app = "pg-meta"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].namespace]
  }

  spec {
    service_name = "pg-meta"
    replicas     = 1

    selector {
      match_labels = {
        app = "pg-meta"
      }
    }

    template {
      metadata {
        labels = {
          app = "pg-meta"
        }
      }

      spec {
        container {
          name  = "pg-meta"
          image = docker_image.pg-meta.name

          port {
            container_port = 8080
          }

          env {
            name  = "PG_META_PORT"
            value = var.meta_port
          }
          env {
            name  = "PG_META_DB_HOST"
            value = var.postgres_host
          }
          env {
            name  = "PG_META_DB_PASSWORD"
            value = random_password.postgres_password.result
          }
        }
      }
    }
  }
}

resource "kubernetes_stateful_set" "supabase-realtime" {
  metadata {
    name = "supabase-realtime"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
    labels = {
      app = "supabase-realtime"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].namespace]
  }

  spec {
    service_name = "realtime"
    replicas     = 1

    selector {
      match_labels = {
        app = "supabase-realtime"
      }
    }

    template {
      metadata {
        labels = {
          app = "supabase-realtime"
        }
      }

      spec {
        container {
          name  = "realtime"
          image = docker_image.supabase-realtime.name

          port {
            container_port = 4000
          }

          env {
            name  = "DB_HOST"
            value = var.postgres_host
          }
          env {
            name  = "DB_PORT"
            value = var.postgres_port
          }
          env {
            name  = "DB_NAME"
            value = var.postgres_db
          }
          env {
            name  = "DB_USER"
            value = var.postgres_user
          }
          env {
            name  = "DB_PASSWORD"
            value = random_password.postgres_password.result
          }
          env {
            name  = "DB_SSL"
            value = "false"
          }
          env {
            name  = "PORT"
            value = "4000"
          }
          env {
            name  = "JWT_SECRET"
            value = random_password.jwt_secret.result
          }
          env {
            name  = "REPLICATION_MODE"
            value = "RLS"
          }
          env {
            name  = "REPLICATION_POLL_INTERVAL"
            value = "300"
          }
          env {
            name  = "SECURE_CHANNELS"
            value = "true"
          }
          env {
            name  = "SLOT_NAME"
            value = "supabase_realtime_rls"
          }
          env {
            name  = "TEMPORARY_SLOT"
            value = "true"
          }

          command = [
            "bash",
            "-c",
            "./prod/rel/realtime/bin/realtime eval Realtime.Release.migrate && ./prod/rel/realtime/bin/realtime start"
          ]
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_stateful_set.supabase-postgres
  ]
}

resource "kubernetes_stateful_set" "supabase-storage" {
  metadata {
    name = "supabase-storage"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
    labels = {
      app = "supabase-storage"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].namespace]
  }

  spec {
    service_name = "storage"
    replicas     = var.enable_storage ? 1 : 0

    selector {
      match_labels = {
        app = "supabase-storage"
      }
    }

    template {
      metadata {
        labels = {
          app = "supabase-storage"
        }
      }

      spec {
        container {
          name  = "storage"
          image = "supabase/storage-api:latest"

          port {
            container_port = 5000
          }

          env {
            name  = "ANON_KEY"
            value = module.generate_jwt_anon_key.stdout
          }
          env {
            name  = "SERVICE_KEY"
            value = module.generate_jwt_service_role_key.stdout
          }
          env {
            name  = "POSTGREST_URL"
            value = "http://rest:3000"
          }
          env {
            name  = "PGRST_JWT_SECRET"
            value = random_password.jwt_secret.result
          }
          env {
            name  = "DATABASE_URL"
            value = "postgres://${var.postgres_user}:${random_password.postgres_password.result}@${var.postgres_host}:${var.postgres_port}/postgres"
          }
          env {
            name  = "PGOPTIONS"
            value = "-c search_path=storage,public"
          }
          env {
            name  = "FILE_SIZE_LIMIT"
            value = "52428800"
          }
          env {
            name  = "STORAGE_BACKEND"
            value = "file"
          }
          env {
            name  = "FILE_STORAGE_BACKEND_PATH"
            value = "/var/lib/storage"
          }
          env {
            name  = "TENANT_ID"
            value = "stub"
          }
          env {
            name  = "REGION"
            value = "stub"
          }
          env {
            name  = "GLOBAL_S3_BUCKET"
            value = "stub"
          }

          volume_mount {
            name       = "storage-data"
            mount_path = "/var/lib/storage"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "storage-data"
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_stateful_set.supabase-postgres
  ]
}

resource "kubernetes_stateful_set" "supabase-auth" {
  metadata {
    name = "supabase-auth"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
    labels = {
      app = "supabase-auth"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].namespace]
  }

  spec {
    service_name = "auth"
    replicas     = 1

    selector {
      match_labels = {
        app = "supabase-auth"
      }
    }

    template {
      metadata {
        labels = {
          app = "supabase-auth"
        }
      }

      spec {
        container {
          name  = "auth"
          image = docker_image.supabase-auth.name

          port {
            container_port = 9999
          }

          env {
            name  = "GOTRUE_API_HOST"
            value = "0.0.0.0"
          }
          env {
            name  = "GOTRUE_API_PORT"
            value = "9999"
          }
          env {
            name  = "GOTRUE_DB_DRIVER"
            value = "postgres"
          }
          env {
            name  = "GOTRUE_DB_DATABASE_URL"
            value = "postgres://${var.postgres_user}:${random_password.postgres_password.result}@${var.postgres_host}:${var.postgres_port}/${var.postgres_db}?search_path=auth"
          }
          env {
            name  = "GOTRUE_SITE_URL"
            value = var.SITE_URL
          }
          env {
            name  = "GOTRUE_URI_ALLOW_LIST"
            value = var.ADDITIONAL_REDIRECT_URLS
          }
          env {
            name  = "GOTRUE_DISABLE_SIGNUP"
            value = var.DISABLE_SIGNUP
          }
          env {
            name  = "GOTRUE_JWT_SECRET"
            value = random_password.jwt_secret.result
          }
          env {
            name  = "GOTRUE_JWT_EXPIRY"
            value = var.jwt_expiry
          }
          env {
            name  = "GOTRUE_JWT_DEFAULT_GROUP_NAME"
            value = "authenticated"
          }
          env {
            name = "GOTRUE_EXTERNAL_EMAIL_ENABLED"
            value = var.ENABLE_EMAIL_SIGNUP
          }
          env {
            name = "GOTRUE_MAILER_AUTOCONFIRM"
            value = var.ENABLE_EMAIL_AUTOCONFIRM
          }
          env {
            name = "API_EXTERNAL_URL"
            value = var.API_EXTERNAL_URL
          }
          env {
            name = "GOTRUE_MAILER_TEMPLATES_INVITE"
            value = var.EMAIL_CONFIRMATION_TEMPLATE_URL
          }
          env {
            name = "GOTRUE_MAILER_TEMPLATES_CONFIRMATION"
            value = var.EMAIL_CONFIRMATION_TEMPLATE_URL
          }
          env {
            name = "GOTRUE_MAILER_TEMPLATES_RECOVERY"
            value = var.EMAIL_RECOVERY_TEMPLATE_URL
          }
          env {
            name = "GOTRUE_MAILER_TEMPLATES_MAGIC_LINK"
            value = var.EMAIL_MAGICLINK_TEMPLATE_URL
          }
          env {
            name = "GOTRUE_SMTP_HOST"
            value = var.SMTP_HOST
          }
          env {
            name  = "GOTRUE_SMTP_PORT"
            value = var.SMTP_PORT
          }
          env {
            name  = "GOTRUE_SMTP_USER"
            value = var.SMTP_USER
          }
          env {
            name  = "GOTRUE_SMTP_PASSWORD"
            value = var.SMTP_PASS
          }
          env {
            name  = "GOTRUE_SMTP_ADMIN_EMAIL"
            value = var.SMTP_ADMIN_EMAIL
          }
          env {
            name  = "GOTRUE_MAILER_URLPATHS_INVITE"
            value = "/auth/v1/verify"
          }
          env {
            name  = "GOTRUE_MAILER_URLPATHS_CONFIRMATION"
            value = "/auth/v1/verify"
          }
          env {
            name  = "GOTRUE_MAILER_URLPATHS_RECOVERY"
            value = "/auth/v1/verify"
          }
          env {
            name  = "GOTRUE_MAILER_URLPATHS_EMAIL_CHANGE"
            value = "/auth/v1/verify"
          }
          env {
            name  = "GOTRUE_EXTERNAL_PHONE_ENABLED"
            value = var.ENABLE_PHONE_SIGNUP
          }
          env {
            name  = "GOTRUE_SMS_AUTOCONFIRM"
            value = var.ENABLE_PHONE_AUTOCONFIRM
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_stateful_set.supabase-postgres
  ]
}

resource "kubernetes_stateful_set" "supabase-rest" {
  metadata {
    name = "supabase-rest"
    namespace = data.kubernetes_namespace.supabase_playground.metadata[0].name
    labels = {
      app = "supabase-rest"
    }
  }

  spec {
    service_name = "rest"
    replicas     = 1

    selector {
      match_labels = {
        app = "supabase-rest"
      }
    }

    template {
      metadata {
        labels = {
          app = "supabase-rest"
        }
      }

      spec {
        container {
          name  = "rest"
          image = docker_image.supabase-rest.name

          port {
            container_port = 3000
          }

          env {
            name  = "PGRST_DB_URI"
            value = "postgres://${var.postgres_user}:${random_password.postgres_password.result}@${var.postgres_host}:${var.postgres_port}/${var.postgres_db}"
          }
          env {
            name  = "PGRST_DB_SCHEMAS"
            value = "public,storage"
          }
          env {
            name  = "PGRST_DB_ANON_ROLE"
            value = "anon"
          }
          env {
            name  = "PGRST_JWT_SECRET"
            value = random_password.jwt_secret.result
          }
          env {
            name  = "PGRST_DB_USE_LEGACY_GUCS"
            value = "false"
          }

          command = ["/bin/postgrest"]

          liveness_probe {
            exec {
              command = ["pg_isready", "-U", var.postgres_user, "-d", var.postgres_db, "-h", var.postgres_host]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_stateful_set.supabase-postgres
  ]
}
