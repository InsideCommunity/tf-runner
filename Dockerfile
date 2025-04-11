# Use the offical golang image to create a binary.
# This is based on Debian and sets the GOPATH to /go.
# https://hub.docker.com/_/golang
FROM golang:1.23-bookworm AS builder

ARG APP_VERSION
# Create and change to the app directory.
WORKDIR /app

# Retrieve application dependencies.
# This allows the container build to reuse cached dependencies.
# Expecting to copy go.mod and if present go.sum.
COPY go.* ./
RUN go mod download

# Copy local code to the container image.
COPY . ./

# Build the binary.
RUN go build  -ldflags="-X 'main.Version=$APP_VERSION'" -v -o server ./cmd/
#RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
#    -ldflags="-w -s" \
#    -o /app/server \
#    cmd/

# Use the official Debian slim image for a lean production container.
# https://hub.docker.com/_/debian
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM debian:bookworm-slim

ARG TALOS_VERSION=v1.9.4
ARG K8S_VERSION=1.32.2
ARG YQ_VERSION=v4.45.1

RUN set -x && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl jq && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -r cockpit && \
    useradd -r -g cockpit -m cockpit



FROM gitlab/gitlab-runner:ubuntu 

RUN set -x && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl unzip

RUN curl -L https://releases.hashicorp.com/terraform/1.11.4/terraform_1.11.4_linux_amd64.zip -o terraform.zip && unzip terraform.zip