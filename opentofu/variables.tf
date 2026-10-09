# opentofu/variables.tf

#DÉCLARATION SÉCURISÉE DE LA CLÉ SSH (INJECTÉE DE MANIÈRE DYNAMIQUE PAR GITLAB)
variable "ssh_public_key" {
  type        = string
  description = "Clé publique ED25519 d'entreprise lue à la volée depuis le coffre-fort de GitLab"
  # 🛡️ Pas de paramètre 'default' ici : garantit le masquage et l'anonymat complet sur GitHub.
}

#CARTOGRAPHIE MATÉRIELLE ET ADRESSAGE IP DES NŒUDS DU CLUSTER KUBERNETES
variable "kubernetes_cluster" {
  type = map(object({
    id        = number
    role      = string
    cores     = number
    memory    = number
    disk_size = number
    ip        = string
  }))

  description = "Plan de dimensionnement FinOps et plan d'adressage IP du cluster Kubeadm"

  default = {
    "k8s-control-plane-01" = {
      id        = 301
      role      = "control-plane"
      cores     = 2
      memory    = 4096   # 4 Go de RAM dédiés au nœud Master Control-Plane
      disk_size = 40     # 40 Go alloués sur local-lvm
      ip        = "10.10.99.31"
    }
    "k8s-worker-01" = {
      id        = 302
      role      = "worker"
      cores     = 2
      memory    = 8192   # 8 Go de RAM pour le premier nœud de calcul
      disk_size = 60     # 60 Go alloués sur local-lvm
      ip        = "10.10.99.32"
    }
    "k8s-worker-02" = {
      id        = 303
      role      = "worker"
      cores     = 2
      memory    = 8192   # 8 Go de RAM pour le second nœud de calcul
      disk_size = 60     # 60 Go alloués sur local-lvm
      ip        = "10.10.99.33"
    }
  }
}

# DÉCLARATION SÉCURISÉE DES IDENTIFIANTS RED HAT (INJECTÉS DE MANIÈRE MASQUÉE PAR GITLAB)
variable "rhel_org_id" {
  type        = string
  description = "ID d'organisation Red Hat injecté par GitLab"
}

variable "rhel_activation_key" {
  type        = string
  description = "Clé d'activation Red Hat injectée de manière masquée par GitLab"
  sensitive   = true # Masque la valeur dans les logs d'exécution OpenTofu
}

