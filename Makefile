# Makefile
ROOT_PASSWD ?= link
ARCH ?= $(shell uname -m)
SUITE ?= aio

RDP_PORT ?= 3389
VNC_PORT ?= 5900
SSH_PORT ?= 2222

# Set the target architecture based on the detected architecture
ifeq ($(ARCH),aarch64)
    TARGET_ARCH := mac
else ifeq ($(ARCH),arm64)
    TARGET_ARCH := mac
else ifeq ($(ARCH),x86_64)
    TARGET_ARCH := amd64
else
    $(error Unsupported architecture: $(ARCH))
endif

DOCKERFILE := Dockerfile-$(SUITE)
IMAGE_NAME := docker.linkclouds.top/debian10-vlsi-$(SUITE)-suite:$(TARGET_ARCH)

# Path to the build file
BUILD_FILE := version

# Read the version and build number from the file
VERSION := $(shell head -n 1 $(BUILD_FILE))
BUILD_NUMBER := $(shell tail -n 1 $(BUILD_FILE))

# Increment the build number
NEW_BUILD_NUMBER := $(shell expr $(BUILD_NUMBER) + 1)

# Update the build file with the new build number
update-build-file:
	echo "$(VERSION)\n$(NEW_BUILD_NUMBER)" > $(BUILD_FILE)

# Build the Docker image with the build number as an argument
build: update-build-file
	docker build -f $(DOCKERFILE) --build-arg="TARGETARCH=$(TARGET_ARCH)" --build-arg="VERSION=$(VERSION)" --build-arg="BUILD_NUMBER=$(NEW_BUILD_NUMBER)" -t $(IMAGE_NAME) .

rebuild:
	docker build -f $(DOCKERFILE) --build-arg="TARGETARCH=$(TARGET_ARCH)" --build-arg="VERSION=$(VERSION)" --build-arg="BUILD_NUMBER=$(NEW_BUILD_NUMBER)" -t $(IMAGE_NAME) .

push:
	docker push $(IMAGE_NAME)

stop-container:
	docker stop $(SUITE)-suite || true && docker rm $(SUITE)-suite || true

stop-production:
	docker stop vlsi-production || true && docker rm vlsi-production || true

# Run a container from the newly built image
run-production: stop-production
	docker run -it -d --hostname vlsi --privileged --shm-size=1G --name vlsi-production --mac-address 02:42:ac:11:00:02 -p 3999:3389 -v /home/link/Documents/VLSIServer/Data:/media/share -v /home/link/Documents/VLSIServer/Users:/home $(IMAGE_NAME) $(ROOT_PASSWD)

run: stop-container
	docker run -it -d --hostname link --privileged --name $(SUITE)-suite --mac-address 02:42:ac:11:00:02 -p $(RDP_PORT):3389 -v /Users/link/Documents/SharedVM:/media/share $(IMAGE_NAME) $(ROOT_PASSWD)
run-vnc: stop-container
	docker run -it -d --hostname link --name $(SUITE)-suite --mac-address 02:42:ac:11:00:02 -p $(VNC_PORT):5900 -p 5901:5901 -v /Users/link/Documents/SharedVM:/media/share $(IMAGE_NAME) $(ROOT_PASSWD) vnc
run-ssh: stop-container
	docker run -it -d --hostname link --name $(SUITE)-suite --mac-address 02:42:ac:11:00:02 -p $(SSH_PORT):22 -v /Users/link/Documents/SharedVM:/media/share $(IMAGE_NAME) $(ROOT_PASSWD) ssh

# Default target
all: build run

### BUILD/PUSH ALL
# Define the list of suites and architectures
SUITES = aio frontend backend
ARCHITECTURES = amd64 mac

##### BUILD ALL
# Define the targets for building Docker images
build-all: update-build-file $(foreach suite,$(SUITES),$(foreach arch,$(ARCHITECTURES),build-$(suite)-$(arch)))

# Define the individual build targets
define BUILD_TARGET
build-$(1)-$(2):
	@echo "Building docker.linkclouds.top/debian10-vlsi-$(1)-suite:$(2)..."
	@docker build -f Dockerfile-$(1) --build-arg="TARGETARCH=$(2)" --build-arg="VERSION=$(VERSION)" --build-arg="BUILD_NUMBER=$(NEW_BUILD_NUMBER)" -t docker.linkclouds.top/debian10-vlsi-$(1)-suite:$(2) .
endef

# Create the build targets for each combination of suite and architecture
$(foreach suite,$(SUITES),$(foreach arch,$(ARCHITECTURES),$(eval $(call BUILD_TARGET,$(suite),$(arch)))))

##### PUSH ALL
# Define the targets for pushing Docker images
push-all: $(foreach suite,$(SUITES),$(foreach arch,$(ARCHITECTURES),push-$(suite)-$(arch)))

# Define the individual push targets
define PUSH_TARGET
push-$(1)-$(2):
	@echo "Pushing docker.linkclouds.top/debian10-vlsi-$(1)-suite:$(2)..."
	@docker push docker.linkclouds.top/debian10-vlsi-$(1)-suite:$(2)
endef

# Create the push targets for each combination of suite and architecture
$(foreach suite,$(SUITES),$(foreach arch,$(ARCHITECTURES),$(eval $(call PUSH_TARGET,$(suite),$(arch)))))
