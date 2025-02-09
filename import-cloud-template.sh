#!/bin/bash

set -exo pipefail

#
# Configure your settings here
#

STORAGE=local-zfs
CI_USER=${USER}
SSH_KEY=/home/${CI_USER}/.ssh/id_ed25519.pub

INSTALL_DOCKER=false

# Check if CONFIG_FILE is set
if [[ -z "$CONFIG_FILE" ]]; then
    echo "Usage: $0 [--install-docker] [-c config_file]"
    exit 1
fi

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --install-docker)
            INSTALL_DOCKER=true
            ;;
        -c)
            if [[ -z "$2" ]]; then
                echo "Error: Missing config file."
                exit 1
            elif [[ -f "$2" ]]; then
                CONFIG_FILE=$2
                source "$CONFIG_FILE"
                shift
            else
                echo "Error: Invalid or missing config file."
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [--install-docker] [-c config_file]"
            exit 1
            ;;
    esac
    shift
done

VM_NAME="${OS_NAME}-${OS_VERSION}-template"
if [ "$INSTALL_DOCKER" = true ]; then
    VM_NAME="${VM_NAME}-docker"
    IMAGE_NAME="${IMAGE_NAME}-docker"
    ((VMID++))
fi

rm -f $IMAGE_NAME
wget $DOWNLOAD_URL -O $IMAGE_NAME

#
# Configure your template VM here
#
qemu-img resize $IMAGE_NAME 30G
sudo qm destroy $VMID --destroy-unreferenced-disks || true
sudo qm create $VMID --name "$VM_NAME" \
    --ostype l26 \
    --memory 1024 --balloon 8192 \
    --agent 1 \
    --bios ovmf  --efidisk0 $STORAGE:0,pre-enrolled-keys=0 \
    --cpu host --cores 2  \
    --vga serial0 --serial0 socket  \
    --net0 virtio,bridge=vmbr0,mtu=1500
sudo qm importdisk $VMID $IMAGE_NAME $STORAGE
sudo qm set $VMID --scsihw virtio-scsi-pci --virtio0 $STORAGE:vm-$VMID-disk-1,discard=on
sudo qm set $VMID --boot order=virtio0
sudo qm set $VMID --scsi1 $STORAGE:cloudinit

# Create cloud-init configuration
#
# Note: Snippets need to be enabled for the data store in Proxmox
# See: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_common_storage_properties

cat << EOF | sudo tee /var/lib/vz/snippets/$VM_NAME.yaml
#cloud-config
runcmd:
    - apt-get update
    - apt-get install -y qemu-guest-agent gnupg
EOF

if [ "$INSTALL_DOCKER" = true ]; then
  cat << EOF | sudo tee -a /var/lib/vz/snippets/$VM_NAME.yaml
    - install -m 0755 -d /etc/apt/keyrings
    - curl -fsSL https://download.docker.com/linux/${OS_NAME}/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    - chmod a+r /etc/apt/keyrings/docker.gpg
    - |
      echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/${OS_NAME} \$(. /etc/os-release && echo \$VERSION_CODENAME) stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    - apt-get update
    - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
EOF
fi

cat << EOF | sudo tee -a /var/lib/vz/snippets/$VM_NAME.yaml
    - reboot
EOF

# Create the VM
sudo qm set $VMID --cicustom "vendor=local:snippets/${VM_NAME}.yaml"
sudo qm set $VMID --tags ${VM_NAME},${OS_NAME}-${OS_VERSION},cloudinit
sudo qm set $VMID --ciuser ${CI_USER}
sudo qm set $VMID --sshkeys ${SSH_KEY}
sudo qm set $VMID --ipconfig0 ip=dhcp

# Convert the VM to a template
sudo qm template $VMID
