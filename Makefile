#
# Makefile for managing Docker Compose services.
# This Makefile includes targets for building, starting, stopping, and cleaning Docker services.
# It ensures that necessary dependencies are installed and Docker images are built with specified options.
#

#
# Makefile target names
#
ALL=all
STOP=stop
DOWN=down
CLEAN=clean
BUILD_DEPENDS=build-depends
BUILD=build
UP=up
BUILD_UP=build-up
START=start
TEST_VPN=test-vpn
CONFIG=config
ENV=env
PRINT_CONFIG=print-config
PRINT_ENV=print-env
LOGS=logs
OPEN=open
HELP=help
RUN=run

#
# Docker Compose options
#
COMPOSE_FILE               ?= docker-compose.yml
COMPOSE_BUILD_FILE         ?= docker-compose.build.yml
COMPOSE_ENV_FILE           ?= example.env
COMPOSE_PRIVATEERR_SERVICE ?= privateerr
COMPOSE_GLUETUN_SERVICE    ?= gluetun
COMPOSE_DUPLICATI_SERVICE  ?= duplicati
COMPOSE_OVERSEERR_SERVICE  ?= overseerr
COMPOSE_HOMEPAGE_SERVICE   ?= homepage
COMPOSE_TIMEOUT            ?= 30
COMPOSE_STOP_OPTIONS       ?= --timeout $(COMPOSE_TIMEOUT)
COMPOSE_DOWN_OPTIONS       ?= --timeout $(COMPOSE_TIMEOUT)
COMPOSE_CLEAN_OPTIONS      ?= --timeout $(COMPOSE_TIMEOUT) --rmi all --volumes
COMPOSE_BUILD_OPTIONS      ?= --pull --no-cache
COMPOSE_UP_OPTIONS         ?= --force-recreate --pull always --detach
COMPOSE_LOGS_OPTIONS       ?= --follow

#
# Testing commands
#
DOCKER_VPN_TEST_CMD ?= sh scripts/test_vpn.sh

#
# Build dependencies
#
DEPENDENCIES=docker docker-compose

#
# Targets that are not files (i.e. never up-to-date); these will run every
# time the target is called or required.
#
.PHONY: $(ALL) $(DOWN) $(CLEAN) $(BUILD_DEPENDS) $(BUILD) $(UP) $(BUILD_UP) $(START) $(TEST_VPN) \
		$(LOGS) $(OPEN) $(HELP) $(RUN) $(CONFIG) $(ENV) $(PRINT_CONFIG) $(PRINT_ENV)

#
# $(ALL): Default makefile target. Builds and starts the service stack.
#
$(ALL): $(UP)

#
# $(BUILD_DEPENDS): Ensure build dependencies are installed.
#
$(BUILD_DEPENDS):
	$(foreach exe,$(DEPENDENCIES), \
		$(if $(shell which $(exe) 2> /dev/null),,$(error "No $(exe) in PATH")))

#
# $(STOP): Stops running containers without removing them.
#
$(STOP): $(BUILD_DEPENDS)
	@echo "\nStopping compose service containers"
	docker-compose stop $(COMPOSE_STOP_OPTIONS)

#
# $(DOWN): Stops and removes containers.
#
$(DOWN): $(BUILD_DEPENDS)
	@echo "\nStopping compose services and removing containers"
	docker-compose down $(COMPOSE_DOWN_OPTIONS)

#
# $(CLEAN): Stops containers and removes containers, networks, volumes, and images created by up.
#
$(CLEAN): $(BUILD_DEPENDS)
	@echo "\nStopping compose services and removing containers, networks, volumes, and images"
	docker-compose down $(COMPOSE_CLEAN_OPTIONS)

	@echo "\nRemoving images based on test image $(DOCKER_VPN_TEST_IMAGE)"
	docker images -q "$(DOCKER_VPN_TEST_IMAGE)" | xargs -r docker rmi -f || true

