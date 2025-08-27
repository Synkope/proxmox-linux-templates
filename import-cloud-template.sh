#!/bin/bash
# Purpose: Download images and create Proxmox VM templates with cloud-init configuration

set -exo pipefail

#
# Configure your settings here
#
STORAGE=${STORAGE:-"local-zfs"}
CI_USER=${CI_USER:-${USER}}
SSH_KEY=${SSH_KEY:-"/home/${CI_USER}/.ssh/id_ed25519.pub"}
# Control VM deletion behavior: "skip" = skip if exists, "force" = always delete
DELETION_MODE=${DELETION_MODE:-"skip"}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c)
            if [[ -z "$2" ]]; then
                echo "Error: Missing config file parameter."
                exit 1
            elif [[ -f "$2" ]]; then
                CONFIG_FILE="$2"
                source "$CONFIG_FILE"
                shift
            else
                echo "Error: Invalid or missing config file."
                exit 1
            fi
            ;;
        --force)
            DELETION_MODE="force"
            ;;
        --skip)
            DELETION_MODE="skip"
            ;;
        *)
            echo "Usage: $0 [-c config_file] [--force|--skip]"
            echo "Config file must define the variables: OS_NAME, OS_VERSION, IMAGE_NAME, DOWNLOAD_URL, VMID, IMAGE_SIZE and CLOUD_INIT_CONFIG"
            echo "  --skip:  Skip creation if VM/template already exists (default)"
            echo "  --force: Delete existing VM/template"
            exit 1
            ;;
    esac
    shift
done

# Validate required variables from config
required_vars=("OS_NAME" "OS_VERSION" "IMAGE_NAME" "IMAGE_SIZE" "DOWNLOAD_URL" "VMID" "CLOUD_INIT_CONFIG")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var must be set in config file"
        exit 1
    fi
done

VM_NAME="${OS_NAME}-${OS_VERSION}-template"

rm -f "$IMAGE_NAME"
wget "$DOWNLOAD_URL" -O "$IMAGE_NAME"
qemu-img resize "$IMAGE_NAME" "$IMAGE_SIZE"

#
# Configure your template VM here
#
if sudo qm status $VMID &>/dev/null; then
    if [ "$DELETION_MODE" = "skip" ]; then
        echo "VM/template $VMID already exists. Skipping creation (DELETION_MODE=skip)."
        exit 0
    elif [ "$DELETION_MODE" = "force" ]; then
        sudo qm destroy $VMID --destroy-unreferenced-disks && echo "Destroyed existing VM/template: $VMID"
        if [ $? -ne 0 ]; then
            echo "Failed to destroy existing VM/template: $VMID. Do you have linked clones tied to the template disk?"
            exit 1
        fi
    else
        echo "Invalid DELETION_MODE: $DELETION_MODE. Use 'force' or 'skip'."
        exit 1
    fi
fi

sudo qm create $VMID --name "$VM_NAME" \
    --ostype l26 \
    --memory 8192 --balloon 1024 \
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

# Apply cloud-init configuration
echo "$CLOUD_INIT_CONFIG" | sudo tee /var/lib/vz/snippets/${VMID}.yaml

# Create the VM
sudo qm set $VMID --cicustom "vendor=local:snippets/${VMID}.yaml"
sudo qm set $VMID --tags ${VM_NAME},${OS_NAME}-${OS_VERSION},cloudinit
sudo qm set $VMID --ciuser ${CI_USER}
sudo qm set $VMID --sshkeys ${SSH_KEY}
sudo qm set $VMID --ipconfig0 ip=dhcp

# Convert the VM to a template
sudo qm template $VMID

echo "Successfully created template $VM_NAME (ID: $VMID)"
