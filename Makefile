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
CLEAN_ARTIFACTS=clean-artifacts
NUKE=nuke
BUILD_DEPENDS=build-depends
CHECK_ENV=check-env
CHECK_RENDERED=check-rendered
BUILD=build
BUILD_MARAUDARR=build-maraudarr
BUILD_MULTIARCH=build-multiarch
SMOKE_MARAUDARR=smoke-maraudarr
DOCS=docs
DOCS_SERVE=docs-serve
DOCS_DEPENDENCIES=docs-dependencies
ENSURE_MARAUDARR_IMAGE=ensure-maraudarr-image
PULL_MARAUDARR=pull-maraudarr
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
TEST_WORKFLOW_HELPERS=test-workflow-helpers
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
	$(CLEAN_ARTIFACTS) \
	$(NUKE) \
	$(BUILD_DEPENDS) \
	$(CHECK_ENV) \
	$(CHECK_RENDERED) \
	$(BUILD) \
	$(BUILD_MARAUDARR) \
	$(BUILD_MULTIARCH) \
	$(SMOKE_MARAUDARR) \
	$(DOCS) \
	$(DOCS_SERVE) \
	$(DOCS_DEPENDENCIES) \
	$(ENSURE_MARAUDARR_IMAGE) \
	$(PULL_MARAUDARR) \
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
	$(TEST_WORKFLOW_HELPERS) \
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
# Punctuation expanded after Make parses $(call ...) arguments.
#
COMMA=,

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
NZBGET_SERVICE      ?= nzbget
CLEANUPARR_SERVICE  ?= cleanuparr
DUPLICATI_SERVICE   ?= duplicati
SEERR_SERVICE       ?= seerr
HOMEPAGE_SERVICE    ?= homepage

#
# Config reset paths.
#
PRIVATEERR_EXAMPLE_WG_CONFIG   ?= test/examples/example-wg0.conf
PRIVATEERR_EXAMPLE_METADATA    ?= test/examples/example-privateerr.env
PRIVATEERR_GENERATED_WG_CONFIG ?= $(CONFIG_PATH)/gluetun/wireguard/wg0.conf
PRIVATEERR_GENERATED_METADATA  ?= $(CONFIG_PATH)/gluetun/wireguard/privateerr.env
PLUNDARR_GENERATED_PATHS       ?= $(CONFIG_PATH)/privateerr/logs \
	$(CONFIG_PATH)/gluetun/forwarded_port \
	$(CONFIG_PATH)/gluetun/ip \
	$(CONFIG_PATH)/gluetun/piaportforward.json \
	$(CONFIG_PATH)/gluetun/servers \
	test/logs

#
# Docker Compose options.
#
PRESET                    ?= plundarr
ADD_SERVICES              ?=
REMOVE_SERVICES           ?=
DEPLOYMENT_ROOT           ?= dist
DEPLOYMENT_PATH           ?= $(DEPLOYMENT_ROOT)/$(PRESET)
RENDERED_COMPOSE_FILE     ?= $(DEPLOYMENT_PATH)/docker-compose.yml
COMPOSE_FILE              ?= $(RENDERED_COMPOSE_FILE)
ENV_FILE                  ?= $(DEPLOYMENT_PATH)/.env
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
MARAUDARR_OUTPUT_ROOT     ?= $(MARAUDARR_OUTPUT)/$(DEPLOYMENT_ROOT)
MARAUDARR_BUILD_OPTIONS   ?= --pull --no-cache
MARAUDARR_BUILD_PLATFORMS ?= linux/amd64,linux/arm64,linux/arm/v7
MARAUDARR_MULTIARCH_IMAGE ?= maraudarr:multiarch-local
MARAUDARR_TEST_OUTPUT     ?= /tmp/maraudarr-matrix
MARAUDARR_SMOKE_PRESET    ?= plundarr
MARAUDARR_SMOKE_ADD       ?=
MARAUDARR_SMOKE_REMOVE    ?=
MARAUDARR_SMOKE_FILE      ?= config/README.md
CONFIG_PATH               ?= $(DEPLOYMENT_PATH)/config
CONFIG_BACKUP_PATH        ?= $(DEPLOYMENT_PATH)/backups
PYTHON_BIN                ?= python3

