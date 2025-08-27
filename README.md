# proxmox-linux-templates

Download cloud images for multiple Linux distributions and create Proxmox templates
with optimized `cloud-init` configurations.

Supports Debian, Ubuntu, Fedora, and AlmaLinux with optional Docker pre-installation.

## Prerequisites
* `sudo`
* An SSH public key in the running user's home directory

## Preparation
* Configure snippets [storage](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_common_storage_properties) in Proxmox
* Ensure your SSH public key exists at `~/.ssh/id_ed25519.pub` (or update `SSH_KEY` path in the script)
* Review the VMID assignments in the table below
* **⚠️ WARNING: Any existing VM or template with matching VMIDs will be destroyed!**
* Optional: Modify `STORAGE` setting in the script (defaults to `local-zfs`)

## Included configs
* **Debian**: `debian-12`, `debian-13` (current stable)
* **Ubuntu**: `ubuntu-24.04` (LTS), `ubuntu-25.04` (latest)
* **Fedora**: `fedora-42` (latest)
* **AlmaLinux**: `almalinux-9`, `almalinux-10` (latest)
* **Docker variants**: Available for Debian and Ubuntu distributions

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
```shell
$ ./import-cloud-template.sh -c config-file.conf
```

### Makefile Targets (Recommended)
```shell
# Debian
make debian-12 debian-12-docker debian-13 debian-13-docker

# Ubuntu  
make ubuntu-24.04 ubuntu-24.04-docker ubuntu-25.04 ubuntu-25.04-docker

# RHEL-like distros
make fedora-42 almalinux-9 almalinux-10

# Build all templates
make all
```
