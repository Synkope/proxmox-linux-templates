# Define the script and config files
SCRIPT = ./import-cloud-template.sh
CONFIGS = debian-12-cloud.conf debian-12-cloud-docker.conf debian-13-cloud.conf debian-13-cloud-docker.conf ubuntu-24.04-cloud.conf ubuntu-24.04-cloud-docker.conf ubuntu-25.04-cloud.conf ubuntu-25.04-cloud-docker.conf fedora-42-cloud.conf almalinux-9-cloud.conf almalinux-10-cloud.conf

# Define targets for each config
.PHONY: all debian-12 debian-12-docker debian-13 debian-13-docker ubuntu-24.04 ubuntu-24.04-docker ubuntu-25.04 ubuntu-25.04-docker fedora-42 almalinux-9 almalinux-10

all: debian-12 debian-12-docker debian-13 debian-13-docker ubuntu-24.04 ubuntu-24.04-docker ubuntu-25.04 ubuntu-25.04-docker fedora-42 almalinux-9 almalinux-10

debian-12: debian-12-cloud.conf
	$(SCRIPT) -c $<

debian-12-docker: debian-12-cloud-docker.conf
	$(SCRIPT) -c $<

ubuntu-24.04: ubuntu-24.04-cloud.conf
	$(SCRIPT) -c $<

ubuntu-24.04-docker: ubuntu-24.04-cloud-docker.conf
	$(SCRIPT) -c $<

ubuntu-25.04: ubuntu-25.04-cloud.conf
	$(SCRIPT) -c $<

ubuntu-25.04-docker: ubuntu-25.04-cloud-docker.conf
	$(SCRIPT) -c $<

fedora-42: fedora-42-cloud.conf
	$(SCRIPT) -c $<

almalinux-9: almalinux-9-cloud.conf
	$(SCRIPT) -c $<

almalinux-10: almalinux-10-cloud.conf
	$(SCRIPT) -c $<

debian-13: debian-13-cloud.conf
	$(SCRIPT) -c $<

debian-13-docker: debian-13-cloud-docker.conf
	$(SCRIPT) -c $<
