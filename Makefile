SCRIPT = ./import-cloud-template.sh
DISTROS = debian-12 debian-12-docker debian-13 debian-13-docker \
          ubuntu-24.04 ubuntu-24.04-docker ubuntu-26.04 ubuntu-26.04-docker \
          fedora-43 fedora-44 almalinux-9 almalinux-10

.PHONY: all $(DISTROS)

all: $(DISTROS)

$(DISTROS): %: %-cloud.conf
	$(SCRIPT) -c $<