#
# Reject the retired service-selection interface instead of silently producing
# a different stack than the caller requested.
#
ifneq ($(origin OPTIONAL_SERVICES),undefined)
$(error OPTIONAL_SERVICES was removed. Use ADD_SERVICES and REMOVE_SERVICES)
endif

#
# Developer documentation settings.
#
MKDOCS             ?= mkdocs
DOCS_SITE_PATH     ?= site
DOCS_SERVE_ADDRESS ?= 127.0.0.1:8000
DOCS_VENV           ?= .venv-docs
DOCS_PYTHON         ?= $(DOCS_VENV)/bin/python
DOCS_MKDOCS         ?= $(DOCS_VENV)/bin/$(MKDOCS)
DOCS_REQUIREMENTS   ?= requirements-docs.txt
DEVELOPER_ARTIFACTS ?= $(DOCS_VENV) site .ruff_cache .pytest_cache test/logs

#
# Rendered service selection used by runtime tests.
#
SELECTED_COMPOSE_SERVICES = $(strip $(shell $(PLUNDARR_COMPOSE) config --services 2>/dev/null))
VPN_QBITTORRENT_SERVICE   ?= $(filter $(QBITTORRENT_SERVICE),$(SELECTED_COMPOSE_SERVICES))
E2E_DOWNLOAD_SERVICES     ?= $(filter $(QBITTORRENT_SERVICE) $(SABNZBD_SERVICE) $(NZBGET_SERVICE),$(SELECTED_COMPOSE_SERVICES))
GLUETUN_DOWNLOADER_PORTS  ?= $(if $(filter $(QBITTORRENT_SERVICE),$(SELECTED_COMPOSE_SERVICES)),8080,) \
	$(if $(filter $(SABNZBD_SERVICE),$(SELECTED_COMPOSE_SERVICES)),8081,) \
	$(if $(filter $(NZBGET_SERVICE),$(SELECTED_COMPOSE_SERVICES)),6789,)

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
WORKFLOW_HELPERS_TEST_CMD ?= test/test-workflow-helpers.sh

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
PLUNDARR_COMPOSE = $(DOCKER_COMPOSE) \
	--env-file $(COMPOSE_ENV_FILE) \
	-f $(COMPOSE_FILE)

#
# Docker Compose command used to build Maraudarr from its self-contained image
# context. This file and environment pair never replace generated Plundarr files.
#
MARAUDARR_COMPOSE = MARAUDARR_IMAGE="$(MARAUDARR_IMAGE)" \
	$(DOCKER_COMPOSE) \
	--env-file $(MARAUDARR_ENV_FILE) \
	-f $(MARAUDARR_COMPOSE_FILE)

#
# Hardened Docker options shared by every published Maraudarr image command.
# The host identity keeps generated files editable by the invoking user.
#
MARAUDARR_BASE_RUN_OPTIONS ?= \
	--rm \
	--read-only \
	--network none \
	--cap-drop ALL \
	--security-opt no-new-privileges:true \
	--tmpfs /tmp:rw,noexec,nosuid,size=64m \
	--user "$$(id -u):$$(id -g)"

#
# Normal generation writes into this checkout. The smoke target adds its own
# disposable output mount so it cannot alter a real generated deployment.
#
MARAUDARR_RUN_OPTIONS ?= \
	$(MARAUDARR_BASE_RUN_OPTIONS) \
	--volume "$(CURDIR):$(MARAUDARR_OUTPUT):rw"

