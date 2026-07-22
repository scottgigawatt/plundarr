#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Makefile: Automation for managing Plundarr Docker Compose services, config
#           resets, VPN validation, logs, and local convenience commands.
#

#
# Makefile target names.
#
ALL=all
DOWN=down
CLEAN=clean
NUKE=nuke
BUILD_DEPENDS=build-depends
CHECK_ENV=check-env
CHECK_RENDERED=check-rendered
BUILD=build
BUILD_MARAUDARR=build-maraudarr
BUILD_MULTIARCH=build-multiarch
ENSURE_MARAUDARR_IMAGE=ensure-maraudarr-image
UPDATE_MARAUDARR=update-maraudarr
RESET_CONFIG=reset-config
BACKUP_CONFIG=backup-config
CLEAN_CONFIG=clean-config
TEST_VPN=test-vpn
TEST_E2E=test-e2e
TEST_STACK=test-stack
TEST_DOWN=test-down
TEST_LOGS=test-logs
UP=up
SHIP=ship
CONFIGURE=configure
TEST_MARAUDARR_UNIT=test-maraudarr-unit
TEST_MARAUDARR=test-maraudarr
PRESETS=presets
AVAILABLE_SERVICES=services
CONFIG=config
COMPOSE_SERVICES=compose-services
ENV=env
PRINT_CONFIG=print-config
PRINT_ENV=print-env
PS=ps
LOGS=logs
OPEN=open
HELP=help
RUN=run
START=start
STOP=stop

TARGETS= \
	$(ALL) \
	$(DOWN) \
	$(CLEAN) \
	$(NUKE) \
	$(BUILD_DEPENDS) \
	$(CHECK_ENV) \
	$(CHECK_RENDERED) \
	$(BUILD) \
	$(BUILD_MARAUDARR) \
	$(BUILD_MULTIARCH) \
	$(ENSURE_MARAUDARR_IMAGE) \
	$(UPDATE_MARAUDARR) \
	$(RESET_CONFIG) \
	$(BACKUP_CONFIG) \
	$(CLEAN_CONFIG) \
	$(TEST_VPN) \
	$(TEST_E2E) \
	$(TEST_STACK) \
	$(TEST_DOWN) \
	$(TEST_LOGS) \
	$(UP) \
	$(SHIP) \
	$(CONFIGURE) \
	$(TEST_MARAUDARR_UNIT) \
	$(TEST_MARAUDARR) \
	$(PRESETS) \
	$(AVAILABLE_SERVICES) \
	$(CONFIG) \
	$(COMPOSE_SERVICES) \
	$(ENV) \
	$(PRINT_CONFIG) \
	$(PRINT_ENV) \
	$(PS) \
	$(LOGS) \
	$(OPEN) \
	$(HELP) \
	$(RUN) \
	$(START) \
	$(STOP)

#
# Docker Compose service names.
#
PRIVATEERR_SERVICE  ?= privateerr
GLUETUN_SERVICE     ?= gluetun
PROWLARR_SERVICE    ?= prowlarr
RADARR_SERVICE      ?= radarr
SONARR_SERVICE      ?= sonarr
BAZARR_SERVICE      ?= bazarr
QBITTORRENT_SERVICE ?= qbittorrent
SABNZBD_SERVICE     ?= sabnzbd
CLEANUPARR_SERVICE  ?= cleanuparr
DUPLICATI_SERVICE   ?= duplicati
SEERR_SERVICE       ?= seerr
HOMEPAGE_SERVICE    ?= homepage

#
# Config reset paths.
#
PRIVATEERR_EXAMPLE_WG_CONFIG   ?= test/examples/example-wg0.conf
PRIVATEERR_EXAMPLE_METADATA    ?= test/examples/example-privateerr.env
PRIVATEERR_GENERATED_WG_CONFIG ?= config/gluetun/wireguard/wg0.conf
PRIVATEERR_GENERATED_METADATA  ?= config/gluetun/wireguard/privateerr.env
PLUNDARR_GENERATED_PATHS       ?= config/privateerr/logs \
	config/gluetun/forwarded_port \
	config/gluetun/ip \
	config/gluetun/piaportforward.json \
	config/gluetun/servers \
	test/logs