#
# $(BUILD): Builds a local image of the privateerr service for use when it cannot be pulled from GHCR.
#
$(BUILD): $(BUILD_DEPENDS)
	@echo "\nBuilding local image for compose service: $(COMPOSE_PRIVATEERR_SERVICE)"
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_BUILD_FILE) build $(COMPOSE_BUILD_OPTIONS) $(COMPOSE_PRIVATEERR_SERVICE)

#
# $(UP): (Re)creates and starts containers for services.
#
$(UP): $(BUILD_DEPENDS)
	@echo "\nStarting compose services"
	docker-compose -f $(COMPOSE_FILE) up $(COMPOSE_UP_OPTIONS)

#
# $(BUILD_UP): Alias for build, up.
#
$(BUILD_UP): $(BUILD)
	@$(MAKE) $(UP)

#
# $(START): Starts existing containers for a service.
#
$(START): $(BUILD_DEPENDS)
	docker-compose start

#
# $(TEST_VPN): Obtains the VPN IP address and ensure the connection is working.
#
$(TEST_VPN):
	$(DOCKER_VPN_TEST_CMD)

#
# $(CONFIG): Renders the actual data model to be applied on the Docker Engine.
# Resolves variables in the Compose file and expands short-notation into the canonical format.
#
$(CONFIG):
	docker-compose config

#
# $(ENV): Prints the evaluated docker compose default env configuration.
#
$(ENV):
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
$(PRINT_ENV):
	@awk '{ \
		sub(/#.*/, ""); \
		sub(/[[:space:]]+$$/, ""); \
		if (NF) print \
	}' $(COMPOSE_ENV_FILE)

#
# $(LOGS): View output from containers.
#
$(LOGS):
	@echo "\nGetting logs for services"
	docker-compose logs $(COMPOSE_LOGS_OPTIONS)

#
# $(OPEN): Opens the compose services in the default web browser.
#
$(OPEN):
	@echo "\nOpening compose services in default browser"
	open "http://localhost:`docker-compose port $(COMPOSE_GLUETUN_SERVICE) 8080 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_GLUETUN_SERVICE) 9696 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_GLUETUN_SERVICE) 7878 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_GLUETUN_SERVICE) 8989 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_GLUETUN_SERVICE) 6767 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_GLUETUN_SERVICE) 8787 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_DUPLICATI_SERVICE) 8200 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_OVERSEERR_SERVICE) 5055 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_HOMEPAGE_SERVICE) 3000 | cut -d: -f2`"

#
# $(HELP): Print help information.
#
$(HELP):
	@echo "Usage: make [TARGET]"
	@echo ""
	@echo "Targets:"
	@echo "  $(ALL)             - Builds and starts the service stack."
	@echo "  $(BUILD_DEPENDS)   - Ensures build dependencies are installed."
	@echo "  $(STOP)            - Stops running containers without removing them."
	@echo "  $(DOWN)            - Stops and removes containers."
	@echo "  $(CLEAN)           - Stops and removes containers, networks, volumes, and images."
	@echo "  $(BUILD)           - Builds a local image of the privateerr service for use when it cannot be pulled from GHCR."
	@echo "  $(UP)              - (Re)creates and starts containers for services."
	@echo "  $(BUILD_UP)        - Alias for $(BUILD), $(UP)."
	@echo "  $(START)           - Starts existing containers for a service."
	@echo "  $(TEST_VPN)        - Obtain the VPN IP address and ensure the connection is working."
	@echo "  $(CONFIG)          - Renders the actual data model to be applied on the Docker Engine."
	@echo "  $(ENV)             - Prints the evaluated docker compose default env configuration."
	@echo "  $(PRINT_CONFIG)    - Print the raw uncommented docker compose yaml configuration."
	@echo "  $(PRINT_ENV)       - Print the raw uncommented docker compose env configuration."
	@echo "  $(LOGS)            - Shows logs for the service."
	@echo "  $(OPEN)            - Opens the service site in the default web browser."
	@echo "  $(RUN)             - Alias for $(UP), $(OPEN), $(LOGS)."
	@echo "  $(HELP)            - Displays this help message."

#
# $(RUN): Alias for up, open, logs
#
$(RUN): $(UP)
	@$(MAKE) $(OPEN)
	@$(MAKE) $(LOGS)
