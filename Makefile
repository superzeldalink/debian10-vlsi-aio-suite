# Makefile
ARCH := $(shell uname -m)

# Set the target architecture based on the detected architecture
ifeq ($(ARCH),aarch64)
    TARGET_ARCH := arm64
else ifeq ($(ARCH),arm64)
    TARGET_ARCH := arm64
else ifeq ($(ARCH),x86_64)
    TARGET_ARCH := amd64
else
    $(error Unsupported architecture: $(ARCH))
endif

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
	docker build --build-arg="TARGETARCH=$(TARGET_ARCH)" --build-arg="VERSION=$(VERSION)" --build-arg="BUILD_NUMBER=$(NEW_BUILD_NUMBER)" -t superzeldalink/debian10-rtl-suite:latest-$(TARGET_ARCH) .

push:
	docker push superzeldalink/debian10-rtl-suite:latest-$(TARGET_ARCH)

stop-container:
	docker stop rtl-suite || true && docker rm rtl-suite || true

# Run a container from the newly built image
run: stop-container
	docker run -it -d --hostname link --name rtl-suite --mac-address 02:42:ac:11:00:02 -p 3389:3389 -v /Users/link/Documents/SharedVM:/media/share superzeldalink/debian10-rtl-suite:latest-$(TARGET_ARCH) link
run-vnc: stop-container
	docker run -it -d --hostname link --name rtl-suite --mac-address 02:42:ac:11:00:02 -p 5900:5900 -p 5901:5901 -v /Users/link/Documents/SharedVM:/media/share superzeldalink/debian10-rtl-suite:latest-$(TARGET_ARCH) link vnc
run-ssh: stop-container
	docker run -it -d --hostname link --name rtl-suite --mac-address 02:42:ac:11:00:02 -p 2222:22 -v /Users/link/Documents/SharedVM:/media/share superzeldalink/debian10-rtl-suite:latest-$(TARGET_ARCH) link ssh

# Default target
all: build run