#
# Docker Compose options.
#
OPTIONAL_SERVICES         ?= qbittorrent,cleanuparr
PRESET                    ?= plundarr
RENDERED_COMPOSE_FILE     ?= docker-compose.yml
COMPOSE_FILE              ?= $(RENDERED_COMPOSE_FILE)
ENV_FILE                  ?= .env
COMPOSE_ENV_FILE          ?= $(ENV_FILE)
COMPOSE_DOWN_TIMEOUT      ?= 30
COMPOSE_DOWN_OPTIONS      ?= --timeout $(COMPOSE_DOWN_TIMEOUT) --remove-orphans
COMPOSE_CLEAN_OPTIONS     ?= --timeout $(COMPOSE_DOWN_TIMEOUT) --volumes --remove-orphans
COMPOSE_UP_OPTIONS        ?= --force-recreate --pull always --detach --remove-orphans
COMPOSE_E2E_OPTIONS       ?= --force-recreate --pull always --detach --remove-orphans
COMPOSE_E2E_WAIT          ?= 300
COMPOSE_STACK_WAIT        ?= 600
COMPOSE_LOGS_OPTIONS      ?= --follow
MARAUDARR_IMAGE           ?= ghcr.io/scottgigawatt/maraudarr:latest
MARAUDARR_COMPOSE_FILE    ?= docker-compose.maraudarr.yml
MARAUDARR_ENV_FILE        ?= example.maraudarr.env
MARAUDARR_OUTPUT          ?= /output
MARAUDARR_BUILD_OPTIONS   ?= --pull --no-cache
MARAUDARR_BUILD_PLATFORMS ?= linux/amd64,linux/arm64,linux/arm/v7
MARAUDARR_MULTIARCH_IMAGE ?= maraudarr:multiarch-local
MARAUDARR_TEST_OUTPUT     ?= /tmp/maraudarr-matrix
CONFIG_PATH               ?= config
CONFIG_BACKUP_PATH        ?= backups

#
# Optional service selection used by Maraudarr and runtime tests.
#
empty :=
space := $(empty) $(empty)
comma := ,
SELECTED_OPTIONAL_SERVICES := $(strip $(subst $(comma),$(space),$(OPTIONAL_SERVICES)))
VPN_QBITTORRENT_SERVICE    ?= $(if $(filter qbittorrent,$(SELECTED_OPTIONAL_SERVICES)),$(QBITTORRENT_SERVICE),)
E2E_DOWNLOAD_SERVICES      ?= $(if $(filter qbittorrent,$(SELECTED_OPTIONAL_SERVICES)),$(QBITTORRENT_SERVICE),) \
	$(if $(filter sabnzbd,$(SELECTED_OPTIONAL_SERVICES)),$(SABNZBD_SERVICE),)
GLUETUN_DOWNLOADER_PORTS   ?= $(if $(filter qbittorrent,$(SELECTED_OPTIONAL_SERVICES)),8080,) \
	$(if $(filter sabnzbd,$(SELECTED_OPTIONAL_SERVICES)),8081,)

#
# End-to-end test services.
#
E2E_SERVICES ?= \
	$(PRIVATEERR_SERVICE) \
	$(GLUETUN_SERVICE) \
	$(E2E_DOWNLOAD_SERVICES)

#
# Web ports for services.
#
GLUETUN_WEB_PORTS ?= $(GLUETUN_DOWNLOADER_PORTS)
DIRECT_WEB_PORTS  ?= \
	$(PROWLARR_SERVICE):9696 \
	$(RADARR_SERVICE):7878 \
	$(SONARR_SERVICE):8989 \
	$(BAZARR_SERVICE):6767 \
	$(DUPLICATI_SERVICE):8200 \
	$(SEERR_SERVICE):5055 \
	$(HOMEPAGE_SERVICE):3000

#
# Testing commands.
#
PLUNDARR_VPN_TEST_CMD    ?= test/plundarr-vpn-test.sh
PLUNDARR_STACK_WAIT_CMD  ?= test/plundarr-stack-wait.sh
MARAUDARR_IMAGE_TEST_CMD ?= test/test-maraudarr-image.sh

#
# Docker Compose command compatible with 'docker compose' (v2) and 'docker-compose' (v1).
#
DOCKER_COMPOSE := $(shell \
	if docker compose version >/dev/null 2>&1; then \
		echo "docker compose"; \
	elif command -v docker-compose >/dev/null 2>&1; then \
		echo "docker-compose"; \
	else \
		echo ""; \
	fi)

