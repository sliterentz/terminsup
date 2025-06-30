variable "enable_storage" {
  description = "Enable storage for Supabase"
  type        = bool
  default     = false
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
  default = 5532
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

variable "jwt_expiry" {
  type    = number
  default = 3600
}
