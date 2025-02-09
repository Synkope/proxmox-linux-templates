# Define the script and config files
SCRIPT = ./import-cloud-template.sh
CONFIGS = ubuntu-24.04-cloud.conf debian-12-cloud.conf debian-12-cloud-docker.conf ubuntu-24.04-cloud-docker.conf

# Define targets for each config
.PHONY: all ubuntu debian debian-docker ubuntu-docker

all: ubuntu debian debian-docker ubuntu-docker

ubuntu: ubuntu-24.04-cloud.conf
	$(SCRIPT) -c $<

debian: debian-12-cloud.conf
	$(SCRIPT) -c $<

debian-docker: debian-12-cloud-docker.conf
	$(SCRIPT) -c $<

ubuntu-docker: ubuntu-24.04-cloud-docker.conf
	$(SCRIPT) -c $<
