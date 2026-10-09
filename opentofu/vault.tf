# opentofu/vault.tf
# Déploiement de la VM HashiCorp Vault de Production en VLAN 99

resource "proxmox_virtual_environment_file" "vault_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve1"

  source_raw {
    file_name = "vault-user-data.yaml"
    data      = <<EOF

#cloud-config
rh_subscription:
  org: "${var.rhel_org_id}"
  activation-key: "${var.rhel_activation_key}"

bootcmd:
  - localectl set-keymap fr
  - localectl set-x11-keymap fr
locale: fr_FR.UTF-8
growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false
package_update: true

# Installation des paquets requis (GPG et l'Agent Proxmox d'usine)
packages:
  - gpg
  - wget
  - curl
  - qemu-guest-agent

# SÉQUENCE AUTOMATISÉE D'INSTALLATION SÉCURE DE HASHICORP VAULT SUR RHEL 9
runcmd:
  - [ systemctl, daemon-reload ]
  - [ systemctl, enable, --now, qemu-guest-agent ]
  - [ mkdir, -p, /usr/share/keyrings ]
  - wget -O- https://hashicorp.com | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  - echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://hashicorp.com RHEL/9 main" > /etc/yum.repos.d/hashicorp.repo
  - dnf update -y
  - dnf install -y vault
  - [ mkdir, -p, /opt/vault/data ]
  - [ chown, -R, "vault:vault", /opt/vault/data ]
  - |
    cat <<EOC > /etc/vault.d/vault.hcl
    storage "file" { path = "/opt/vault/data" }
    listener "tcp" {
      address     = "0.0.0.0:8200"
      tls_disable = 1
    }
    ui = true
    EOC
  - [ systemctl, daemon-reload ]
  - [ systemctl, enable, --now, vault ]

users:
  - name: secops
    groups: wheel
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    ssh_authorized_keys:
      - "${var.ssh_public_key}" # Injection automatique de la clé du Runner
EOF
  }
}

resource "proxmox_virtual_environment_vm" "vault_server" {
  name        = "vm-vault-01"
  description = "Coffre-fort d'entreprise centralise SecOps - HashiCorp Vault Server"
  node_name   = "pve1"
  vm_id       = 401

  clone {
    vm_id = 9000 
    full  = true
  }

  scsi_hardware = "virtio-scsi-pci"
  bios          = "seabios"

  cpu {
    cores = 1
    type  = "host"
  }

  memory {
    dedicated = 1024 # 1 Go de RAM dédié pour des performances fluides de l'API Go
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20 # 20 Go d'espace NVMe alloués
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id      = "local-lvm"
    user_data_file_id = proxmox_virtual_environment_file.vault_cloud_init.id

    ip_config {
      ipv4 {
        address = "10.10.99.41/24"
        gateway = "10.10.99.1"
      }
    }

    dns {
      servers = ["10.10.99.11"]
    }
  }
}
