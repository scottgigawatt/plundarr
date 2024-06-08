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
LOGS=logs
OPEN=open
HELP=help
START=start
RUN=run

#
# Docker Compose options
#
COMPOSE_GLUETUN_SERVICE   ?= gluetun
COMPOSE_DUPLICATI_SERVICE ?= duplicati
COMPOSE_TIMEOUT           ?= 30
COMPOSE_STOP_OPTIONS      ?= --timeout $(COMPOSE_TIMEOUT)
COMPOSE_DOWN_OPTIONS      ?= --timeout $(COMPOSE_TIMEOUT)
COMPOSE_CLEAN_OPTIONS     ?= --timeout $(COMPOSE_TIMEOUT) --rmi all --volumes
COMPOSE_BUILD_OPTIONS     ?= --pull --no-cache
COMPOSE_UP_OPTIONS        ?= --build --force-recreate --pull always --detach
COMPOSE_LOGS_OPTIONS      ?= --follow

#
# Build dependencies
#
DEPENDENCIES=docker docker-compose

#
# Targets that are not files (i.e. never up-to-date); these will run every
# time the target is called or required.
#
.PHONY: $(ALL) $(DOWN) $(CLEAN) $(BUILD_DEPENDS) $(BUILD) $(UP) $(LOGS) $(OPEN) $(HELP) $(START) $(RUN)

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

#
# $(BUILD): Builds the service stack.
#
$(BUILD): $(BUILD_DEPENDS)
	@echo "\nBuilding compose services"
	docker-compose build $(COMPOSE_BUILD_OPTIONS)

#
# $(UP): Builds, (re)creates, and starts containers for services.
#
$(UP): $(BUILD_DEPENDS)
	@echo "\nBuilding and starting compose services"
	docker-compose up $(COMPOSE_UP_OPTIONS)

#
# $(START): Starts existing containers for a service.
#
$(START): $(BUILD_DEPENDS)
	docker-compose start

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
		"http://localhost:`docker-compose port $(COMPOSE_DUPLICATI_SERVICE) 8200 | cut -d: -f2`"

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
	@echo "  $(BUILD)           - Builds the service stack."
	@echo "  $(UP)              - Builds, (re)creates, and starts containers for services."
	@echo "  $(START)           - Starts existing containers for a service."
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
