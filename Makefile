# Define the script and config files
SCRIPT = ./import-cloud-template.sh
CONFIGS = ubuntu-24.04-cloud.conf debian-12-cloud.conf debian-12-cloud-docker.conf ubuntu-24.04-cloud-docker.conf fedora-41-cloud.conf almalinux-9-cloud.conf

# Define targets for each config
.PHONY: all ubuntu debian debian-docker ubuntu-docker fedora almalinux

all: ubuntu debian debian-docker ubuntu-docker fedora almalinux

ubuntu: ubuntu-24.04-cloud.conf
	$(SCRIPT) -c $<

debian: debian-12-cloud.conf
	$(SCRIPT) -c $<

debian-docker: debian-12-cloud-docker.conf
	$(SCRIPT) -c $<

ubuntu-docker: ubuntu-24.04-cloud-docker.conf
	$(SCRIPT) -c $<

fedora: fedora-41-cloud.conf
	$(SCRIPT) -c $<

almalinux: almalinux-9-cloud.conf
	$(SCRIPT) -c $<
