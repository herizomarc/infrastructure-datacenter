# opentofu/main.tf
# Template 9000 + Cloud-Init Natif (Zéro SSH, Zéro Internet)

# 🏆 1. OPEN TOFU GÉNÈRE ET TÉLÉVERSE LE SNIPPET VIA L'API WEB (PORT 8006)
resource "proxmox_virtual_environment_file" "cloud_init_config" {
  for_each     = var.kubernetes_cluster
  content_type = "snippets"
  datastore_id = "local" # Utilise le stockage local que l'on vient d'activer
  node_name    = "pve1"

  source_raw {
    # Nom du fichier généré sur Proxmox
    file_name = "k8s-${each.key}-user-data.yaml"
    
    # user-data (directement embarqué dans l'IaC)
    data = <<EOF
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

# Force l'installation et le démarrage immédiat du QEMU Guest Agent
packages:
  - qemu-guest-agent
runcmd:
  - [ systemctl, daemon-reload ]
  - [ systemctl, enable, --now, qemu-guest-agent ]

users:
  - name: secops
    groups: wheel
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    ssh_authorized_keys:
      - "${var.ssh_public_key}" # Injection dynamique de la clé du Runner
EOF
  }
}

# 🚀 2. DÉPLOIEMENT DES VMS PAR CLONAGE DU TEMPLATE 9000
resource "proxmox_virtual_environment_vm" "k8s_nodes" {
  for_each    = var.kubernetes_cluster
  name        = each.key
  description = "Instance Kubernetes ${each.value.role}"
  node_name   = "pve1"
  vm_id       = each.value.id

  clone {
    vm_id = 9000 
    full  = true 
  }

  scsi_hardware = "virtio-scsi-pci"
  bios          = "seabios"

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory { dedicated = each.value.memory }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  # Activation de l'agent avec l'attente IP active (l'agent va remonter proprement en local)
  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Association du fichier Cloud-Init à la VM via l'API Proxmox
  initialization {
    datastore_id = "local-lvm"
    
    # OpenTofu lie physiquement le snippet généré au lecteur virtuel de la VM
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_config[each.key].id

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.10.99.1"
      }
    }

    dns { servers = ["10.10.99.11"] }
  }
}