#
# Always bind Compose interpolation to the generated environment file.
#
PLUNDARR_COMPOSE = $(DOCKER_COMPOSE) --env-file $(COMPOSE_ENV_FILE) -f $(COMPOSE_FILE)

#
# Docker Compose command used to build Maraudarr from its self-contained image
# context. This file and environment pair never replace generated Plundarr files.
#
MARAUDARR_COMPOSE = MARAUDARR_IMAGE="$(MARAUDARR_IMAGE)" \
	$(DOCKER_COMPOSE) --env-file $(MARAUDARR_ENV_FILE) -f $(MARAUDARR_COMPOSE_FILE)

#
# Hardened Docker options shared by every published Maraudarr image command.
# The host identity keeps generated files editable by the invoking user.
#
MARAUDARR_RUN_OPTIONS ?= \
	--rm \
	--read-only \
	--network none \
	--cap-drop ALL \
	--security-opt no-new-privileges:true \
	--tmpfs /tmp:rw,noexec,nosuid,size=64m \
	--user "$$(id -u):$$(id -g)" \
	--volume "$(CURDIR):$(MARAUDARR_OUTPUT):rw"

#
# Non-interactive and interactive Maraudarr image commands.
#
MARAUDARR_RUN = docker run $(MARAUDARR_RUN_OPTIONS) $(MARAUDARR_IMAGE)
MARAUDARR_RUN_INTERACTIVE = docker run --interactive --tty $(MARAUDARR_RUN_OPTIONS) $(MARAUDARR_IMAGE)
MARAUDARR_BUILD = $(MARAUDARR_COMPOSE) build $(MARAUDARR_BUILD_OPTIONS) maraudarr

#
# Localhost URL helper function.
#
define localhost_url
"http://localhost:`$(PLUNDARR_COMPOSE) port $(1) $(2) | cut -d: -f2`"
endef

#
# Help message formatting.
#
define help_line
	@printf "  %-24s %s\n" "$(1)" "$(2)"
endef

#
# Verify Docker Compose availability.
#
ifeq ($(DOCKER_COMPOSE),)
    $(error "Neither 'docker compose' nor 'docker-compose' is available. \
        Please install Docker Compose.")
endif

#
# Build dependencies.
#
DEPENDENCIES=docker

#
# Targets that are not files (i.e. never up-to-date); these will run every
# time the target is called or required.
#
.PHONY: $(TARGETS)

#
# $(ALL): Default makefile target. Starts the service stack.
#
# Dependencies:
#   $(UP) - Start the service stack.
#
$(ALL): $(UP)

#
# $(BUILD_DEPENDS): Ensure build dependencies are installed.
#
$(BUILD_DEPENDS):
	$(foreach exe,$(DEPENDENCIES), \
		$(if $(shell which $(exe) 2> /dev/null),,$(error "No $(exe) in PATH")))
	@# Verify Docker Compose availability.
	@$(DOCKER_COMPOSE) version >/dev/null 2>&1 || { \
		echo "Docker Compose be missin'."; \
		echo "Install docker compose or docker-compose. 🧭"; \
		exit 1; \
	}

#
# $(CHECK_ENV): Ensure the project environment file exists.
#
$(CHECK_ENV):
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "\nNo $(ENV_FILE) found. The ship needs a chart before it sails. 🗺️"; \
		echo "Run: make $(SHIP)"; \
		exit 1; \
	fi

#
# $(CHECK_RENDERED): Ensure the deployable Compose file exists.
#
$(CHECK_RENDERED):
	@if [ ! -f "$(COMPOSE_FILE)" ]; then \
		echo "\nNo $(COMPOSE_FILE) found. The fleet needs one final chart. 🗺️"; \
		echo "Run: make $(SHIP) OPTIONAL_SERVICES=$(OPTIONAL_SERVICES)"; \
		exit 1; \
	fi

#
# $(DOWN): Stops containers and removes containers and networks.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(DOWN): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	@echo "\nDroppin' anchor for the Plundarr fleet. ⚓"
	$(PLUNDARR_COMPOSE) down $(COMPOSE_DOWN_OPTIONS)

#
# $(RESET_CONFIG): Restores checked-in example config files after live tests.
#
$(RESET_CONFIG):
	@echo "\nRestorin' example maps for safe check-in. 🧭"
	mkdir -p $$(dirname $(PRIVATEERR_GENERATED_WG_CONFIG))
	cp $(PRIVATEERR_EXAMPLE_WG_CONFIG) $(PRIVATEERR_GENERATED_WG_CONFIG)
	cp $(PRIVATEERR_EXAMPLE_METADATA) $(PRIVATEERR_GENERATED_METADATA)

