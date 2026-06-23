#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# Makefile: Automation for managing Plundarr Docker Compose services, config
#           resets, VPN validation, logs, and local convenience commands.
#

#
# Makefile target names
#
ALL=all
DOWN=down
CLEAN=clean
NUKE=nuke
BUILD_DEPENDS=build-depends
CHECK_ENV=check-env
RESET_CONFIG=reset-config
TEST_VPN=test-vpn
TEST_E2E=test-e2e
TEST_STACK=test-stack
TEST_DOWN=test-down
TEST_LOGS=test-logs
UP=up
CONFIG=config
ENV=env
PRINT_CONFIG=print-config
PRINT_ENV=print-env
LOGS=logs
OPEN=open
HELP=help
RUN=run
START=start
STOP=stop

#
# Docker Compose service names
#
PRIVATEERR_SERVICE  ?= privateerr
GLUETUN_SERVICE     ?= gluetun
QBITTORRENT_SERVICE ?= qbittorrent
DUPLICATI_SERVICE   ?= duplicati
SEERR_SERVICE       ?= seerr
HOMEPAGE_SERVICE    ?= homepage

#
# Config reset paths
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
# Docker Compose options
#
COMPOSE_FILE          ?= docker-compose.yml
ENV_FILE              ?= .env
EXAMPLE_ENV_FILE      ?= example.env
COMPOSE_ENV_FILE      ?= $(ENV_FILE)
COMPOSE_DOWN_TIMEOUT  ?= 30
COMPOSE_DOWN_OPTIONS  ?= --timeout $(COMPOSE_DOWN_TIMEOUT) --remove-orphans
COMPOSE_CLEAN_OPTIONS ?= --timeout $(COMPOSE_DOWN_TIMEOUT) --volumes --remove-orphans
COMPOSE_UP_OPTIONS    ?= --force-recreate --pull always --detach --remove-orphans
COMPOSE_E2E_OPTIONS   ?= --force-recreate --pull always --detach --remove-orphans
COMPOSE_E2E_WAIT      ?= 300
COMPOSE_STACK_WAIT    ?= 600
COMPOSE_LOGS_OPTIONS  ?= --follow

#
# Testing commands
#
PLUNDARR_VPN_TEST_CMD   ?= test/plundarr-vpn-test.sh
PLUNDARR_STACK_WAIT_CMD ?= test/plundarr-stack-wait.sh

#
# Docker Compose command compatible with 'docker compose' (v2) and 'docker-compose' (v1).
#
DOCKER_COMPOSE := $(shell if docker compose version >/dev/null 2>&1; then echo "docker compose"; elif command -v docker-compose >/dev/null 2>&1; then echo "docker-compose"; else echo ""; fi)

ifeq ($(DOCKER_COMPOSE),)
    $(error "Neither 'docker compose' nor 'docker-compose' is available. Please install Docker Compose.")
endif

#
# Build dependencies
#
DEPENDENCIES=docker

#
# Targets that are not files (i.e. never up-to-date); these will run every
# time the target is called or required.
#
.PHONY: $(ALL) $(DOWN) $(CLEAN) $(NUKE) $(BUILD_DEPENDS) $(CHECK_ENV) $(RESET_CONFIG) $(TEST_VPN) $(TEST_E2E) $(TEST_STACK) $(TEST_DOWN) $(TEST_LOGS) $(UP) $(CONFIG) $(ENV) $(PRINT_CONFIG) $(PRINT_ENV) $(LOGS) $(OPEN) $(HELP) $(RUN) $(START) $(STOP)

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
	@$(DOCKER_COMPOSE) version >/dev/null 2>&1 || (echo "Docker Compose be missin'. Install docker compose or docker-compose. 🧭" && exit 1)

#
# $(CHECK_ENV): Ensure the project environment file exists.
#
$(CHECK_ENV):
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "\nNo $(ENV_FILE) found. The ship needs a chart before it sails. 🗺️"; \
		echo "Copy $(EXAMPLE_ENV_FILE) to $(ENV_FILE), then update yer voyage settings."; \
		echo "Run: cp $(EXAMPLE_ENV_FILE) $(ENV_FILE)"; \
		exit 1; \
	fi

#
# $(DOWN): Stops containers and removes containers and networks.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#
$(DOWN): $(BUILD_DEPENDS) $(CHECK_ENV)
	@echo "\nDroppin' anchor for the Plundarr fleet. ⚓"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down $(COMPOSE_DOWN_OPTIONS)

#
# $(RESET_CONFIG): Restores checked-in example config files after live tests.
#
$(RESET_CONFIG):
	@echo "\nRestorin' example maps for safe check-in. 🧭"
	cp $(PRIVATEERR_EXAMPLE_WG_CONFIG) $(PRIVATEERR_GENERATED_WG_CONFIG)
	cp $(PRIVATEERR_EXAMPLE_METADATA) $(PRIVATEERR_GENERATED_METADATA)