#
# Non-interactive, styled-list, and interactive Maraudarr image commands.
#
MARAUDARR_RUN = docker run $(MARAUDARR_RUN_OPTIONS) $(MARAUDARR_IMAGE)
MARAUDARR_RUN_STYLED = docker run --tty $(MARAUDARR_RUN_OPTIONS) $(MARAUDARR_IMAGE)
MARAUDARR_RUN_INTERACTIVE = docker run --interactive --tty $(MARAUDARR_RUN_OPTIONS) $(MARAUDARR_IMAGE)
MARAUDARR_BUILD = $(MARAUDARR_COMPOSE) build $(MARAUDARR_BUILD_OPTIONS) maraudarr

#
# Localhost URL helper function.
#
define localhost_url
"http://localhost:`$(PLUNDARR_COMPOSE) port $(1) $(2) | cut -d: -f2`"
endef

#
# Terminal presentation settings. Recipe-time checks enable color only for
# interactive terminals and honor the standard NO_COLOR opt-out.
#
# See https://no-color.org/ for the opt-out convention.
COLOR_RESET   := \033[0m
COLOR_TITLE   := \033[1;36m
COLOR_COMMAND := \033[1;33m
COLOR_INFO    := \033[0;36m
COLOR_SUCCESS := \033[0;32m
COLOR_WARNING := \033[1;33m
COLOR_ERROR   := \033[1;31m
COLOR_MUTED   := \033[0;37m

#
# Shell fragments used by user-facing Make output. Test stdout here instead of
# inside $(shell ...): GNU Make captures expansion output before a recipe sees
# the caller's terminal.
#
define print_line_inline
if [ -t 1 ] && [ -z "$$NO_COLOR" ]; then \
	printf '\n%b%s%b\n' "$(1)" "$(2)" "$(COLOR_RESET)"; \
else \
	printf '\n%s\n' "$(2)"; \
fi
endef

define print_detail_inline
if [ -t 1 ] && [ -z "$$NO_COLOR" ]; then \
	printf '  %b%s%b\n' "$(1)" "$(2)" "$(COLOR_RESET)"; \
else \
	printf '  %s\n' "$(2)"; \
fi
endef

#
# User-facing Make output helpers.
#
define announce
	@$(call print_line_inline,$(COLOR_INFO),$(1))
endef

define announce_success
	@$(call print_line_inline,$(COLOR_SUCCESS),$(1))
endef

define announce_warning
	@$(call print_line_inline,$(COLOR_WARNING),$(1))
endef

define announce_error
	@$(call print_line_inline,$(COLOR_ERROR),$(1))
endef

define announce_title
	@$(call print_line_inline,$(COLOR_TITLE),$(1))
endef

define announce_detail
	@$(call print_detail_inline,$(COLOR_MUTED),$(1))
endef

#
# Help message formatting.
#
define help_line
	@if [ -t 1 ] && [ -z "$$NO_COLOR" ]; then \
		printf '  %b%-24s%b %s\n' "$(COLOR_COMMAND)" "$(1)" "$(COLOR_RESET)" "$(2)"; \
	else \
		printf '  %-24s %s\n' "$(1)" "$(2)"; \
	fi
endef

define help_heading
	@$(call print_line_inline,$(COLOR_TITLE),$(1))
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
		$(call print_line_inline,$(COLOR_ERROR),Docker Compose be missin'.); \
		$(call print_detail_inline,$(COLOR_MUTED),Install docker compose or docker-compose. 🧭); \
		exit 1; \
	}

#
# $(CHECK_ENV): Ensure the project environment file exists.
#
$(CHECK_ENV):
	@if [ ! -f "$(ENV_FILE)" ]; then \
		$(call print_line_inline,$(COLOR_ERROR),No $(ENV_FILE) found. The ship needs a chart before it sails. 🗺️); \
		$(call print_detail_inline,$(COLOR_MUTED),Run: make $(SHIP)); \
		exit 1; \
	fi

#
# $(CHECK_RENDERED): Ensure the deployable Compose file exists.
#
$(CHECK_RENDERED):
	@if [ ! -f "$(COMPOSE_FILE)" ]; then \
		$(call print_line_inline,$(COLOR_ERROR),No $(COMPOSE_FILE) found. The fleet needs one final chart. 🗺️); \
		$(call print_detail_inline,$(COLOR_MUTED),Run: make $(SHIP)); \
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
	$(call announce,Droppin' anchor for the Plundarr fleet. ⚓)
	$(PLUNDARR_COMPOSE) down $(COMPOSE_DOWN_OPTIONS)

#
# $(RESET_CONFIG): Restores checked-in example config files after live tests.
#
$(RESET_CONFIG):
	$(call announce,Restorin' example maps for safe check-in. 🧭)
	mkdir -p $$(dirname $(PRIVATEERR_GENERATED_WG_CONFIG))
	cp $(PRIVATEERR_EXAMPLE_WG_CONFIG) $(PRIVATEERR_GENERATED_WG_CONFIG)
	cp $(PRIVATEERR_EXAMPLE_METADATA) $(PRIVATEERR_GENERATED_METADATA)

#
# $(BACKUP_CONFIG): Archives the complete config directory with a collision-safe
#                   timestamped filename.
#
$(BACKUP_CONFIG):
	@if [ ! -d "$(CONFIG_PATH)" ]; then \
		$(call print_line_inline,$(COLOR_ERROR),No $(CONFIG_PATH) directory found to archive.); \
		exit 1; \
	fi
	@mkdir -p "$(CONFIG_BACKUP_PATH)"
	@timestamp=$$(date +%Y%m%d-%H%M%S); \
	archive="$(CONFIG_BACKUP_PATH)/$(PRESET)-config-$${timestamp}.tar.gz"; \
	suffix=0; \
	while [ -e "$$archive" ]; do \
		suffix=$$((suffix + 1)); \
		archive="$(CONFIG_BACKUP_PATH)/$(PRESET)-config-$${timestamp}-$${suffix}.tar.gz"; \
	done; \
	tar -czf "$$archive" "$(CONFIG_PATH)"; \
	$(call print_line_inline,$(COLOR_SUCCESS),Config cargo archived at $$archive. 📦)

#
# $(CLEAN_CONFIG): Deletes the complete generated config directory. This target
#                  is intentionally explicit because application state is lost.
#
$(CLEAN_CONFIG):
	$(call announce_warning,Removing the complete Plundarr config hold. ☠️)
	rm -rf "$(CONFIG_PATH)"
	$(call announce_detail,Run make $(SHIP) to regenerate selected service folders and seed files. 🗺️)

#
# $(CLEAN_ARTIFACTS): Removes only disposable developer artifacts. It never
#                     reads or deletes dist/, generated configuration,
#                     environment files, Docker resources, or backups.
#
$(CLEAN_ARTIFACTS):
	$(call announce,Scrubbin' disposable developer artifacts only. 🧽)
	rm -rf $(DEVELOPER_ARTIFACTS)
	find . -path './.git' -prune -o -path './dist' -prune -o \
		-type d -name '__pycache__' -prune -exec rm -rf {} +
	find . -path './.git' -prune -o -path './dist' -prune -o \
		-type f \( -name '*.pyc' -o -name '*.pyo' -o -name '.DS_Store' \) -delete
	$(call announce_detail,Deployment charts$(COMMA) .env files$(COMMA) config$(COMMA) backups$(COMMA) containers$(COMMA) volumes$(COMMA) and images remain untouched. ⚓)

#
# $(TEST_VPN): Validates a running stack's Privateerr and Gluetun VPN runtime state.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(CHECK_RENDERED) - Ensure the rendered Compose file exists.
#
$(TEST_VPN): $(BUILD_DEPENDS) $(CHECK_ENV) $(CHECK_RENDERED)
	$(call announce,Inspectin' the VPN tunnel and port-forwarding loot. 🔎)
	PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
	PLUNDARR_ENV_FILE=$(COMPOSE_ENV_FILE) \
	PLUNDARR_CONFIG_PATH=$(CONFIG_PATH)/gluetun/wireguard \
	PLUNDARR_GLUETUN_PATH=$(CONFIG_PATH)/gluetun \
	PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
	PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
	PLUNDARR_DOWNLOAD_SERVICES="$(E2E_DOWNLOAD_SERVICES)" \
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
	$(call announce,Launching Privateerr$(COMMA) Gluetun$(COMMA) and selected download mates for one clean test voyage. 🌊)
	@status=0; \
	$(PLUNDARR_COMPOSE) \
		up $(COMPOSE_E2E_OPTIONS) $(E2E_SERVICES) || status=$$?; \
	if [ "$$status" -eq 0 ]; then \
		PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
		PLUNDARR_ENV_FILE=$(COMPOSE_ENV_FILE) \
		PLUNDARR_CONFIG_PATH=$(CONFIG_PATH)/gluetun/wireguard \
		PLUNDARR_GLUETUN_PATH=$(CONFIG_PATH)/gluetun \
		PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
		PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
		PLUNDARR_DOWNLOAD_SERVICES="$(E2E_DOWNLOAD_SERVICES)" \
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
	$(call announce,Launching the whole Plundarr fleet for a full-stack test voyage. 🏴‍☠️)
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
		PLUNDARR_CONFIG_PATH=$(CONFIG_PATH)/gluetun/wireguard \
		PLUNDARR_GLUETUN_PATH=$(CONFIG_PATH)/gluetun \
		PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
		PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
		PLUNDARR_DOWNLOAD_SERVICES="$(E2E_DOWNLOAD_SERVICES)" \
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
	$(call announce_warning,Firin' the clean broadside. Repo-safe files stay aboard. 💣)
	$(PLUNDARR_COMPOSE) down $(COMPOSE_CLEAN_OPTIONS) --rmi all

	$(call announce,Scrubbin' generated logs and Gluetun state. 🧽)
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
	$(call announce,Raisin' the whole Plundarr fleet. 🏴‍☠️)
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
		$(call print_line_inline,$(COLOR_SUCCESS),⚓ Found Maraudarr aboard locally: $(MARAUDARR_IMAGE)); \
	else \
		$(call print_line_inline,$(COLOR_INFO),🌊 No local Maraudarr image found. Checking GHCR...); \
		if docker pull "$(MARAUDARR_IMAGE)" >/dev/null 2>&1; then \
			$(call print_line_inline,$(COLOR_SUCCESS),✅ Published Maraudarr image is ready.); \
		else \
			$(call print_line_inline,$(COLOR_WARNING),🛠️ Published image unavailable. Building from this checkout...); \
			$(MARAUDARR_BUILD) || { \
				$(call print_line_inline,$(COLOR_ERROR),☠️ Maraudarr could not be pulled or built.); \
				exit 1; \
			}; \
		fi; \
	fi
	@docker image inspect "$(MARAUDARR_IMAGE)" >/dev/null 2>&1 || { \
		$(call print_line_inline,$(COLOR_ERROR),☠️ Maraudarr image is still missing: $(MARAUDARR_IMAGE)); \
		exit 1; \
	}

#
# $(PULL_MARAUDARR): Pulls the latest published Maraudarr image from GHCR.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#
$(PULL_MARAUDARR): $(BUILD_DEPENDS)
	$(call announce,🌊 Pulling the latest published Maraudarr image...)
	docker pull "$(MARAUDARR_IMAGE)"

#
# $(SHIP): Generates the comment-rich Compose and environment files.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare a local Maraudarr image.
#
$(SHIP): $(ENSURE_MARAUDARR_IMAGE)
	$(call announce,🧭 Maraudarr is charting the $(PRESET) deployment...)
	@$(MARAUDARR_RUN) build \
		--preset "$(PRESET)" \
		--remove "$(REMOVE_SERVICES)" \
		--add "$(ADD_SERVICES)" \
		--output-root "$(MARAUDARR_OUTPUT_ROOT)"

#
# $(CONFIGURE): Opens Maraudarr's interactive preset and service configurator.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare a local Maraudarr image.
#
$(CONFIGURE): $(ENSURE_MARAUDARR_IMAGE)
	$(call announce,🧭 Openin' Maraudarr's interactive voyage planner...)
	@$(MARAUDARR_RUN_INTERACTIVE) configure --output-root "$(MARAUDARR_OUTPUT_ROOT)"

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
# $(SMOKE_MARAUDARR): Runs one hardened image-generation and Compose-validation
#                     voyage in a disposable output directory.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare the exact image requested by the caller.
#
$(SMOKE_MARAUDARR): $(ENSURE_MARAUDARR_IMAGE)
	$(call announce,Smoke-testin' Maraudarr in a sealed temporary barrel. 🛢️)
	@set -eu; \
	smoke_output=$$(mktemp -d); \
	trap 'rm -rf "$$smoke_output"' 0 1 2 15; \
	docker run \
		$(MARAUDARR_BASE_RUN_OPTIONS) \
		--volume "$$smoke_output:$(MARAUDARR_OUTPUT):rw" \
		"$(MARAUDARR_IMAGE)" \
		--plain build \
		--preset "$(MARAUDARR_SMOKE_PRESET)" \
		--remove "$(MARAUDARR_SMOKE_REMOVE)" \
		--add "$(MARAUDARR_SMOKE_ADD)" \
		--output-root "$(MARAUDARR_OUTPUT_ROOT)"; \
	smoke_deployment="$$smoke_output/$(DEPLOYMENT_ROOT)/$(MARAUDARR_SMOKE_PRESET)"; \
	test -s "$$smoke_deployment/docker-compose.yml"; \
	test -s "$$smoke_deployment/.env"; \
	test -s "$$smoke_deployment/$(MARAUDARR_SMOKE_FILE)"; \
	$(DOCKER_COMPOSE) \
		--env-file "$$smoke_deployment/.env" \
		-f "$$smoke_deployment/docker-compose.yml" \
		config \
		--quiet
	$(call announce_success,Maraudarr's disposable smoke voyage came back clean. ✅)

#
# $(TEST_MARAUDARR_UNIT): Runs Maraudarr's Python unit tests.
#
$(TEST_MARAUDARR_UNIT):
	PYTHONDONTWRITEBYTECODE=1 \
	PYTHONPATH=docker/src \
	MARAUDARR_CATALOG_ROOT=docker \
		$(PYTHON_BIN) -m unittest discover -s docker/tests -v

#
# $(TEST_WORKFLOW_HELPERS): Tests workflow payload and registry helpers locally.
#
$(TEST_WORKFLOW_HELPERS):
	$(WORKFLOW_HELPERS_TEST_CMD)

#
# $(TEST_MARAUDARR): Runs unit tests, workflow helpers, and the Compose matrix.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure Docker and Docker Compose are installed.
#   $(TEST_MARAUDARR_UNIT) - Run Maraudarr's Python unit tests.
#   $(TEST_WORKFLOW_HELPERS) - Test workflow helpers without external writes.
#
$(TEST_MARAUDARR): $(BUILD_DEPENDS) $(TEST_MARAUDARR_UNIT) $(TEST_WORKFLOW_HELPERS)
	$(MARAUDARR_IMAGE_TEST_CMD)
	MARAUDARR_TEST_OUTPUT="$(MARAUDARR_TEST_OUTPUT)" \
	PYTHON_BIN="$(PYTHON_BIN)" \
		test/test-maraudarr-matrix.sh

#
# $(DOCS_VENV)/bin/python: Creates an isolated Python environment for developer
#                           documentation tooling.
#
$(DOCS_VENV)/bin/python:
	$(call announce,📚 Creating the isolated developer documentation toolchain...)
	@$(PYTHON_BIN) -m venv "$(DOCS_VENV)" || { \
		$(call print_line_inline,$(COLOR_ERROR),Python venv support is required to build documentation.); \
		$(call print_detail_inline,$(COLOR_MUTED),Install Python with venv support, then run make $(DOCS).); \
		exit 1; \
	}

#
# $(DOCS_VENV)/.requirements-installed: Installs the pinned developer
#                                         documentation toolchain when its
#                                         requirements change.
#
$(DOCS_VENV)/.requirements-installed: $(DOCS_REQUIREMENTS) | $(DOCS_VENV)/bin/python
	$(call announce,📦 Installing pinned developer documentation tools...)
	@$(DOCS_PYTHON) -m pip install --disable-pip-version-check --requirement "$(DOCS_REQUIREMENTS)"
	@touch "$(DOCS_VENV)/.requirements-installed"

#
# $(DOCS_DEPENDENCIES): Ensures the pinned documentation toolchain is ready.
#
$(DOCS_DEPENDENCIES): $(DOCS_VENV)/.requirements-installed

#
# $(DOCS): Builds the strict Plundarr developer documentation site.
#
# Dependencies:
#   $(DOCS_DEPENDENCIES) - Prepare the isolated MkDocs toolchain.
#
$(DOCS): $(DOCS_DEPENDENCIES)
	$(call announce,📚 Building the strict developer documentation site...)
	$(DOCS_MKDOCS) build --strict --site-dir "$(DOCS_SITE_PATH)"

#
# $(DOCS_SERVE): Starts the local developer documentation preview server.
#
# Dependencies:
#   $(DOCS_DEPENDENCIES) - Prepare the isolated MkDocs toolchain.
#
$(DOCS_SERVE): $(DOCS_DEPENDENCIES)
	$(call announce,📚 Serving developer documentation at http://$(DOCS_SERVE_ADDRESS)...)
	$(DOCS_MKDOCS) serve --dev-addr "$(DOCS_SERVE_ADDRESS)"

#
# $(PRESETS): Lists presets and their exact default services.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare a local Maraudarr image.
#
$(PRESETS): $(ENSURE_MARAUDARR_IMAGE)
	$(call announce,🗺️ Maraudarr preset voyages)
	@if [ -t 1 ] && [ -z "$$NO_COLOR" ]; then \
		$(MARAUDARR_RUN_STYLED) presets; \
	else \
		$(MARAUDARR_RUN) --plain presets; \
	fi

#
# $(AVAILABLE_SERVICES): Lists every selectable Plundarr service.
#
# Dependencies:
#   $(ENSURE_MARAUDARR_IMAGE) - Prepare a local Maraudarr image.
#
$(AVAILABLE_SERVICES): $(ENSURE_MARAUDARR_IMAGE)
	$(call announce,🧰 Maraudarr service cargo)
	@if [ -t 1 ] && [ -z "$$NO_COLOR" ]; then \
		$(MARAUDARR_RUN_STYLED) services; \
	else \
		$(MARAUDARR_RUN) --plain services; \
	fi

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
	$(call announce,Readin' logs for the fleet. 🔎)
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
	@project_name="$${COMPOSE_PROJECT_NAME:-}"; \
	if [ -z "$$project_name" ]; then \
		project_name=$$(awk -F '=' '\
			/^COMPOSE_PROJECT_NAME=/ { \
				value=$$2; \
				sub(/^"\$\${COMPOSE_PROJECT_NAME:-/, "", value); \
				sub(/}"$$/, "", value); \
				sub(/^"/, "", value); \
				print value; \
				exit; \
			}' "$(COMPOSE_ENV_FILE)"); \
	fi; \
	docker ps \
		--filter "label=com.docker.compose.project=$$project_name" \
		--format 'table {{.Names}}\t{{.Label "com.docker.compose.service"}}\t{{.Status}}\t{{.Ports}}'

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
	$(call announce,Opening selected Compose services in the default browser. 🌐)
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
	$(call announce_title,🏴‍☠️ Plundarr command chart)
	$(call announce_detail,Usage: make <target> [PRESET=<preset>] [ADD_SERVICES=id$(COMMA)...] [REMOVE_SERVICES=id$(COMMA)...])
	$(call help_heading,🧭 Generate and discover)
	$(call help_line,$(SHIP),Generate a preset deployment (default: plundarr).)
	$(call help_line,$(CONFIGURE),Open the interactive preset and service selector.)
	$(call help_line,$(PRESETS),List presets and their default services.)
	$(call help_line,$(AVAILABLE_SERVICES),List every selectable service.)
	$(call help_heading,🚀 Run the selected deployment)
	$(call help_line,$(UP),Start or recreate the selected stack.)
	$(call help_line,$(DOWN),Stop and remove selected-stack containers and networks.)
	$(call help_line,$(PS),Show a compact container status table.)
	$(call help_line,$(LOGS),Follow selected-stack logs.)
	$(call help_line,$(OPEN),Open selected-stack web interfaces on macOS.)
	$(call help_heading,🔎 Inspect generated output)
	$(call help_line,$(CONFIG),Print Docker Compose's rendered configuration.)
	$(call help_line,$(COMPOSE_SERVICES),List rendered Compose services.)
	$(call help_line,$(ENV),Print rendered environment values.)
	$(call help_line,$(PRINT_CONFIG),Print raw Compose configuration without comments.)
	$(call help_line,$(PRINT_ENV),Print raw environment settings without comments.)
	$(call help_heading,🧪 Test and build)
	$(call help_line,$(TEST_MARAUDARR_UNIT),Run Maraudarr Python unit tests.)
	$(call help_line,$(TEST_MARAUDARR),Run all generator and workflow-helper tests.)
	$(call help_line,$(TEST_WORKFLOW_HELPERS),Test Discord and registry workflow helpers.)
	$(call help_line,$(TEST_VPN),Check a running VPN tunnel.)
	$(call help_line,$(TEST_E2E),Run the focused VPN end-to-end test.)
	$(call help_line,$(TEST_STACK),Run the complete stack test.)
	$(call help_line,$(BUILD_MARAUDARR),Build Maraudarr from this checkout.)
	$(call help_line,$(BUILD_MULTIARCH),Check every published image architecture.)
	$(call help_line,$(SMOKE_MARAUDARR),Smoke-test one hardened Maraudarr image.)
	$(call help_line,$(DOCS),Build the strict developer documentation site.)
	$(call help_line,$(DOCS_SERVE),Preview developer documentation locally.)
	$(call help_line,$(DOCS_DEPENDENCIES),Install or refresh pinned documentation tools.)
	$(call help_heading,🧹 Maintenance)
	$(call help_line,$(PULL_MARAUDARR),Pull the latest published Maraudarr image.)
	$(call help_line,$(BACKUP_CONFIG),Archive the selected preset config safely.)
	$(call help_line,$(CLEAN_ARTIFACTS),Remove only disposable developer artifacts.)
	$(call help_line,$(CLEAN),Stop the stack and restore example test config.)
	$(call help_line,$(RESET_CONFIG),Restore example VPN config files for tests.)
	$(call help_line,$(CLEAN_CONFIG),‼️DANGER‼️ delete the selected preset config tree.)
	$(call help_line,$(NUKE),‼️DANGER‼️ remove selected-stack containers volumes and images.)
	$(call announce_warning,⚠️  Destructive targets never run automatically. Back up config before using them.)

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