#
# $(BACKUP_CONFIG): Archives the complete config directory with a collision-safe
#                   timestamped filename.
#
$(BACKUP_CONFIG):
	@if [ ! -d "$(CONFIG_PATH)" ]; then \
		echo "No $(CONFIG_PATH) directory found to archive."; \
		exit 1; \
	fi
	@mkdir -p "$(CONFIG_BACKUP_PATH)"
	@timestamp=$$(date +%Y%m%d-%H%M%S); \
	archive="$(CONFIG_BACKUP_PATH)/plundarr-config-$${timestamp}.tar.gz"; \
	suffix=0; \
	while [ -e "$$archive" ]; do \
		suffix=$$((suffix + 1)); \
		archive="$(CONFIG_BACKUP_PATH)/plundarr-config-$${timestamp}-$${suffix}.tar.gz"; \
	done; \
	tar -czf "$$archive" "$(CONFIG_PATH)"; \
	echo "\nConfig cargo archived at $$archive. 📦"

#
# $(CLEAN_CONFIG): Deletes the complete generated config directory. This target
#                  is intentionally explicit because application state is lost.
#
$(CLEAN_CONFIG):
	@echo "\nRemoving the complete Plundarr config hold. ☠️"
	rm -rf "$(CONFIG_PATH)"
	@echo "Run make $(SHIP) to regenerate selected service folders and seed files. 🗺️"

#
# $(TEST_VPN): Validates a running stack's Privateerr and Gluetun VPN runtime state.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(TEST_VPN): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	@echo "\nInspectin' the VPN tunnel and port-forwarding loot. 🔎"
	PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
	PLUNDARR_ENV_FILE=$(COMPOSE_ENV_FILE) \
	PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
	PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
	PLUNDARR_QBITTORRENT_SERVICE=$(VPN_QBITTORRENT_SERVICE) \
	$(PLUNDARR_VPN_TEST_CMD)

#
# $(TEST_E2E): Starts core VPN/download services, validates VPN state, then removes them.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#   $(RESET_CONFIG) - Restore example config files.
#
$(TEST_E2E): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED) $(RESET_CONFIG)
	@echo "\nLaunching Privateerr, Gluetun, and selected download mates for one clean test voyage. 🌊"
	@status=0; \
	$(PLUNDARR_COMPOSE) \
		up $(COMPOSE_E2E_OPTIONS) $(E2E_SERVICES) || status=$$?; \
	if [ "$$status" -eq 0 ]; then \
		PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
		PLUNDARR_ENV_FILE=$(COMPOSE_ENV_FILE) \
		PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
		PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
		PLUNDARR_QBITTORRENT_SERVICE=$(VPN_QBITTORRENT_SERVICE) \
		PLUNDARR_WAIT_SECONDS=$(COMPOSE_E2E_WAIT) \
		$(PLUNDARR_VPN_TEST_CMD) || status=$$?; \
	fi; \
	$(PLUNDARR_COMPOSE) down $(COMPOSE_DOWN_OPTIONS); \
	$(MAKE) --no-print-directory $(RESET_CONFIG); \
	exit "$$status"

#
# $(TEST_STACK): Starts every service, waits for health, validates VPN and qBittorrent state.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#   $(RESET_CONFIG) - Restore example config files.
#
$(TEST_STACK): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED) $(RESET_CONFIG)
	@echo "\nLaunching the whole Plundarr fleet for a full-stack test voyage. 🏴‍☠️"
	@status=0; \
	$(PLUNDARR_COMPOSE) up $(COMPOSE_UP_OPTIONS) || status=$$?; \
	if [ "$$status" -eq 0 ]; then \
		PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
		PLUNDARR_ENV_FILE=$(COMPOSE_ENV_FILE) \
		PLUNDARR_STACK_WAIT_SECONDS=$(COMPOSE_STACK_WAIT) \
		$(PLUNDARR_STACK_WAIT_CMD) || status=$$?; \
	fi; \
	if [ "$$status" -eq 0 ]; then \
		PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
		PLUNDARR_ENV_FILE=$(COMPOSE_ENV_FILE) \
		PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
		PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
		PLUNDARR_QBITTORRENT_SERVICE=$(VPN_QBITTORRENT_SERVICE) \
		PLUNDARR_WAIT_SECONDS=$(COMPOSE_STACK_WAIT) \
		$(PLUNDARR_VPN_TEST_CMD) || status=$$?; \
	fi; \
	if [ "$$status" -ne 0 ]; then \
		$(PLUNDARR_COMPOSE) ps; \
		$(PLUNDARR_COMPOSE) logs --tail=120; \
	fi; \
	$(MAKE) --no-print-directory $(RESET_CONFIG); \
	exit "$$status"