#
# $(TEST_VPN): Validates a running stack's Privateerr and Gluetun VPN runtime state.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#
$(TEST_VPN): $(BUILD_DEPENDS) $(CHECK_ENV)
	@echo "\nInspectin' the VPN tunnel and port-forwarding loot. 🔎"
	PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
	PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
	PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
	PLUNDARR_QBITTORRENT_SERVICE=$(QBITTORRENT_SERVICE) \
	$(PLUNDARR_VPN_TEST_CMD)

#
# $(TEST_E2E): Starts Privateerr, Gluetun, and qBittorrent, validates VPN state, then removes them.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(RESET_CONFIG) - Restore example config files.
#
$(TEST_E2E): $(BUILD_DEPENDS) $(CHECK_ENV) $(RESET_CONFIG)
	@echo "\nLaunching Privateerr, Gluetun, and qBittorrent for one clean test voyage. 🌊"
	@status=0; \
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up $(COMPOSE_E2E_OPTIONS) $(PRIVATEERR_SERVICE) $(GLUETUN_SERVICE) $(QBITTORRENT_SERVICE) || status=$$?; \
	if [ "$$status" -eq 0 ]; then \
		PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
		PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
		PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
		PLUNDARR_QBITTORRENT_SERVICE=$(QBITTORRENT_SERVICE) \
		PLUNDARR_WAIT_SECONDS=$(COMPOSE_E2E_WAIT) \
		$(PLUNDARR_VPN_TEST_CMD) || status=$$?; \
	fi; \
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down $(COMPOSE_DOWN_OPTIONS); \
	$(MAKE) --no-print-directory $(RESET_CONFIG); \
	exit "$$status"

#
# $(TEST_STACK): Starts every service, waits for health, validates VPN and qBittorrent state.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#   $(RESET_CONFIG) - Restore example config files.
#
$(TEST_STACK): $(BUILD_DEPENDS) $(CHECK_ENV) $(RESET_CONFIG)
	@echo "\nLaunching the whole Plundarr fleet for a full-stack test voyage. 🏴‍☠️"
	@status=0; \
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up $(COMPOSE_UP_OPTIONS) || status=$$?; \
	if [ "$$status" -eq 0 ]; then \
		PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
		PLUNDARR_STACK_WAIT_SECONDS=$(COMPOSE_STACK_WAIT) \
		$(PLUNDARR_STACK_WAIT_CMD) || status=$$?; \
	fi; \
	if [ "$$status" -eq 0 ]; then \
		PLUNDARR_COMPOSE_FILE=$(COMPOSE_FILE) \
		PLUNDARR_PRIVATEERR_SERVICE=$(PRIVATEERR_SERVICE) \
		PLUNDARR_GLUETUN_SERVICE=$(GLUETUN_SERVICE) \
		PLUNDARR_QBITTORRENT_SERVICE=$(QBITTORRENT_SERVICE) \
		PLUNDARR_WAIT_SECONDS=$(COMPOSE_STACK_WAIT) \
		$(PLUNDARR_VPN_TEST_CMD) || status=$$?; \
	fi; \
	if [ "$$status" -ne 0 ]; then \
		$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) ps; \
		$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) logs --tail=120; \
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
#
$(NUKE): $(BUILD_DEPENDS) $(CHECK_ENV)
	@echo "\nFirin' the clean broadside. Repo-safe files stay aboard. 💣"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) down $(COMPOSE_CLEAN_OPTIONS) --rmi all

	@echo "Scrubbin' generated logs and Gluetun state. 🧽"
	rm -rf $(PLUNDARR_GENERATED_PATHS)

	@$(MAKE) --no-print-directory $(RESET_CONFIG)

#
# $(UP): (Re)creates and starts every service in the stack.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#
$(UP): $(BUILD_DEPENDS) $(CHECK_ENV)
	@echo "\nRaisin' the whole Plundarr fleet. 🏴‍☠️"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) up $(COMPOSE_UP_OPTIONS)

#
# $(CONFIG): Renders the actual data model to be applied on the Docker Engine.
#
# Dependencies:
#   $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#   $(CHECK_ENV) - Ensure the environment file exists.
#
$(CONFIG): $(BUILD_DEPENDS) $(CHECK_ENV)
	$(DOCKER_COMPOSE) --env-file $(COMPOSE_ENV_FILE) -f $(COMPOSE_FILE) config

