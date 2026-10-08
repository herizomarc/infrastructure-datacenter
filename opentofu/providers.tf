# opentofu/providers.tf

# Configuration du provider Proxmox pour OpenTofu
variable "proxmox_endpoint" {
  type        = string
  description = "URL HTTPS de l'API de Proxmox"
}

variable "proxmox_username" {
  type        = string
  description = "Identifiant du Token API Proxmox"
}

variable "proxmox_token" {
  type        = string
  description = "Valeur secrète du Token API généré sur Proxmox"
  sensitive   = true # Masque la valeur dans les fichiers de rapports logs
}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${var.proxmox_username}=${var.proxmox_token}"
  insecure  = true
}