#
# $(TEST_DOWN): Stops and removes containers, then restores example config files.
#
# Dependencies:
#   $(DOWN) - Stop and remove the stack.
#   $(RESET_CONFIG) - Restore example config files.
#
$(TEST_DOWN): $(DOWN) $(RESET_CONFIG)

#
# $(NUKE): Removes containers, images, generated files, and resets example config.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(NUKE): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	@echo "\nFirin' the clean broadside. Repo-safe files stay aboard. 💣"
	$(PLUNDARR_COMPOSE) down $(COMPOSE_CLEAN_OPTIONS) --rmi all

	@echo "Scrubbin' generated logs and Gluetun state. 🧽"
	rm -rf $(PLUNDARR_GENERATED_PATHS)

	@$(MAKE) --no-print-directory $(RESET_CONFIG)

#
# $(UP): (Re)creates and starts every service in the stack.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(UP): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	@echo "\nRaisin' the whole Plundarr fleet. 🏴‍☠️"
	$(PLUNDARR_COMPOSE) up $(COMPOSE_UP_OPTIONS)

#
# $(ENSURE_MARAUDARR_IMAGE): Uses a local Maraudarr image, pulls the published
#                            image when missing, or builds from this checkout.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#
$(ENSURE_MARAUDARR_IMAGE): $(BUILD_DEPENDS)
	@if docker image inspect "$(MARAUDARR_IMAGE)" >/dev/null 2>&1; then \
		echo "⚓ Found Maraudarr aboard locally: $(MARAUDARR_IMAGE)"; \
	else \
		echo "🌊 No local Maraudarr image found. Checking GHCR..."; \
		if docker pull "$(MARAUDARR_IMAGE)" >/dev/null 2>&1; then \
			echo "✅ Published Maraudarr image is ready."; \
		else \
			echo "🛠️ Published image unavailable. Building from this checkout..."; \
			$(MARAUDARR_BUILD) || { \
				echo "☠️ Maraudarr could not be pulled or built."; \
				exit 1; \
			}; \
		fi; \
	fi
	@docker image inspect "$(MARAUDARR_IMAGE)" >/dev/null 2>&1 || { \
		echo "☠️ Maraudarr image is still missing: $(MARAUDARR_IMAGE)"; \
		exit 1; \
	}

#
# $(UPDATE_MARAUDARR): Refreshes the published Maraudarr image from GHCR.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#
$(UPDATE_MARAUDARR): $(BUILD_DEPENDS)
	@echo "🌊 Fetching the newest published Maraudarr image..."
	docker pull "$(MARAUDARR_IMAGE)"

#
# $(SHIP): Generates the comment-rich Compose and environment files.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare a local Maraudarr image.
#
$(SHIP): $(ENSURE_MARAUDARR_IMAGE)

	$(MARAUDARR_RUN) build \
		--preset "$(PRESET)" \
		--remove qbittorrent,cleanuparr \
		--add "$(OPTIONAL_SERVICES)" \
		--output "$(MARAUDARR_OUTPUT)"

#
# $(CONFIGURE): Opens Maraudarr's interactive preset and service configurator.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare a local Maraudarr image.
#
$(CONFIGURE): $(ENSURE_MARAUDARR_IMAGE)
	$(MARAUDARR_RUN_INTERACTIVE) configure --output "$(MARAUDARR_OUTPUT)"

#
# $(BUILD_MARAUDARR): Builds Maraudarr locally using its dedicated Compose chart.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure Docker and Docker Compose are installed.
#
$(BUILD_MARAUDARR): $(BUILD_DEPENDS)
	$(MARAUDARR_BUILD)

#
# $(BUILD): Alias for build-maraudarr to match the related Privateerr project.
#
# Dependencies:
#   $(BUILD_MARAUDARR) - Build the local Maraudarr image.
#
$(BUILD): $(BUILD_MARAUDARR)

