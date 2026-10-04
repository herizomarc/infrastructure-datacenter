# opentofu/variables.tf

# 1. DÉCLARATION DYNAMIQUE DE LA CLÉ SSH SECURE
variable "ssh_public_key" {
  type        = string
  description = "Clé publique ED25519 lue dynamiquement au boot (Clé du Runner)"
}

# 2. CARTOGRAPHIE MATÉRIELLE DES NŒUDS DU CLUSTER KUBERNETES
variable "kubernetes_cluster" {
  type = map(object({
    id        = number
    role      = string
    cores     = number
    memory    = number
    disk_size = number
    ip        = string
  }))

  description = "Dimensionnement FinOps et plan d'adressage IP du cluster Kubeadm"

  default = {
    "k8s-control-plane-01" = {
      id        = 301
      role      = "control-plane"
      cores     = 2
      memory    = 4096   # 4 Go de RAM dédiés au Master Control-Plane
      disk_size = 40     # 40 Go NVMe alloués sur local-lvm
      ip        = "10.10.99.31"
    }
    "k8s-worker-01" = {
      id        = 302
      role      = "worker"
      cores     = 2
      memory    = 8192   # 8 Go de RAM dédiés au premier nœud de calcul
      disk_size = 60     # 60 Go NVMe alloués sur local-lvm
      ip        = "10.10.99.32"
    }
    "k8s-worker-02" = {
      id        = 303
      role      = "worker"
      cores     = 2
      memory    = 8192   # 8 Go de RAM dédiés au second nœud de calcul
      disk_size = 60     # 60 Go NVMe alloués sur local-lvm
      ip        = "10.10.99.33"
    }
  }
}
