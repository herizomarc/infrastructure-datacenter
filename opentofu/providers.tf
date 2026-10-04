# opentofu/providers.tf

# 1. DÉCLARATION DES ACCÈS API SÉCURISÉS (INJECTÉS VIA L'ENVIRONNEMENT)
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
  sensitive   = true # Masque la valeur dans les logs d'exécution de la console
}

# 2. CONFIGURATION DES VERSIONS DE L'USINE LOGICIELLE
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60.0" # Version d'entreprise moderne du provider
    }
  }
}

# 3. INITIALISATION DU PROVIDER PROXMOX SANS SECRETS EN CLAIR
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${var.proxmox_username}=${var.proxmox_token}"
  insecure  = true # Requis car l'hyperviseur utilise un certificat auto-signé

  ssh {
    agent = true # S'appuie sur le service ssh-agent pour la sécurité des clés
  }
}