#
# $(ENV): Prints the evaluated docker compose default env configuration.
#
# Dependencies:
#   $(CHECK_ENV) - Ensure the environment file exists.
#
$(ENV): $(CHECK_ENV)
	@. ./$(COMPOSE_ENV_FILE) && \
	awk -F '=' '/^[^#]/ { \
		gsub(/^[[:space:]]+|[[:space:]]+$$/, ""); \
		value = ENVIRON[$$1]; \
		if (!value) { \
			split($$2, parts, /:-/); \
			if (length(parts) > 1) { \
				gsub(/[{}"]/,"", parts[2]); \
				value = parts[2]; \
			} \
		} \
		printf "%s=%s\n", $$1, value \
	}' $(COMPOSE_ENV_FILE)

#
# $(PRINT_CONFIG): Prints the raw uncommented docker compose yaml configuration.
#
$(PRINT_CONFIG):
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
#
$(LOGS): $(BUILD_DEPENDS) $(CHECK_ENV)
	@echo "\nReadin' logs for the fleet. 🔎"
	$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) logs $(COMPOSE_LOGS_OPTIONS)

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
#
$(OPEN): $(BUILD_DEPENDS) $(CHECK_ENV)
	@echo "\nOpening compose services in default browser"
	open "http://localhost:`$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) port $(GLUETUN_SERVICE) 8080 | cut -d: -f2`" \
		"http://localhost:`$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) port $(GLUETUN_SERVICE) 9696 | cut -d: -f2`" \
		"http://localhost:`$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) port $(GLUETUN_SERVICE) 7878 | cut -d: -f2`" \
		"http://localhost:`$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) port $(GLUETUN_SERVICE) 8989 | cut -d: -f2`" \
		"http://localhost:`$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) port $(GLUETUN_SERVICE) 6767 | cut -d: -f2`" \
		"http://localhost:`$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) port $(DUPLICATI_SERVICE) 8200 | cut -d: -f2`" \
		"http://localhost:`$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) port $(SEERR_SERVICE) 5055 | cut -d: -f2`" \
		"http://localhost:`$(DOCKER_COMPOSE) -f $(COMPOSE_FILE) port $(HOMEPAGE_SERVICE) 3000 | cut -d: -f2`"

#
# $(HELP): Print help information.
#
$(HELP):
	@echo "Usage: make [TARGET]"
	@echo ""
	@echo "Targets:"
	@echo "  $(ALL)             Starts the service stack."
	@echo "  $(BUILD_DEPENDS)   Ensures build dependencies are installed."
	@echo "  $(CHECK_ENV)       Ensures $(ENV_FILE) exists before Compose-backed targets run."
	@echo "  $(DOWN)            Stops and removes the service stack."
	@echo "  $(CLEAN)           Stops the stack and restores example config files."
	@echo "  $(NUKE)            Removes containers, images, generated files, and restores example config."
	@echo "  $(RESET_CONFIG)    Restores example wg0.conf and privateerr.env files."
	@echo "  $(TEST_VPN)        Validates running Privateerr and Gluetun VPN runtime state."
	@echo "  $(TEST_E2E)        Starts Privateerr, Gluetun, and qBittorrent, validates VPN state, then removes them."
	@echo "  $(TEST_STACK)      Starts every service, waits for health, then validates VPN and qBittorrent state."
	@echo "  $(TEST_DOWN)       Stops the stack and restores example config files."
	@echo "  $(TEST_LOGS)       Shows logs for the service stack."
	@echo "  $(UP)              (Re)creates and starts every service."
	@echo "  $(CONFIG)          Renders the Docker Compose model."
	@echo "  $(ENV)             Prints the evaluated docker compose default env configuration."
	@echo "  $(PRINT_CONFIG)    Prints the raw uncommented docker compose yaml configuration."
	@echo "  $(PRINT_ENV)       Prints the raw uncommented docker compose env configuration."
	@echo "  $(LOGS)            Shows logs for the service stack."
	@echo "  $(OPEN)            Opens the service sites in the default web browser."
	@echo "  $(RUN)             Alias for $(UP), $(OPEN), $(LOGS)."
	@echo "  $(START)           Alias for $(UP)."
	@echo "  $(STOP)            Alias for $(DOWN)."
	@echo "  $(HELP)            Displays this help message."

#
# Alias for test-down.
#
# Dependencies:
#   $(TEST_DOWN) - Stop the stack and restore example config files.
#
$(CLEAN): $(TEST_DOWN)

#
# Alias for up.
#
# Dependencies:
#   $(UP) - Start the service stack.
#
$(START): $(UP)

#
# Alias for down.
#
# Dependencies:
#   $(DOWN) - Stop and remove the stack.
#
$(STOP): $(DOWN)

#
# Alias for up, open, logs.
#
# Dependencies:
#   $(UP) - Start the service stack.
#
$(RUN): $(UP)
	@$(MAKE) --no-print-directory $(OPEN)
	@$(MAKE) --no-print-directory $(LOGS)