#
# $(BUILD_MULTIARCH): Verifies Maraudarr builds for every published architecture.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure Docker and Docker Compose are installed.
#
$(BUILD_MULTIARCH): $(BUILD_DEPENDS)
	docker buildx build \
		--pull \
		--platform "$(MARAUDARR_BUILD_PLATFORMS)" \
		--tag "$(MARAUDARR_MULTIARCH_IMAGE)" \
		--file docker/Dockerfile \
		docker

#
# $(TEST_MARAUDARR_UNIT): Runs Maraudarr's Python unit tests.
#
$(TEST_MARAUDARR_UNIT):
	PYTHONDONTWRITEBYTECODE=1 \
	PYTHONPATH=docker/src \
	MARAUDARR_CATALOG_ROOT=docker \
		python3 -m unittest discover -s docker/tests -v

#
# $(TEST_MARAUDARR): Runs unit tests and the representative Compose matrix.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure Docker and Docker Compose are installed.
#   $(TEST_MARAUDARR_UNIT) - Run Maraudarr's Python unit tests.
#
$(TEST_MARAUDARR): $(BUILD_DEPENDS) $(TEST_MARAUDARR_UNIT)
	$(MARAUDARR_IMAGE_TEST_CMD)
	MARAUDARR_TEST_OUTPUT="$(MARAUDARR_TEST_OUTPUT)" \
		test/test-maraudarr-matrix.sh

#
# $(PRESETS): Lists presets and their exact default services.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare a local Maraudarr image.
#
$(PRESETS): $(ENSURE_MARAUDARR_IMAGE)
	$(MARAUDARR_RUN) --plain presets

#
# $(AVAILABLE_SERVICES): Lists every selectable Plundarr service.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare a local Maraudarr image.
#
$(AVAILABLE_SERVICES): $(ENSURE_MARAUDARR_IMAGE)
	$(MARAUDARR_RUN) --plain services

#
# $(CONFIG): Renders the actual data model to be applied on the Docker Engine.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#
$(CONFIG): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	$(PLUNDARR_COMPOSE) config

#
# $(COMPOSE_SERVICES): Lists services in the rendered Docker Compose file.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(COMPOSE_SERVICES): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	$(PLUNDARR_COMPOSE) config --services

#
# $(ENV): Prints the environment Docker Compose uses for interpolation.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(ENV): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	@$(PLUNDARR_COMPOSE) config --environment | \
	awk -F '=' ' \
		NR == FNR { \
			if ($$0 ~ /^[A-Za-z_][A-Za-z0-9_]*=/) values[$$1] = $$0; \
			next; \
		} \
		$$0 ~ /^[A-Za-z_][A-Za-z0-9_]*=/ && $$1 in values { \
			print values[$$1] \
		} \
	' - $(COMPOSE_ENV_FILE)

#
# $(PRINT_CONFIG): Prints the raw uncommented docker compose yaml configuration.
#
$(PRINT_CONFIG): $(CHECK_RENDERED)
	@awk '{ \
		sub(/#.*/, ""); \
		sub(/[[:space:]]+$$/, ""); \
		if (NF) print \
	}' $(COMPOSE_FILE)

#
# $(PRINT_ENV): Prints the raw uncommented docker compose env configuration.
#
# Dependencies:
#   $(CHECK_ENV) - Ensure the environment file exists.
#
$(PRINT_ENV): $(CHECK_ENV)
	@awk '{ \
		sub(/#.*/, ""); \
		sub(/[[:space:]]+$$/, ""); \
		if (NF) print \
	}' $(COMPOSE_ENV_FILE)

#
# $(LOGS): View output from stack containers.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(LOGS): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	@echo "\nReadin' logs for the fleet. 🔎"
	$(PLUNDARR_COMPOSE) logs $(COMPOSE_LOGS_OPTIONS)

#
# $(PS): Shows current stack container status.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(PS): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	$(PLUNDARR_COMPOSE) ps

#
# $(TEST_LOGS): View output from stack containers.
#
# Dependencies:
#   $(LOGS) - Show logs for the service stack.
#
$(TEST_LOGS): $(LOGS)

