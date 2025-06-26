# Variables for the Terraform configuration

variable "kube_config_path" {
  description = "Path to the kubeconfig file"
  type        = string
}

variable "server_ips" {
  description = "List of server IPs for K3S cluster"
  type        = list(string)
}

variable "minikube_default_namespace" {
  description = "Name of the K3S default namespace"
  type        = string
}

variable "ssh_username" {
  description = "SSH username for server access"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
}

variable "postgres_username" {
  description = "PostgreSQL username"
  type        = string
  sensitive   = true
}

variable "postgres_root_password" {
  description = "PostgreSQL root password"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "mariadb_database" {
  description = "Mariadb database name"
  type        = string
}

variable "mariadb_username" {
  description = "Mariadb username"
  type        = string
  sensitive   = true
}

variable "mariadb_root_password" {
  description = "Mariadb root password"
  type        = string
  sensitive   = true
}

variable "mariadb_password" {
  description = "Mariadb password"
  type        = string
  sensitive   = true
}

variable "mongo_username" {
  description = "MongoDB Admin username"
  type        = string
  sensitive   = true
}

variable "mongo_password" {
  description = "MongoDB root password"
  type        = string
  sensitive   = true
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment (dev or prod)"
  type        = string
  default     = "prod"
}

# Supabase Config
variable "jwt_expiry" {
  type    = number
  default = 3600
}

# API Config
variable "additional_redirect_urls" {
  description = "CHANGE THIS BEFORE DEPLOYING - Comma separated list of additional redirect urls. Valid examples: https://example.com/reset-password,https://example.com/magiclink-login,https://example.com/signup-complete,myapp://some/deep/link"
  type        = string
  default     = ""
}

variable "site_url" {
  description = "CHANGE THIS BEFORE DEPLOYING - The base domain for your site without subdomains OR protocols (e.g. example.com is correct, sub.example.com is incorrect, https://example.com is incorrect)"
  type        = string
  default     = "example.com"
  }

variable "api_external_url" {
  description = "CHANGE THIS BEFORE DEPLOYING - What is the URL that your supabase instance is accessible at? For example, where can we access https://api.example.com/rest/v1, https://api.example.com/auth/v1, etc.?"
  type        = string
  default     = "https://api.example.com"
}

# Email config
variable "smtp_admin_email" {
  description = "CHANGE THIS BEFORE DEPLOYING"
  type        = string
  default     = "admin@example.com"
}

variable "smtp_host" {
  description = "CHANGE THIS BEFORE DEPLOYING"
  type        = string
  default     = "smtp.example.com"
}

variable "smtp_port" {
  description = "CHANGE THIS BEFORE DEPLOYING"
  type        = number
  default     = 2500
}

variable "smtp_user" {
  description = "CHANGE THIS BEFORE DEPLOYING"
  type        = string
  default     = "fake_mail_user"
}

variable "smtp_password" {
  description = "CHANGE THIS BEFORE DEPLOYING"
  type        = string
  default     = "fake_mail_pass"
}

variable "smtp_sender_name" {
  description = "CHANGE THIS BEFORE DEPLOYING"
  type        = string
  default     = "fake_sender"
}

# Postgres connection config
variable "postgres_host" {
  type    = string
  default = "db"
}

variable "postgres_port" {
  type    = number
  default = 5432
}

variable "postgres_user" {
  type      = string
  default   = "postgres"
  sensitive = true
}

variable "postgres_db" {
  type    = string
  default = "postgres"
}

# Meta config
variable "meta_url" {
  description = "Combines with META_HTTP_PORT to form the Meta URL"
  type        = string
  default     = "meta"
}

variable "meta_port" {
  type    = number
  default = 8080
}

variable "supa_studio_port" {
  type    = number
  default = 3000
}

variable "supa_enable_storage" {
  description = "Set this to false if you don't want the Supabase storage container to be created"
  type        = bool
  default     = true
}

variable "disable_signup" {
  type    = bool
  default = false
}

variable "enable_email_signup" {
  type    = bool
  default = true
}

variable "enable_email_autoconfirm" {
  type    = bool
  default = true
}

variable "enable_phone_signup" {
  type    = bool
  default = false
}

variable "enable_phone_autoconfirm" {
  type    = bool
  default = false
}

variable "email_invite_template_url" {
  description = "A URL which points towards a HTML template for inviting users"
  type        = string
  default     = ""
}

variable "email_confirmation_template_url" {
  description = "A URL which points towards a HTML template to allow users to confirm their account"
  type        = string
  default     = ""
}

variable "email_recovery_template_url" {
  description = "A URL which points towards a HTML template to allow users to recover their account"
  type        = string
  default     = ""
}

variable "email_magiclink_template_url" {
  description = "A URL which points towards a HTML template which allows users to login with a magic link"
  type        = string
  default     = ""
}

variable "ghcr_io_token" {
  description = "If you're pulling images from Github Container Registry, set your token here (https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry)"
  type        = string
  default     = ""
  sensitive   = true
}