#
# Makefile for managing Docker Compose services.
# This Makefile includes targets for building, starting, stopping, and cleaning Docker services.
# It ensures that necessary dependencies are installed and Docker images are built with specified options.
#

#
# Makefile target names
#
ALL=all
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
COMPOSE_QBITTORRENT_SERVICE ?= qbittorrent
COMPOSE_PROWLARR_SERVICE    ?= prowlarr
COMPOSE_RADARR_SERVICE      ?= radarr
COMPOSE_SONARR_SERVICE      ?= sonarr
COMPOSE_READARR_SERVICE     ?= readarr
COMPOSE_JACKETT_SERVICE     ?= jackett
COMPOSE_DOWN_TIMEOUT        ?= 30
COMPOSE_DOWN_OPTIONS        ?= --timeout $(COMPOSE_DOWN_TIMEOUT) --rmi all --volumes
COMPOSE_BUILD_OPTIONS       ?= --pull --no-cache
COMPOSE_UP_OPTIONS          ?= --build --force-recreate --pull always --detach
COMPOSE_LOGS_OPTIONS        ?= --follow

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
# $(DOWN): Stops containers and removes containers, networks, volumes, and images created by up.
#
$(DOWN): $(BUILD_DEPENDS)
	@echo "\nStopping compose services"
	docker-compose down $(COMPOSE_DOWN_OPTIONS)

#
# $(BUILD): Builds the service stack.
#
# Dependencies: $(BUILD_DEPENDS) - Ensure build dependencies are installed.
#
$(BUILD): $(BUILD_DEPENDS)
	@echo "\nBuilding compose services"
	docker-compose build $(COMPOSE_BUILD_OPTIONS)

#
# $(UP): Builds, (re)creates, and starts containers for services.
#
$(UP): $(BUILD_DEPENDS)
	@echo "\nStarting compose services"
	HOST_WIKI_PATH=${PWD} docker-compose up $(COMPOSE_UP_OPTIONS)

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
	open "http://localhost:`docker-compose port $(COMPOSE_QBITTORRENT_SERVICE) 8080 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_PROWLARR_SERVICE) 9696 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_RADARR_SERVICE) 7878 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_SONARR_SERVICE) 8989 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_READARR_SERVICE) 8787 | cut -d: -f2`" \
		"http://localhost:`docker-compose port $(COMPOSE_JACKETT_SERVICE) 9117 | cut -d: -f2`"

#
# $(HELP): Print help information.
#
$(HELP):
	@echo "Usage: make [TARGET]"
	@echo ""
	@echo "Targets:"
	@echo "  $(ALL)             - Builds and starts the service stack."
	@echo "  $(BUILD_DEPENDS)   - Ensures build dependencies are installed."
	@echo "  $(DOWN)            - Stops and removes containers, networks, volumes, and images."
	@echo "  $(CLEAN)           - Alias for $(DOWN)."
	@echo "  $(BUILD)           - Builds the service stack."
	@echo "  $(UP)              - Builds, (re)creates, and starts containers for services."
	@echo "  $(START)           - Alias for $(UP)."
	@echo "  $(LOGS)            - Shows logs for the service."
	@echo "  $(OPEN)            - Opens the service site in the default web browser."
	@echo "  $(RUN)             - Alias for $(UP), $(OPEN), $(LOGS)."
	@echo "  $(HELP)            - Displays this help message."

#
# Alias for down
#
$(CLEAN): $(DOWN)

#
# Alias for up
#
$(START): $(UP)

#
# $(RUN): Alias for up, open, logs
#
$(RUN): $(UP)
	@$(MAKE) $(OPEN)
	@$(MAKE) $(LOGS)
