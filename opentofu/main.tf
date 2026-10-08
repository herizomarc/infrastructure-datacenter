# opentofu/main.tf

# LE CONTENU DU DICTIONNAIRE EST FOURNI PAR VOTRE VARIABLES.TF (CONSERVÉ À L'IDENTIQUE)

# DEPLOYEMENT EN BOUCLE DES 3 VMS À PARTIR DU QCOW2 VIA AMORCE CLOUDFLARE R2
resource "proxmox_virtual_environment_vm" "k8s_nodes" {
  for_each    = var.kubernetes_cluster
  name        = each.key
  description = "Instance Kubernetes ${each.value.role} - Cloud-Init via Cloudflare R2"
  node_name   = "pve1"
  vm_id       = each.value.id

  # Caractéristiques matérielles standardisées d'entreprise
  scsi_hardware = "virtio-scsi-pci"
  bios          = "seabios"

  cpu {
    cores = each.value.cores
    type  = "host" # Transmission directe des instructions physiques de l'ASUS SAGE
  }

  memory {
    dedicated = each.value.memory
  }

  # Liaison directe avec l'image usine QCOW2 stockée sur l'hyperviseur
  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/rhel-9.8-x86_64-kvm.qcow2" # Chemin local /var/lib/vz/template/iso/
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  agent {
    enabled = true # QEMU Guest Agent indispensable pour la remontée d'IPs dans GitLab
  }

  # Architecture réseau raccordée au pont d'administration (VLAN 99)
  network_device {
    bridge = "vmbr0"
    model  = "virtio" # Driver paravirtualisé pour maximiser les performances réseaux
  }

  # 🏆 STANDARD SECOPS : Injection de la source de métadonnées NoCloud dans le numéro de série SMBIOS.
  # Au premier démarrage, le service Cloud-Init natif de RHEL 9.8 va lire le numéro de série de sa 
  # propre carte mère et émettre une requête HTTPS vers Cloudflare R2 pour s'auto-configurer.
  smbios {
    serial = "ds=nocloud-net;s=https://herizor.cloud"
  }

  # Déclaration réseau statique transmise à l'API Proxmox
  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.10.99.1" # Passerelle de votre MikroTik
      }
    }

    dns {
      servers = ["10.10.99.11"] # Résolution interne confiée à votre AdGuard Home
    }
  }
}
