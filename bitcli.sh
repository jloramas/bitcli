#!/bin/bash
# Copyright (c) 2012-2016 Bitrock
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Jose L. Oramas - Initial adaptation from Codenvy CLI implementation
#

init_logging() {
  BLUE='\033[1;34m'
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[38;5;220m'
  NC='\033[0m'

  # Which nami CLI version to run?
  DEFAULT_NAMI_CLI_VERSION="latest"
  NAMI_CLI_VERSION=${NAMI_CLI_VERSION:-${DEFAULT_NAMI_CLI_VERSION}}

  # Name used in CLI statements
  DEFAULT_NAMI_MINI_PRODUCT_NAME="bitcli"
  NAMI_MINI_PRODUCT_NAME=${NAMI_MINI_PRODUCT_NAME:-${DEFAULT_NAMI_MINI_PRODUCT_NAME}}

  # Turns on stack trace
  DEFAULT_NAMI_CLI_DEBUG="false"
  NAMI_CLI_DEBUG=${NAMI_CLI_DEBUG:-${DEFAULT_NAMI_CLI_DEBUG}}

  # Activates console output
  DEFAULT_NAMI_CLI_INFO="true"
  NAMI_CLI_INFO=${NAMI_CLI_INFO:-${DEFAULT_NAMI_CLI_INFO}}

  # Activates console warnings
  DEFAULT_NAMI_CLI_WARN="true"
  NAMI_CLI_WARN=${NAMI_CLI_WARN:-${DEFAULT_NAMI_CLI_WARN}}
}

warning() {
  if is_warning; then
    printf  "${YELLOW}WARN:${NC} %s\n" "${1}"
  fi
}

info() {
  if is_info; then
    printf  "${GREEN}INFO:${NC} %s\n" "${1}"
  fi
}

debug() {
  if is_debug; then
    printf  "\n${BLUE}DEBUG:${NC} %s" "${1}"
  fi
}

error() {
  printf  "${RED}ERROR:${NC} %s\n" "${1}"
}

is_warning() {
  if [ "${NAMI_CLI_WARN}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

is_info() {
  if [ "${NAMI_CLI_INFO}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

is_debug() {
  if [ "${NAMI_CLI_DEBUG}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

has_docker() {
  hash docker 2>/dev/null && return 0 || return 1
}

check_docker() {
  if ! has_docker; then
    error "Error - Docker not found. Get it at https://docs.docker.com/engine/installation/."
    return 1;
  fi

  if ! docker ps > /dev/null 2>&1; then
    output=$(docker ps)
    error "Error - Docker not installed properly: \n${output}"
    return 1;
  fi

  # Prep script by getting default image
  if [ "$(docker images -q alpine 2> /dev/null)" = "" ]; then
    info "Pulling image alpine:latest"
    docker pull alpine > /dev/null 2>&1
  fi

  if [ "$(docker images -q appropriate/curl 2> /dev/null)" = "" ]; then
    info "Pulling image curl:latest"
    docker pull appropriate/curl > /dev/null 2>&1
  fi
}

curl () {
  docker run --rm appropriate/curl "$@"
}

update_nami_cli() {
  info "Downloading cli-$NAMI_CLI_VERSION"

  CLI_DIR=~/."${NAMI_MINI_PRODUCT_NAME}"/cli
  test -d "${CLI_DIR}" || mkdir -p "${CLI_DIR}"

  if [[ "${NAMI_CLI_VERSION}" = "latest" ]] || \
     [[ "${NAMI_CLI_VERSION}" = "nightly" ]] || \
     [[ ${NAMI_CLI_VERSION:0:1} == "4" ]]; then
    GITHUB_VERSION=master
  else
    GITHUB_VERSION=$NAMI_CLI_VERSION
  fi
  
  URL=https://raw.githubusercontent.com/jloramas/bitcli/$GITHUB_VERSION/cli.sh

  if ! curl --output /dev/null --silent --head --fail "$URL"; then
    error "CLI download error. Bad network or version."
    return 1;
  else 
    curl -sL $URL > ~/."${NAMI_MINI_PRODUCT_NAME}"/cli/cli-$NAMI_CLI_VERSION.sh
  fi
}

init() {
  init_logging
  check_docker

  # Test to see if we have cli_funcs
  if [ ! -f ~/."${NAMI_MINI_PRODUCT_NAME}"/cli/cli-${NAMI_CLI_VERSION}.sh ]; then
    # By now we don't want to update anything, so commented 
    update_nami_cli
    # info "CLI not found"
  fi

  source ~/."${NAMI_MINI_PRODUCT_NAME}"/cli/cli-${NAMI_CLI_VERSION}.sh

  init_global_variables
}

# See: https://sipb.mit.edu/doc/safe-shell/
set -e
set -u
init
parse_command_line "$@"
execute_cli "$@"