#
# $(OPEN): Opens the compose services in the default web browser.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(OPEN): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	@echo "\nOpening compose services in default browser"
	open \
		$(foreach port,$(GLUETUN_WEB_PORTS), \
			$(call localhost_url,$(GLUETUN_SERVICE),$(port))) \
		$(foreach mapping,$(DIRECT_WEB_PORTS), \
			$(call localhost_url, \
				$(word 1,$(subst :, ,$(mapping))), \
				$(word 2,$(subst :, ,$(mapping)))))

#
# $(HELP): Print help information.
#
$(HELP):
	@echo "Usage: make [TARGET]"
	@echo ""
	@echo "Targets:"
	$(call help_line,$(ALL),Starts the service stack.)
	$(call help_line,$(BUILD_DEPENDS),Ensures build dependencies are installed.)
	$(call help_line,$(CHECK_ENV),Ensures $(ENV_FILE) exists.)
	$(call help_line,$(CHECK_RENDERED),Ensures $(COMPOSE_FILE) exists.)
	$(call help_line,$(BUILD),Builds the local Maraudarr image.)
	$(call help_line,$(BUILD_MARAUDARR),Builds Maraudarr from the docker context.)
	$(call help_line,$(BUILD_MULTIARCH),Checks every published image architecture.)
	$(call help_line,$(UPDATE_MARAUDARR),Refreshes the published Maraudarr image.)
	$(call help_line,$(DOWN),Stops and removes the service stack.)
	$(call help_line,$(CLEAN),Stops the stack and restores example config files.)
	$(call help_line,$(NUKE),Removes containers plus images and generated files.)
	$(call help_line,$(RESET_CONFIG),Restores example VPN config files.)
	$(call help_line,$(BACKUP_CONFIG),Archives config with a unique timestamp.)
	$(call help_line,$(CLEAN_CONFIG),Deletes the complete generated config tree.)
	$(call help_line,$(TEST_VPN),Validates the VPN runtime state.)
	$(call help_line,$(TEST_E2E),Tests VPN plus selected download services.)
	$(call help_line,$(TEST_STACK),Tests the full stack health and VPN state.)
	$(call help_line,$(TEST_DOWN),Stops the stack and restores example configs.)
	$(call help_line,$(TEST_LOGS),Shows logs for the service stack.)
	$(call help_line,$(UP),(Re)creates and starts every service.)
	$(call help_line,$(SHIP),Generates the selected Plundarr preset and services.)
	$(call help_line,$(CONFIGURE),Opens Maraudarr's interactive configurator.)
	$(call help_line,$(TEST_MARAUDARR_UNIT),Runs Maraudarr's Python unit tests.)
	$(call help_line,$(TEST_MARAUDARR),Tests Maraudarr and generated charts.)
	$(call help_line,$(PRESETS),Lists presets and their default services.)
	$(call help_line,$(AVAILABLE_SERVICES),Lists every selectable service.)
	$(call help_line,$(CONFIG),Renders the Docker Compose model.)
	$(call help_line,$(COMPOSE_SERVICES),Lists generated Compose services.)
	$(call help_line,$(ENV),Prints evaluated Compose env values.)
	$(call help_line,$(PRINT_CONFIG),Prints uncommented Compose yaml.)
	$(call help_line,$(PRINT_ENV),Prints uncommented Compose env values.)
	$(call help_line,$(PS),Shows stack container status.)
	$(call help_line,$(LOGS),Shows logs for the service stack.)
	$(call help_line,$(OPEN),Opens service sites in the default browser.)
	$(call help_line,$(RUN),Alias for $(UP) $(OPEN) and $(LOGS).)
	$(call help_line,$(START),Alias for $(UP).)
	$(call help_line,$(STOP),Alias for $(DOWN).)
	$(call help_line,$(HELP),Displays this help message.)

#
# $(CLEAN): Alias for test-down.
#
# Dependencies:
#   $(TEST_DOWN) - Stop the stack and restore example config files.
#
$(CLEAN): $(TEST_DOWN)

#
# $(START): Alias for up.
#
# Dependencies:
#   $(UP) - Start the service stack.
#
$(START): $(UP)

#
# $(STOP): Alias for down.
#
# Dependencies:
#   $(DOWN) - Stop and remove the stack.
#
$(STOP): $(DOWN)

#
# $(RUN): Alias for up, open, logs.
#
# Dependencies:
#   $(UP) - Start the service stack.
#
$(RUN): $(UP)
	@$(MAKE) --no-print-directory $(OPEN)
	@$(MAKE) --no-print-directory $(LOGS)
