# opentofu/main.tf
# Architecture Certifiée GitOps - Déploiement sans SSH via Clones et Cloudflare R2

resource "proxmox_virtual_environment_vm" "k8s_nodes" {
  for_each    = var.kubernetes_cluster
  name        = each.key
  description = "Instance Kubernetes ${each.value.role} - Deploiement immuable via Template 9000 et Cloudflare R2"
  node_name   = "pve1"
  vm_id       = each.value.id

  # 🏆 LE STANDARD DE PRODUCTION : CLONAGE API EN PORT 8006
  # Plus aucun flux SSH n'est requis sur l'hyperviseur physique pour manipuler le disque.
  clone {
    vm_id = 9000 # Pointage sur la Gold Image de référence RHEL 9.8 creee a la main
    full  = true # Decoupe un clone independant pour maximiser les IOPS et les performances de calcul
  }

  # Drivers de stockage et controleurs virtio d'entreprise
  scsi_hardware = "virtio-scsi-pci"
  bios          = "seabios"

  cpu {
    cores = each.value.cores
    type  = "host" # Transmission directe des instructions physiques AES-NI du processeur
  }

  memory {
    dedicated = each.value.memory
  }

  # Extension de la partition disque brute heritee du moule d'usine NVMe
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = each.value.disk_size
  }

  agent {
    enabled = true # QEMU Guest Agent indispensable pour remonter l'etat de sante dans GitLab
    wait_for_ip {
      disabled = true 
    }

  }

  # Interface reseau raccordee au pont d'administration (VLAN 99)
  network_device {
    bridge = "vmbr0"
    model  = "virtio" # Driver paravirtualise standard pour la performance reseau
  }

  # 🏆 AMORCE EDGE CLOUDFLARE R2 : Injection NoCloud-Net dans la table de la carte mere (SMBIOS)
  # Au premier démarrage, le service Cloud-Init natif de RHEL 9.8 va lire le numero de serie virtuel
  # et emettre une requete HTTPS de lecture vers Cloudflare pour s'auto-configurer (AZERTY, user_data).
  smbios {
    serial = "ds=nocloud-net;s=https://7a3b6c0841bd27ee9593b930a4be6e7a.r2.cloudflarestorage.com/infrastructure-cloudinit"
  }

  # Declaration de la couche reseau statique transmise via l'API Proxmox
  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = "10.10.99.1" # Passerelle de votre routeur MikroTik
      }
    }

    dns {
      servers = ["10.10.99.11"] # Resolution interne confiee a votre AdGuard Home
    }
  }
}
