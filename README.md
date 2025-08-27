# proxmox-linux-templates

Download cloud images for multiple Linux distributions and create Proxmox templates
with optimized `cloud-init` configurations.

Supports Debian, Ubuntu, Fedora, and AlmaLinux with optional Docker pre-installation.

## Prerequisites

- `sudo` access
- An SSH public key in the running user's home directory

## Preparation

- Configure snippets [storage](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_common_storage_properties) in Proxmox
- Ensure your SSH public key exists at `~/.ssh/id_ed25519.pub` (or configure `SSH_KEY` variable)
- Review the VMID assignments in the table below
- **Optional**: Configure storage, user, and SSH key settings (see Configuration section below)

> **⚠️ WARNING**: By default, the script will skip creation if a VM/template already exists. Use `--force` to overwrite existing templates.

## Included Configurations

- **Debian**: `debian-12`, `debian-13` (current stable)
- **Ubuntu**: `ubuntu-24.04` (LTS), `ubuntu-25.04` (latest)
- **Fedora**: `fedora-42` (latest)
- **AlmaLinux**: `almalinux-9`, `almalinux-10` (latest)
- **Docker variants**: Available for Debian and Ubuntu distributions

## VMID Assignments
| Distribution | Basic | Docker |
|--------------|-------|---------|
| **Debian 12** | 5100 | 5150 |
| **Debian 13** | 5200 | 5250 |
| **Ubuntu 24.04 LTS** | 5300 | 5350 |
| **Ubuntu 25.04** | 5400 | 5450 |
| **Fedora 42** | 5500 | - |
| **AlmaLinux 9** | 5600 | - |
| **AlmaLinux 10** | 5700 | - |

## Usage

### Direct Script Usage

```bash
# Basic usage (skips existing templates by default)
./import-cloud-template.sh -c config-file.conf

# Explicitly skip existing templates
./import-cloud-template.sh -c config-file.conf --skip

# Force deletion of existing templates
./import-cloud-template.sh -c config-file.conf --force
```

### Makefile Targets (Recommended)

```bash
# Debian
make debian-12 debian-12-docker debian-13 debian-13-docker

# Ubuntu
make ubuntu-24.04 ubuntu-24.04-docker ubuntu-25.04 ubuntu-25.04-docker

# Enterprise/Rolling Release
make fedora-42 almalinux-9 almalinux-10

# Build all templates
make all
```

## Configuration

The script supports several configurable options that can be set via environment variables:

### Storage Configuration
- **STORAGE** - Proxmox storage name for VM disks and cloud-init
- **Default**: `local-zfs`
- **Usage**: Where VM disks and templates will be stored

### User Configuration  
- **CI_USER** - Username for cloud-init and SSH access
- **Default**: Current user (`$USER`)
- **Usage**: Default user account created in VMs

### SSH Configuration
- **SSH_KEY** - Path to SSH public key file
- **Default**: `~/.ssh/id_ed25519.pub`  
- **Usage**: Public key injected into VMs for passwordless access

### Setting Configuration Options

```bash
# Method 1: Environment variables
export STORAGE="local-lvm"
export CI_USER="admin" 
export SSH_KEY="/path/to/custom/key.pub"
make debian-13

# Method 2: Inline with command
STORAGE="nvme-pool" ./import-cloud-template.sh -c ubuntu-24.04-cloud.conf

# Method 3: In shell session
export STORAGE="ceph-storage"
export CI_USER="devops"
./import-cloud-template.sh -c fedora-42-cloud.conf
```

## Deletion Control

By default, the script will **skip creation if a VM/template already exists** (safe mode). You can control this behavior:

### Command Line Options

- `--skip` - Skip creation if VM/template already exists (default)
- `--force` - Delete existing VM/template

### Environment Variables

```bash
# Deletion behavior
export DELETION_MODE="skip"   # Default - skip existing templates
export DELETION_MODE="force"  # Force mode - delete existing templates

# Combined example with all configurable options
export STORAGE="local-lvm"
export CI_USER="admin"
export SSH_KEY="/home/admin/.ssh/id_rsa.pub"
export DELETION_MODE="skip"
make all
```

