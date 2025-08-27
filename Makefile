# Define the script and config files
SCRIPT = ./import-cloud-template.sh
CONFIGS = debian-12-cloud.conf debian-12-cloud-docker.conf debian-13-cloud.conf debian-13-cloud-docker.conf ubuntu-24.04-cloud-docker.conf ubuntu-25.04-cloud.conf ubuntu-25.04-cloud-docker.conf fedora-42-cloud.conf almalinux-9-cloud.conf almalinux-10-cloud.conf

# Define targets for each config
.PHONY: all debian debian-docker debian13 debian13-docker ubuntu-docker ubuntu2504 ubuntu2504-docker fedora42 almalinux almalinux10

all: debian debian-docker debian13 debian13-docker ubuntu-docker ubuntu2504 ubuntu2504-docker fedora42 almalinux almalinux10

debian: debian-12-cloud.conf
	$(SCRIPT) -c $<

debian-docker: debian-12-cloud-docker.conf
	$(SCRIPT) -c $<

ubuntu-docker: ubuntu-24.04-cloud-docker.conf
	$(SCRIPT) -c $<

ubuntu2504: ubuntu-25.04-cloud.conf
	$(SCRIPT) -c $<

ubuntu2504-docker: ubuntu-25.04-cloud-docker.conf
	$(SCRIPT) -c $<

fedora42: fedora-42-cloud.conf
	$(SCRIPT) -c $<

almalinux: almalinux-9-cloud.conf
	$(SCRIPT) -c $<

almalinux10: almalinux-10-cloud.conf
	$(SCRIPT) -c $<

debian13: debian-13-cloud.conf
	$(SCRIPT) -c $<

debian13-docker: debian-13-cloud-docker.conf
	$(SCRIPT) -c $<
