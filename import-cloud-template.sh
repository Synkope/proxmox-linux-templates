#!/bin/bash
# Purpose: Download images and create Proxmox VM templates with cloud-init configuration

set -eo pipefail

STORAGE=${STORAGE:-"local-zfs"}
CI_USER=${CI_USER:-${USER}}
SSH_KEY=${SSH_KEY:-"/home/${CI_USER}/.ssh/id_ed25519.pub"}
DELETION_MODE=${DELETION_MODE:-"skip"}
REFRESH=${REFRESH:-"false"}

IMAGE_PREEXISTED=false
VM_CREATED=false

cleanup() {
    local exit_code=$?
    [[ $exit_code -eq 0 ]] && return
    echo "Error occurred, cleaning up..."
    if [[ "$IMAGE_PREEXISTED" == "false" ]]; then
        rm -f "$IMAGE_NAME"
    fi
    if [[ "$VM_CREATED" == "true" ]]; then
        sudo qm destroy "$VMID" --destroy-unreferenced-disks 2>/dev/null || true
    fi
}

trap cleanup EXIT

parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -c)
                if [[ -z "$2" ]]; then
                    echo "Error: Missing config file parameter."
                    exit 1
                elif [[ -f "$2" ]]; then
                    source "$2"
                    shift
                else
                    echo "Error: Invalid or missing config file."
                    exit 1
                fi
                ;;
            --force)    DELETION_MODE="force" ;;
            --skip)     DELETION_MODE="skip" ;;
            --refresh)  REFRESH="true" ;;
            *)
                echo "Usage: $0 [-c config_file] [--force|--skip] [--refresh]"
                echo "Config file must define: OS_NAME, OS_VERSION, IMAGE_NAME, DOWNLOAD_URL, VMID, IMAGE_SIZE, CLOUD_INIT_CONFIG, CHECKSUM_URL"
                echo "  --skip:    Skip creation if VM/template already exists (default)"
                echo "  --force:   Delete existing VM/template"
                echo "  --refresh: Re-download image even if cached"
                exit 1
                ;;
        esac
        shift
    done
}

validate_config() {
    local required_vars=("OS_NAME" "OS_VERSION" "IMAGE_NAME" "IMAGE_SIZE" "DOWNLOAD_URL" "VMID" "CLOUD_INIT_CONFIG" "CHECKSUM_URL")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "Error: $var must be set in config file"
            exit 1
        fi
    done
    VM_NAME="${OS_NAME}-${OS_VERSION}-template"
}

fetch_expected_hash() {
    local checksum_file
    checksum_file=$(mktemp)
    wget -q "$CHECKSUM_URL" -O "$checksum_file" || {
        echo "Error: Failed to download checksum file from $CHECKSUM_URL (HTTP error or URL not found)"
        rm -f "$checksum_file"
        exit 1
    }
    local expected
    if grep -qF "($IMAGE_NAME)" "$checksum_file"; then
        expected=$(grep -F "($IMAGE_NAME)" "$checksum_file" | awk '{print $NF}')
    else
        expected=$(grep -F "$IMAGE_NAME" "$checksum_file" | awk '{print $1}')
    fi
    rm -f "$checksum_file"
    if [[ -z "$expected" ]]; then
        echo "Error: Could not find entry for '$IMAGE_NAME' in $CHECKSUM_URL"
        exit 1
    fi
    echo "$expected"
}

compute_hash() {
    if [[ "$CHECKSUM_URL" == *SHA512* || "$CHECKSUM_URL" == *sha512* ]]; then
        sha512sum "$IMAGE_NAME" | awk '{print $1}'
    else
        sha256sum "$IMAGE_NAME" | awk '{print $1}'
    fi
}

download_image() {
    if [[ -f "$IMAGE_NAME" && "$REFRESH" != "true" ]]; then
        echo "Checking cached image: $IMAGE_NAME"
        local expected actual
        expected=$(fetch_expected_hash)
        actual=$(compute_hash)
        if [[ "$expected" == "$actual" ]]; then
            IMAGE_PREEXISTED=true
            echo "Cached image is up to date: $IMAGE_NAME"
            return
        fi
        echo "Cached image is outdated, re-downloading..."
    fi
    echo "Downloading: $DOWNLOAD_URL"
    wget "$DOWNLOAD_URL" -O "$IMAGE_NAME"
}

verify_checksum() {
    echo "Verifying checksum: $IMAGE_NAME"
    local expected actual
    expected=$(fetch_expected_hash)
    actual=$(compute_hash)
    if [[ "$expected" != "$actual" ]]; then
        echo "Error: Checksum mismatch for $IMAGE_NAME"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        exit 1
    fi
    echo "Checksum OK: $IMAGE_NAME"
}

resize_image() {
    echo "Resizing image to $IMAGE_SIZE"
    qemu-img resize "$IMAGE_NAME" "$IMAGE_SIZE"
}

create_vm() {
    if sudo qm status "$VMID" &>/dev/null; then
        if [[ "$DELETION_MODE" == "skip" ]]; then
            echo "VM/template $VMID already exists. Skipping creation (DELETION_MODE=skip)."
            exit 0
        elif [[ "$DELETION_MODE" == "force" ]]; then
            sudo qm destroy "$VMID" --destroy-unreferenced-disks && echo "Destroyed existing VM/template: $VMID"
        else
            echo "Invalid DELETION_MODE: $DELETION_MODE. Use 'force' or 'skip'."
            exit 1
        fi
    fi

    sudo qm create "$VMID" --name "$VM_NAME" \
        --ostype l26 \
        --memory 8192 --balloon 1024 \
        --agent 1 \
        --bios ovmf --efidisk0 "$STORAGE":0,pre-enrolled-keys=0 \
        --cpu host --cores 2 \
        --vga serial0 --serial0 socket \
        --net0 virtio,bridge=vmbr0,mtu=1500
    VM_CREATED=true
    sudo qm importdisk "$VMID" "$IMAGE_NAME" "$STORAGE"
    sudo qm set "$VMID" --scsihw virtio-scsi-pci --virtio0 "$STORAGE":vm-"$VMID"-disk-1,discard=on
    sudo qm set "$VMID" --boot order=virtio0
    sudo qm set "$VMID" --scsi1 "$STORAGE":cloudinit
}

configure_cloud_init() {
    # Snippets must be enabled for the datastore in Proxmox
    # See: https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_common_storage_properties
    echo "$CLOUD_INIT_CONFIG" | sudo tee /var/lib/vz/snippets/"${VMID}".yaml
    sudo qm set "$VMID" --cicustom "vendor=local:snippets/${VMID}.yaml"
    sudo qm set "$VMID" --tags "${VM_NAME},${OS_NAME}-${OS_VERSION},cloudinit"
    sudo qm set "$VMID" --ciuser "${CI_USER}"
    sudo qm set "$VMID" --sshkeys "${SSH_KEY}"
    sudo qm set "$VMID" --ipconfig0 ip=dhcp
}

convert_to_template() {
    sudo qm template "$VMID"
    echo "Successfully created template $VM_NAME (ID: $VMID)"
}

parse_args "$@"
validate_config
download_image
verify_checksum
resize_image
create_vm
configure_cloud_init
convert_to_template
