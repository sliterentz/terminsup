resource "time_sleep" "sleep_wait" {
    depends_on = [kubernetes_stateful_set.supabase-postgres]
    
    create_duration = "20s"
}

resource "null_resource" "wait_for_supabase_postgres" {
    provisioner "local-exec" {
        command = <<-EOT
            while ! docker exec ${var.postgres_host} pg_isready -U ${var.postgres_user} -d ${var.POSTGRES_DB}; do
                echo "Menunggu PostgreSQL siap..."
                sleep 5
            done
        EOT
    }
    depends_on = [
        kubernetes_stateful_set.supabase-postgres,
        time_sleep.sleep_wait
    ]
}

resource "null_resource" "db_setup_00" {
    provisioner "local-exec" {
        command = "docker exec -e PGPASSWORD=${random_password.postgres_password.result} -i ${var.postgres_host} psql -h ${var.postgres_host} -p ${var.POSTGRES_PORT} -U ${var.postgres_user} -d ${var.POSTGRES_DB} -f \"/home/init/00-initial-schema.sql\""
    }
    depends_on = [
        kubernetes_stateful_set.supabase-postgres,
        null_resource.wait_for_supabase_postgres,
        time_sleep.sleep_wait
    ]
}

resource "null_resource" "db_setup_01" {
    provisioner "local-exec" {
        command = "docker exec -e PGPASSWORD=${random_password.postgres_password.result} -i ${var.postgres_host} psql -h ${var.postgres_host} -p ${var.POSTGRES_PORT} -U ${var.postgres_user} -d ${var.POSTGRES_DB} -f \"/home/init/01-auth-schema.sql\""
    }
    depends_on = [
        kubernetes_stateful_set.supabase-postgres,
        null_resource.db_setup_00,
        time_sleep.sleep_wait
    ]
}

resource "null_resource" "db_setup_02" {
    provisioner "local-exec" {
        command = "docker exec -e PGPASSWORD=${random_password.postgres_password.result} -i ${var.postgres_host} psql -h ${var.postgres_host} -p ${var.POSTGRES_PORT} -U ${var.postgres_user} -d ${var.POSTGRES_DB} -f \"/home/init/02-storage-schema.sql\""
        }
        depends_on = [
            kubernetes_stateful_set.supabase-postgres,
            null_resource.db_setup_01,
            time_sleep.sleep_wait
        ]
}

resource "null_resource" "db_setup_03" {
    provisioner "local-exec" {
        command = "docker exec -e PGPASSWORD=${random_password.postgres_password.result} -i ${var.postgres_host} psql -h ${var.postgres_host} -p ${var.POSTGRES_PORT} -U ${var.postgres_user} -d ${var.POSTGRES_DB} -f \"/home/init/03-post-setup.sql\""
    }
    depends_on = [
        kubernetes_stateful_set.supabase-postgres,
        null_resource.db_setup_02,
        time_sleep.sleep_wait
    ]
}