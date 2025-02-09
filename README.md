# proxmox scripts

Download cloud images for Debian or Ubuntu and create a Proxmox template
with a basic `cloud-init` configuration. 

Easily extendible with new configurations for Debian based Linux distributions.

## Prerequisites
* `sudo`
* An SSH public key in the running user's home directory

## Preparation
* Configure snippets [storage](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#_common_storage_properties)
* Configure settings in the script
* Check the `VM_ID` in the config files. 
*  **Any existing VM or template with ID or `VM_ID++` `VM_ID` will be deleted**!

## Included configs
* `debian-12`
*  `ubuntu-24.04`

## Usage
```shell
$ ./import-cloud-template.sh [--install-docker] -c config-file.conf
```
