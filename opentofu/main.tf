# opentofu/main.tf

# 1. GÉNÉRATION DES SNIPPETS CLOUD-INIT INDIVIDUELS (AMORCE AU PREMIER BOOT)
resource "proxmox_virtual_environment_file" "k8s_cloud_config" {
  for_each     = var.kubernetes_cluster
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve1"

  # Alignement SecOps avec la syntaxe moderne d'encapsulation de données brutes
  source_raw {
    file_name = "${each.key}-init.yaml"
    data      = <<EOF
#cloud-config
bootcmd:
  - localectl set-keymap fr
  - localectl set-x11-keymap fr
locale: fr_FR.UTF-8
growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false
package_update: true
EOF
  }
}

# 2. PROVISIONNEMENT EN BOUCLE DES 3 VMS RHEL 9.8 D'ENTREPRISE
resource "proxmox_virtual_environment_vm" "k8s_nodes" {
  for_each    = var.kubernetes_cluster
  name        = each.key
  description = "Instance Kubernetes ${each.value.role} - Deploiement immuable via OpenTofu"
  node_name   = "pve1"
  vm_id       = each.value.id

  # Drivers de stockage virtio d'entreprise pour maximiser les IOPS
  scsi_hardware = "virtio-scsi-pci"
  bios          = "seabios"

  cpu {
    cores = each.value.cores
    type  = "host" # Transmission directe des instructions physiques AES-NI / VT-x
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/rhel-9.8-x86_64-kvm.qcow2" # Votre image d'usine brute Red Hat
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  agent {
    enabled = true # Liaison avec le QEMU Guest Agent pour remonter les metriques reseau
  }

  # Architecture reseau de type VM (Underlay raccordée au pont d'administration)
  network_device {
    bridge = "vmbr0" # Liaison physique avec le VLAN 99 d'administration
    model  = "virtio" # Driver paravirtualisé standard pour la performance
  }

  initialization {
    datastore_id      = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.k8s_cloud_config[each.key].id

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.10.99.1" # Passerelle MikroTik
      }
    }

    dns {
      servers = ["10.10.99.11"] # Resolution interne confiee au DNS
    }

    user_account {
      username = "secops"
      keys     = [var.ssh_public_key] # Injection de la cle SSH lue dynamiquement
    }
  }
}
