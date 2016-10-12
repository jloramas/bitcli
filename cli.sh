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

init_global_variables() {
  DEFAULT_NAMI_PRODUCT_NAME="BITNAMI CLI"
  DEFAULT_NAMI_LAUNCHER_IMAGE_NAME="bitnami/nami-launcher"
  DEFAULT_NAMI_SERVER_IMAGE_NAME="bitnami/nami-server"
  DEFAULT_NAMI_DIR_IMAGE_NAME="bitnami/nami-dir"
  DEFAULT_NAMI_MOUNT_IMAGE_NAME="bitnami/nami-mount"
  DEFAULT_NAMI_ACTION_IMAGE_NAME="bitnami/nami-action"
  DEFAULT_NAMI_TEST_IMAGE_NAME="bitnami/nami-test"
  DEFAULT_NAMI_DEV_IMAGE_NAME="bitnami/nami-dev"
  DEFAULT_NAMI_SERVER_CONTAINER_NAME="nami-server"
  DEFAULT_NAMI_VERSION="latest"
  DEFAULT_NAMI_UTILITY_VERSION="nightly"
  DEFAULT_NAMI_CLI_ACTION="help"
  DEFAULT_IS_INTERACTIVE="true"
  DEFAULT_IS_PSEUDO_TTY="true"
  DEFAULT_NAMI_DATA_FOLDER="/home/user/nami"

  DEFAULT_NAMI_IMAGE_BASE_NAME="bitnami"

  NAMI_PRODUCT_NAME=${NAMI_PRODUCT_NAME:-${DEFAULT_NAMI_PRODUCT_NAME}}
  NAMI_LAUNCHER_IMAGE_NAME=${NAMI_LAUNCHER_IMAGE_NAME:-${DEFAULT_NAMI_LAUNCHER_IMAGE_NAME}}
  NAMI_SERVER_IMAGE_NAME=${NAMI_SERVER_IMAGE_NAME:-${DEFAULT_NAMI_SERVER_IMAGE_NAME}}
  NAMI_DIR_IMAGE_NAME=${NAMI_DIR_IMAGE_NAME:-${DEFAULT_NAMI_DIR_IMAGE_NAME}}
  NAMI_MOUNT_IMAGE_NAME=${NAMI_MOUNT_IMAGE_NAME:-${DEFAULT_NAMI_MOUNT_IMAGE_NAME}}
  NAMI_ACTION_IMAGE_NAME=${NAMI_ACTION_IMAGE_NAME:-${DEFAULT_NAMI_ACTION_IMAGE_NAME}}
  NAMI_TEST_IMAGE_NAME=${NAMI_TEST_IMAGE_NAME:-${DEFAULT_NAMI_TEST_IMAGE_NAME}}
  NAMI_DEV_IMAGE_NAME=${NAMI_DEV_IMAGE_NAME:-${DEFAULT_NAMI_DEV_IMAGE_NAME}}
  NAMI_SERVER_CONTAINER_NAME=${NAMI_SERVER_CONTAINER_NAME:-${DEFAULT_NAMI_SERVER_CONTAINER_NAME}}
  NAMI_VERSION=${NAMI_VERSION:-${DEFAULT_NAMI_VERSION}}
  NAMI_UTILITY_VERSION=${NAMI_UTILITY_VERSION:-${DEFAULT_NAMI_UTILITY_VERSION}}
  NAMI_CLI_ACTION=${NAMI_CLI_ACTION:-${DEFAULT_NAMI_CLI_ACTION}}
  NAMI_IS_INTERACTIVE=${NAMI_IS_INTERACTIVE:-${DEFAULT_IS_INTERACTIVE}}
  NAMI_IS_PSEUDO_TTY=${NAMI_IS_PSEUDO_TTY:-${DEFAULT_IS_PSEUDO_TTY}}
  NAMI_DATA_FOLDER=${NAMI_DATA_FOLDER:-${DEFAULT_NAMI_DATA_FOLDER}}

  NAMI_IMAGE_BASE_NAME=${NAMI_IMAGE_BASE_NAME:-${DEFAULT_NAMI_IMAGE_BASE_NAME}}

  GLOBAL_NAME_MAP=$(docker info | grep "Name:" | cut -d" " -f2)
  GLOBAL_HOST_ARCH=$(docker version --format {{.Client}} | cut -d" " -f5)
  GLOBAL_UNAME=$(docker run --rm alpine sh -c "uname -r")
  GLOBAL_GET_DOCKER_HOST_IP=$(get_docker_host_ip)

  if is_boot2docker && has_docker_for_windows_client; then
    if [[ "${NAMI_DATA_FOLDER,,}" != *"${USERPROFILE,,}"* ]]; then
      NAMI_DATA_FOLDER=$(get_mount_path "${USERPROFILE}/.${NAMI_MINI_PRODUCT_NAME}/")
      warning "Boot2docker for Windows - NAMI_DATA_FOLDER set to $NAMI_DATA_FOLDER"   
    fi
  fi

  USAGE="
Usage: ${NAMI_MINI_PRODUCT_NAME} <application> <COMMAND> [--force]
    start                              Starts <application> 
    stop                               Stops <application> 
    restart                            Restart <application>
    volumes                            Clear existing volumes for <application>
    info                               Shows <application> docker-compose file and debug info
    update [--force]                   Update base image (--force first deletes it)
    compose <commands>                 Execute docker-compose for the <appliction> with the <commands> as parameters 

    --force                            Force always the download of the <application> docker compose file
"
}

usage () {
  debug $FUNCNAME
  printf "%s" "${USAGE}"
}

parse_command_line () {
  debug $FUNCNAME
  if [ $# -lt 2 ]; then 
    NAMI_CLI_ACTION="help"
  else
    NAMI_CLI_APP=$1
    shift
    case $1 in
      # start|stop|restart|update|info|profile|action|dir|mount|compile|test|help|-h|--help)
      start|stop|restart|volumes|list|update|info|compose|help|-h|--help)
        NAMI_CLI_ACTION=$1
      ;;
      *)
        # unknown option
        error "You passed an unknown command line option."
      ;;
    esac
  fi
}

execute_cli() {
  case ${NAMI_CLI_ACTION} in
    start|stop|restart|volumes|info|compose)
      shift 
      load_profile
      execute_nami_launcher "$@"
    ;;
    profile)
      execute_profile "$@"
    ;;
    dir)
      # remove "dir" arg by shifting it
      shift
      load_profile
      execute_nami_dir "$@"
    ;;
    action)
      # remove "action" arg by shifting it
      shift
      load_profile
      execute_nami_action "$@"
    ;;
    update)
      shift
      load_profile
      # Not yet supported
      # update_nami_cli
      update_nami_image "$@" ${NAMI_IMAGE_BASE_NAME}/${NAMI_CLI_APP} ${NAMI_VERSION}
      # update_nami_image "$@" ${NAMI_SERVER_IMAGE_NAME} ${NAMI_VERSION}
      # update_nami_image "$@" ${NAMI_LAUNCHER_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
      # update_nami_image "$@" ${NAMI_MOUNT_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
      # update_nami_image "$@" ${NAMI_DIR_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
      # update_nami_image "$@" ${NAMI_ACTION_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
      # update_nami_image "$@" ${NAMI_TEST_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
      # update_nami_image "$@" ${NAMI_DEV_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
    ;;
    mount)
      shift
      load_profile
      execute_nami_mount "$@"
    ;;
    compile)
      # remove "compile" arg by shifting it
      shift
      load_profile
      execute_nami_compile "$@"
    ;;
    test)
      # remove "test" arg by shifting it
      shift
      load_profile
      execute_nami_test "$@"
    ;;
    debug)
      load_profile
      execute_nami_info "$@"
    ;;
    help)
      usage
    ;;
  esac
}

docker_exec() {
  debug $FUNCNAME
  if has_docker_for_windows_client; then
    MSYS_NO_PATHCONV=1 docker.exe "$@"
  else
    "$(which docker)" "$@"
  fi
}

docker_run() {
  debug $FUNCNAME
  docker_exec run --rm -v /var/run/docker.sock:/var/run/docker.sock "$@"
}

docker_run_with_env_file() {
  debug $FUNCNAME
  get_list_of_nami_system_environment_variables
  
  # Silly issue - docker run --env-file does not accept path to file - must be in same dir
  cd ~/."${NAMI_MINI_PRODUCT_NAME}"
  docker_run --env-file tmpgibberish "$@"
  rm -rf ~/."${NAMI_MINI_PRODUCT_NAME}"/tmpgibberish > /dev/null
}

docker_run_with_pseudo_tty() {
  debug $FUNCNAME
  if has_pseudo_tty; then
    docker_run_with_env_file -t "$@"
  else
    docker_run_with_env_file "$@"
  fi
}

docker_run_with_interactive() {
  debug $FUNCNAME
  if has_interactive; then
    docker_run_with_pseudo_tty -i "$@"
  else
    docker_run_with_pseudo_tty "$@"
  fi
}

docker_run_with_nami_properties() {
  debug $FUNCNAME
  if [ ! -z ${NAMI_CONF_FOLDER+x} ]; then

    # Configuration directory set by user - this has precedence.
    docker_run_with_interactive -e "NAMI_CONF_FOLDER=${NAMI_CONF_FOLDER}" "$@"
  else 
    if has_nami_properties; then
      # No user configuration directory, but NAMI_PROPERTY_ values set
      generate_temporary_nami_properties_file
      docker_run_with_interactive -e "NAMI_CONF_FOLDER=$(get_mount_path ~/.${NAMI_MINI_PRODUCT_NAME}/conf)" "$@"
      rm -rf ~/."${NAMI_MINI_PRODUCT_NAME}"/conf/nami.properties > /dev/null
    else
      docker_run_with_interactive "$@"
    fi
  fi
}

has_interactive() {
  debug $FUNCNAME
  if [ "${NAMI_IS_INTERACTIVE}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

has_pseudo_tty() {
  debug $FUNCNAME
  if [ "${NAMI_IS_PSEUDO_TTY}" = "true" ]; then
    return 0
  else
    return 1
  fi
}

get_docker_host_ip() {
  debug $FUNCNAME
  case $(get_docker_install_type) in
   boot2docker)
     NETWORK_IF="eth1"
   ;;
   native)
     NETWORK_IF="docker0"
   ;;
   *)
     NETWORK_IF="eth0"
   ;;
  esac
  
  docker run --rm --net host \
            alpine sh -c \
            "ip a show ${NETWORK_IF}" | \
            grep 'inet ' | \
            cut -d/ -f1 | \
            awk '{ print $2}'
}

get_docker_install_type() {
  debug $FUNCNAME
  if is_boot2docker; then
    echo "boot2docker"
  elif is_docker_for_windows; then
    echo "docker4windows"
  elif is_docker_for_mac; then
    echo "docker4mac"
  else
    echo "native"
  fi
}

is_boot2docker() {
  debug $FUNCNAME
  if echo "$GLOBAL_UNAME" | grep -q "boot2docker"; then
    return 0
  else
    return 1
  fi
}

is_docker_for_mac() {
  debug $FUNCNAME
  if is_moby_vm && ! has_docker_for_windows_client; then
    return 0
  else
    return 1
  fi
}

is_docker_for_windows() {
  debug $FUNCNAME
  if is_moby_vm && has_docker_for_windows_client; then
    return 0
  else
    return 1
  fi
}

is_native() {
  debug $FUNCNAME
  if [ $(get_docker_install_type) = "native" ]; then
    return 0
  else
    return 1
  fi
}

is_moby_vm() {
  debug $FUNCNAME
  if echo "$GLOBAL_NAME_MAP" | grep -q "moby"; then
    return 0
  else
    return 1
  fi
}

has_docker_for_windows_client(){
  debug $FUNCNAME
  if [ "${GLOBAL_HOST_ARCH}" = "windows" ]; then
    return 0
  else
    return 1
  fi
}

get_full_path() {
  debug $FUNCNAME
  # "/some/path" => /some/path
  #OUTPUT_PATH=${1//\"}

  # create full directory path
  echo "$(cd "$(dirname "${1}")"; pwd)/$(basename "$1")"
}

convert_windows_to_posix() {
  debug $FUNCNAME
  echo "/"$(echo "$1" | sed 's/\\/\//g' | sed 's/://')
}

get_clean_path() {
  debug $FUNCNAME
  INPUT_PATH=$1
  # \some\path => /some/path
  OUTPUT_PATH=$(echo ${INPUT_PATH} | tr '\\' '/')
  # /somepath/ => /somepath
  OUTPUT_PATH=${OUTPUT_PATH%/}
  # /some//path => /some/path
  OUTPUT_PATH=$(echo ${OUTPUT_PATH} | tr -s '/')
  # "/some/path" => /some/path
  OUTPUT_PATH=${OUTPUT_PATH//\"}
  echo ${OUTPUT_PATH}
}

get_mount_path() {
  debug $FUNCNAME
  FULL_PATH=$(get_full_path "${1}")

  POSIX_PATH=$(convert_windows_to_posix "${FULL_PATH}")

  CLEAN_PATH=$(get_clean_path "${POSIX_PATH}")
  echo $CLEAN_PATH
}

has_docker_for_windows_ip() {
  debug $FUNCNAME
  if [ "${GLOBAL_GET_DOCKER_HOST_IP}" = "10.0.75.2" ]; then
    return 0
  else
    return 1
  fi
}

get_nami_hostname() {
  debug $FUNCNAME
  INSTALL_TYPE=$(get_docker_install_type)
  if [ "${INSTALL_TYPE}" = "boot2docker" ]; then
    echo $GLOBAL_GET_DOCKER_HOST_IP
  else
    echo "localhost"
  fi
}

has_nami_env_variables() {
  debug $FUNCNAME
  PROPERTIES=$(env | grep NAMI_)

  if [ "$PROPERTIES" = "" ]; then
    return 1
  else 
    return 0
  fi 
}

get_list_of_nami_system_environment_variables() {
  debug $FUNCNAME

  # See: http://stackoverflow.com/questions/4128235/what-is-the-exact-meaning-of-ifs-n
  IFS=$'\n'
  
  TMP_DIR=~/."${NAMI_MINI_PRODUCT_NAME}"
  TMP_FILE="${TMP_DIR}"/tmpgibberish

  test -d "${TMP_DIR}" || mkdir -p "${TMP_DIR}"
  touch "${TMP_FILE}"

  if has_default_profile; then
    cat "${TMP_DIR}"/profiles/"${NAMI_PROFILE}" | sed 's/\"//g' >> "${TMP_FILE}"
  else

    # Grab these values to send to other utilities - they need to know the values  
    echo "NAMI_SERVER_CONTAINER_NAME=${NAMI_SERVER_CONTAINER_NAME}" >> "${TMP_FILE}"
    echo "NAMI_SERVER_IMAGE_NAME=${NAMI_SERVER_IMAGE_NAME}" >> "${TMP_FILE}"
    echo "NAMI_PRODUCT_NAME=${NAMI_PRODUCT_NAME}" >> "${TMP_FILE}"
    echo "NAMI_MINI_PRODUCT_NAME=${NAMI_MINI_PRODUCT_NAME}" >> "${TMP_FILE}"
    echo "NAMI_VERSION=${NAMI_VERSION}" >> "${TMP_FILE}"
    echo "NAMI_CLI_INFO=${NAMI_CLI_INFO}" >> "${TMP_FILE}"
    echo "NAMI_CLI_DEBUG=${NAMI_CLI_DEBUG}" >> "${TMP_FILE}"
    echo "NAMI_DATA_FOLDER=${NAMI_DATA_FOLDER}" >> "${TMP_FILE}"

    echo "NAMI_IMAGE_BASE_NAME=${NAMI_IMAGE_BASE_NAME}" >> "${TMP_FILE}"


    NAMI_VARIABLES=$(env | grep NAMI_)

    if [ ! -z ${NAMI_VARIABLES+x} ]; then
      env | grep NAMI_ >> "${TMP_FILE}"
    fi

    # Add in known proxy variables
    if [ ! -z ${http_proxy+x} ]; then
      echo "http_proxy=${http_proxy}" >> "${TMP_FILE}"
    fi

    if [ ! -z ${https_proxy+x} ]; then
      echo "https_proxy=${https_proxy}" >> "${TMP_FILE}"
    fi

    if [ ! -z ${no_proxy+x} ]; then
      echo "no_proxy=${no_proxy}" >> "${TMP_FILE}"
    fi
  fi
}

check_current_image_and_update_if_not_found() {
  debug $FUNCNAME

  CURRENT_IMAGE=$(docker images -q "$1":"$2")

  if [ "${CURRENT_IMAGE}" == "" ]; then
    update_nami_image $1 $2
  fi
}

has_nami_properties() {
  debug $FUNCNAME
  PROPERTIES=$(env | grep NAMI_PROPERTY_)

  if [ "$PROPERTIES" = "" ]; then
    return 1
  else 
    return 0
  fi 
}

generate_temporary_nami_properties_file() {
  debug $FUNCNAME
  if has_nami_properties; then
    test -d ~/."${NAMI_MINI_PRODUCT_NAME}"/conf || mkdir -p ~/."${NAMI_MINI_PRODUCT_NAME}"/conf
    touch ~/."${NAMI_MINI_PRODUCT_NAME}"/conf/nami.properties

    # Get list of properties
    PROPERTIES_ARRAY=($(env | grep NAMI_PROPERTY_))
    for PROPERTY in "${PROPERTIES_ARRAY[@]}"
    do
      # NAMI_PROPERTY_NAME=value ==> NAME=value
      PROPERTY_WITHOUT_PREFIX=${PROPERTY#NAMI_PROPERTY_}

      # NAME=value ==> separate name / value into different variables
      PROPERTY_NAME=$(echo $PROPERTY_WITHOUT_PREFIX | cut -f1 -d=)
      PROPERTY_VALUE=$(echo $PROPERTY_WITHOUT_PREFIX | cut -f2 -d=)
     
      # Replace "_" in names to periods
      CONVERTED_PROPERTY_NAME=$(echo "$PROPERTY_NAME" | tr _ .)

      # Replace ".." in names to "_"
      SUPER_CONVERTED_PROPERTY_NAME="${CONVERTED_PROPERTY_NAME//../_}"

      echo "$SUPER_CONVERTED_PROPERTY_NAME=$PROPERTY_VALUE" >> ~/."${NAMI_MINI_PRODUCT_NAME}"/conf/nami.properties
    done
  fi
}

contains() {
  string="$1"
  substring="$2"
  if test "${string#*$substring}" != "$string"
  then
    return 0    # $substring is in $string
  else
    return 1    # $substring is not in $string
  fi
}

get_container_ssh() {
  CURRENT_NAMI_DEBUG=$(docker inspect --format='{{.NetworkSettings.Ports}}' ${1})
  IFS=$' '
  for SINGLE_BIND in $CURRENT_NAMI_DEBUG; do
    case $SINGLE_BIND in
      *22/tcp:*)
        echo $SINGLE_BIND | cut -f2 -d":"
        return
      ;;
      *)
      ;;
    esac
  done
  echo "<nil>"
}

has_ssh () {
  if $(contains $(get_container_ssh $1) "<nil>"); then
    return 1
  else
    return 0
  fi
}

has_default_profile() {
  debug $FUNCNAME
  if [ -f ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/.profile ]; then
    return 0
  else 
    return 1
  fi 
}

get_default_profile() {
  debug $FUNCNAME
  if [ has_default_profile ]; then
    source ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/.profile
    echo "${NAMI_PROFILE}"
  else
    echo ""
  fi
}

load_profile() {
  debug $FUNCNAME
  if has_default_profile; then

    source ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/.profile

    if [ ! -f ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${NAMI_PROFILE}" ]; then
      error ""
      error "${NAMI_MINI_PRODUCT_NAME} CLI profile set in ~/.${NAMI_MINI_PRODUCT_NAME}/profiles/.profile to '${NAMI_PROFILE}' but ~/.${NAMI_MINI_PRODUCT_NAME}/profiles/${NAMI_PROFILE} does not exist."
      error ""
      return
    fi

    source ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${NAMI_PROFILE}"
    info "${NAMI_PRODUCT_NAME}: Loaded profile ${NAMI_PROFILE}"
  fi
}

###########################################################################
### END HELPER FUNCTIONS
###
### START CLI COMMANDS
###########################################################################

execute_nami_launcher() {
  debug $FUNCNAME

  #if [ ! $# -eq 1 ]; then
  #  error "${NAMI_MINI_PRODUCT_NAME} start/stop/start: You passed unknown options."
  #  return
  #fi
  
  COMPOSE_FILE="./${NAMI_CLI_APP}/docker-compose.yml"
  if [ ! -f "${COMPOSE_FILE}" ] || [ "${2:-ok}" = "--force" ]; then
    URL=https://raw.githubusercontent.com/bitnami/bitnami-docker-${NAMI_CLI_APP}/master/docker-compose.yml
    info "Downloading docker compose file from ${URL}"
    if ! curl --output /dev/null --silent --head --fail "$URL"; then
      error "${NAMI_CLI_APP} download error. Bad network or a non Bitnami supported container application"
      return 1;
    fi
    test -d "./${NAMI_CLI_APP}" || mkdir "./${NAMI_CLI_APP}"
    curl -sL $URL > "${COMPOSE_FILE}"
  fi

  if [ ! -f "${COMPOSE_FILE}" ]; then
    error "${NAMI_CLI_APP} compose file not found: ${COMPOSE_FILE}"
    return 1;
  else 
    info "Using: ${COMPOSE_FILE}"
    case ${NAMI_CLI_ACTION} in
      start)
      COMPOSE_FILE="${COMPOSE_FILE}" docker-compose up &
      ;;
      stop)
      COMPOSE_FILE="${COMPOSE_FILE}" docker-compose down
      ;;
      restart)
      COMPOSE_FILE="${COMPOSE_FILE}" docker-compose down
      COMPOSE_FILE="${COMPOSE_FILE}" docker-compose up &
      ;;
      volumes)
      COMPOSE_FILE="${COMPOSE_FILE}" docker-compose down -v
      ;;
      info)
      info "---------------------------------------"
      info "------   DOCKER COMPOSE INFO   --------"
      info "---------------------------------------"
      info ""
      info ${COMPOSE_FILE}
      info "---------------------------------------"
      info "`cat ${COMPOSE_FILE}`"
      info "---------------------------------------"
      print_nami_cli_debug
      # run_connectivity_tests
      ;;
      compose)
      shift
      COMPOSE_FILE="${COMPOSE_FILE}" docker-compose "$@"
      ;;
    esac
  fi
  # check_current_image_and_update_if_not_found ${NAMI_LAUNCHER_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
  # docker_run_with_nami_properties "${NAMI_LAUNCHER_IMAGE_NAME}":"${NAMI_UTILITY_VERSION}" "${NAMI_CLI_ACTION}" || true
}

execute_profile(){
  debug $FUNCNAME

  if [ ! $# -ge 2 ]; then 
    error "${NAMI_MINI_PRODUCT_NAME} profile: Wrong number of arguments."
    return
  fi

  case ${2} in
    add|rm|set|info|update)
    if [ ! $# -eq 3 ]; then 
      error "${NAMI_MINI_PRODUCT_NAME} profile: Wrong number of arguments."
      return
    fi
    ;;
    unset|list)
    if [ ! $# -eq 2 ]; then 
      error "${NAMI_MINI_PRODUCT_NAME} profile: Wrong number of arguments."
      return
    fi
    ;;
  esac

  case ${2} in
    add)
      if [ -f ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${NAMI_MINI_PRODUCT_NAME}/profiles/${3} already exists. Nothing to do. Exiting."
        return
      fi

      PROFILE_DIR=~/."${NAMI_MINI_PRODUCT_NAME}"/profiles
      PROFILE_FILE="${PROFILE_DIR}"/"${3}"
      test -d "${PROFILE_DIR}" || mkdir -p "${PROFILE_DIR}"
      touch "${PROFILE_FILE}"

      echo "NAMI_PRODUCT_NAME=\"""${NAMI_PRODUCT_NAME}""\"" >> "${PROFILE_FILE}"
      echo "NAMI_MINI_PRODUCT_NAME=\"""${NAMI_MINI_PRODUCT_NAME}""\"" >> "${PROFILE_FILE}"
      echo "NAMI_LAUNCHER_IMAGE_NAME=$NAMI_LAUNCHER_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "NAMI_SERVER_IMAGE_NAME=$NAMI_SERVER_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "NAMI_DIR_IMAGE_NAME=$NAMI_DIR_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "NAMI_MOUNT_IMAGE_NAME=$NAMI_MOUNT_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "NAMI_TEST_IMAGE_NAME=$NAMI_TEST_IMAGE_NAME" >> "${PROFILE_FILE}"
      echo "NAMI_SERVER_CONTAINER_NAME=$NAMI_SERVER_CONTAINER_NAME" >> "${PROFILE_FILE}"
      echo "NAMI_VERSION=$NAMI_VERSION" >> "${PROFILE_FILE}"

      # Add all other variables to the profile
      env | grep NAMI_ >> "${PROFILE_FILE}" || true

      # Remove duplicates, if any
      cat "${PROFILE_FILE}" | sort | uniq > "${PROFILE_DIR}"/tmp
      mv -f "${PROFILE_DIR}"/tmp "${PROFILE_FILE}"


      info "Added new ${NAMI_MINI_PRODUCT_NAME} CLI profile ${PROFILE_FILE}."
    ;;
    update)
      if [ ! -f ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${NAMI_MINI_PRODUCT_NAME}/profiles/${3} does not exist. Nothing to update. Exiting."
        return
      fi

      execute_profile profile rm "${3}"
      execute_profile profile add "${3}"
    ;;
    rm)
      if [ ! -f ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${NAMI_MINI_PRODUCT_NAME}/profiles/${3} does not exist. Nothing to do. Exiting."
        return
      fi

      rm ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${3}" > /dev/null

      info "Removed ${NAMI_MINI_PRODUCT_NAME} CLI profile ~/.${NAMI_MINI_PRODUCT_NAME}/profiles/${3}."
    ;;
    info)
      if [ ! -f ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${NAMI_MINI_PRODUCT_NAME}/profiles/${3} does not exist. Nothing to do. Exiting."
        return
      fi
 
      while IFS= read line
      do
        # display $line or do somthing with $line
        info "$line"
      done <~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${3}"
    ;;
    set)
      if [ ! -f ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/"${3}" ]; then
        error "Profile ~/.${NAMI_MINI_PRODUCT_NAME}/${3} does not exist. Nothing to do. Exiting."
        return
      fi
      
      echo "NAMI_PROFILE=${3}" > ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/.profile

      info "Set active ${NAMI_MINI_PRODUCT_NAME} CLI profile to ~/.${NAMI_MINI_PRODUCT_NAME}/profiles/${3}."
    ;;
    unset)
      if [ ! -f ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/.profile ]; then
        error "Default profile not set. Nothing to do. Exiting."
        return
      fi
      
      rm -rf ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles/.profile

      info "Unset the default ${NAMI_MINI_PRODUCT_NAME} CLI profile. No profile currently set."
    ;;
    list)
      if [ -d ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles ]; then
        info "Available ${NAMI_MINI_PRODUCT_NAME} CLI profiles:"
        ls ~/."${NAMI_MINI_PRODUCT_NAME}"/profiles
      else
        info "No ${NAMI_MINI_PRODUCT_NAME} CLI profiles currently set."
      fi

      if has_default_profile; then
        info "Default profile set to:"
        get_default_profile
      else
        info "Default profile currently unset."
      fi
    ;;
  esac
}

execute_nami_dir() {
  debug $FUNCNAME
  check_current_image_and_update_if_not_found ${NAMI_DIR_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
  CURRENT_DIRECTORY=$(get_mount_path "${PWD}")
  docker_run_with_nami_properties -v "$CURRENT_DIRECTORY":"$CURRENT_DIRECTORY" "${NAMI_DIR_IMAGE_NAME}":"${NAMI_UTILITY_VERSION}" "${CURRENT_DIRECTORY}" "$@"
}

execute_nami_action() {
  debug $FUNCNAME
  check_current_image_and_update_if_not_found ${NAMI_ACTION_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
  docker_run_with_nami_properties "${NAMI_ACTION_IMAGE_NAME}":"${NAMI_UTILITY_VERSION}" "$@"
}

update_nami_image() {
  debug $FUNCNAME
  if [ "${1}" == "--force" ]; then
    shift
    info "${NAMI_PRODUCT_NAME}: Removing image $1:$2"
    docker rmi -f $1:$2 > /dev/null
  fi

  info "${NAMI_PRODUCT_NAME}: Pulling image $1:$2"
  docker pull $1:$2
  echo ""
}

execute_nami_mount() {
  debug $FUNCNAME

  # Determine the mount path to do the mount
  info "${NAMI_MINI_PRODUCT_NAME} mount: Setting local mount path to ${PWD}"
  MOUNT_PATH=$(get_mount_path "${PWD}")
  HOME_PATH=$(get_mount_path "${HOME}")

  # If extra parameter provided, then this is the port to connect to
  if [ $# -eq 1 ]; then
    info "${NAMI_MINI_PRODUCT_NAME} mount: Connecting to remote workspace on port ${1}"
    WS_PORT=${1}

  # Port not provided, let's do a simple discovery of running workspaces
  else 
    info "${NAMI_MINI_PRODUCT_NAME} mount: Searching for running workspaces with open SSH port..."

    CURRENT_WS_INSTANCES=$(docker ps -aq --filter "name=workspace")
    CURRENT_WS_COUNT=$(echo $CURRENT_WS_INSTANCES | wc -w)
    
    # No running workspaces
    if [ $CURRENT_WS_COUNT -eq 0 ]; then
      error "${NAMI_MINI_PRODUCT_NAME} mount: We could not find any running workspaces"
      return

    # Exactly 1 running workspace
    elif [ $CURRENT_WS_COUNT -eq 1 ]; then

      if has_ssh ${CURRENT_WS_INSTANCES}; then
        RUNNING_WS_PORT=$(docker inspect --format='{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' ${CURRENT_WS_INSTANCES})
        info "${NAMI_MINI_PRODUCT_NAME} mount: Connecting to remote workspace on port $RUNNING_WS_PORT"
        WS_PORT=$RUNNING_WS_PORT
      else
        error "${NAMI_MINI_PRODUCT_NAME} mount: We found 1 running workspace, but it does not have an SSH agent"
        return
      fi

    # 2+ running workspace
    else 
      info "${NAMI_MINI_PRODUCT_NAME} mount: Re-run with 'nami mount <ssh-port>'"
      IFS=$'\n'

      echo "WS CONTAINER ID    HAS SSH?    SSH PORT"
      for NAMI_WS_CONTAINER_ID in $CURRENT_WS_INSTANCES; do
        CURRENT_WS_PORT=""
        if has_ssh ${NAMI_WS_CONTAINER_ID}; then 
          CURRENT_WS_PORT=$(docker inspect --format='{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' ${NAMI_WS_CONTAINER_ID})
        fi
        echo "$NAMI_WS_CONTAINER_ID       $(has_ssh ${NAMI_WS_CONTAINER_ID} && echo "y" || echo "n")           $CURRENT_WS_PORT"
      done
      return
    fi
  fi
  
  if is_native; then
    docker_run_with_nami_properties --cap-add SYS_ADMIN \
                                   --device /dev/fuse \
                                   -v ${HOME}/.ssh:${HOME}/.ssh \
                                   -v ${HOME}/.unison:${HOME}/.unison \
                                   -v /etc/group:/etc/group:ro \
                                   -v /etc/passwd:/etc/passwd:ro \
                                   -u $(id -u ${USER}) \
                                   -v "${MOUNT_PATH}":/mnthost \
                                   "${NAMI_MOUNT_IMAGE_NAME}":"${NAMI_UTILITY_VERSION}" \
                                        "${GLOBAL_GET_DOCKER_HOST_IP}" $WS_PORT
    
  else
    docker_run_with_nami_properties --cap-add SYS_ADMIN \
                                   --device /dev/fuse \
                                   -v "${HOME_PATH}"/.ssh:/root/.ssh \
                                   -v "${MOUNT_PATH}":/mnthost \
                                   "${NAMI_MOUNT_IMAGE_NAME}":"${NAMI_UTILITY_VERSION}" \
                                        "${GLOBAL_GET_DOCKER_HOST_IP}" $WS_PORT
  fi

}

execute_nami_compile() {
  debug $FUNCNAME
  if [ $# -eq 0 ]; then 
    error "${NAMI_MINI_PRODUCT_NAME} compile: Missing argument - pass compilation command as paramters."
    return
  fi

  check_current_image_and_update_if_not_found ${NAMI_DEV_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
  CURRENT_DIRECTORY=$(get_mount_path "${PWD}")
  docker_run_with_nami_properties -v "$CURRENT_DIRECTORY":/home/user/nami-build \
                                 -v "$(get_mount_path ~/.m2):/home/user/.m2" \
                                 -w /home/user/nami-build \
                                 "${NAMI_DEV_IMAGE_NAME}":"${NAMI_UTILITY_VERSION}" "$@"
}

execute_nami_test() {
  debug $FUNCNAME
  check_current_image_and_update_if_not_found ${NAMI_TEST_IMAGE_NAME} ${NAMI_UTILITY_VERSION}
  docker_run_with_nami_properties "${NAMI_TEST_IMAGE_NAME}":"${NAMI_UTILITY_VERSION}" "$@"
}

execute_nami_info() {
  debug $FUNCNAME
  if [ $# -eq 1 ]; then
    TESTS="--server"
  else
    TESTS=$2
  fi
  
  case $TESTS in
    --all|-all)
      print_nami_cli_debug
      execute_nami_launcher
      run_connectivity_tests
      execute_nami_test post-flight-check "$@"
    ;;
    --cli|-cli)
      print_nami_cli_debug
    ;;
    --networking|-networking)
      run_connectivity_tests
    ;;
    --server|-server)
      print_nami_cli_debug
      execute_nami_launcher
    ;;
    --create|-create)
      execute_nami_test "$@"
    ;;
    *)
      info "Unknown info flag passed: $2. Exiting."
    ;;
  esac
}

print_nami_cli_debug() {
  debug $FUNCNAME
  info "---------------------------------------"
  info "-------------   CLI INFO   ------------"
  info "---------------------------------------"
  info ""
  info "---------  PLATFORM INFO  -------------"
  info "CLI DEFAULT PROFILE       = $(has_default_profile && echo $(get_default_profile) || echo "not set")"
  info "NAMI_VERSION               = ${NAMI_VERSION}"
  info "NAMI_CLI_VERSION           = ${NAMI_CLI_VERSION}"
  info "NAMI_UTILITY_VERSION       = ${NAMI_UTILITY_VERSION}"
  info "DOCKER_INSTALL_TYPE       = $(get_docker_install_type)"
  info "DOCKER_HOST_IP            = ${GLOBAL_GET_DOCKER_HOST_IP}"
  info "IS_NATIVE                 = $(is_native && echo "YES" || echo "NO")"
  info "IS_WINDOWS                = $(has_docker_for_windows_client && echo "YES" || echo "NO")"
  info "IS_DOCKER_FOR_WINDOWS     = $(is_docker_for_windows && echo "YES" || echo "NO")"
  info "IS_DOCKER_FOR_MAC         = $(is_docker_for_mac && echo "YES" || echo "NO")"
  info "IS_BOOT2DOCKER            = $(is_boot2docker && echo "YES" || echo "NO")"
  info "HAS_DOCKER_FOR_WINDOWS_IP = $(has_docker_for_windows_ip && echo "YES" || echo "NO")"
  info "IS_MOBY_VM                = $(is_moby_vm && echo "YES" || echo "NO")"
  info "HAS_NAMI_ENV_VARIABLES     = $(has_nami_env_variables && echo "YES" || echo "NO")"
  info "HAS_TEMP_NAMI_PROPERTIES   = $(has_nami_properties && echo "YES" || echo "NO")"
  info "IS_INTERACTIVE            = $(has_interactive && echo "YES" || echo "NO")"
  info "IS_PSEUDO_TTY             = $(has_pseudo_tty && echo "YES" || echo "NO")"
  info ""
}

run_connectivity_tests() {
  debug $FUNCNAME
  info ""
  info "---------------------------------------"
  info "--------   CONNECTIVITY TEST   --------"
  info "---------------------------------------"
  # Start a fake workspace agent
  docker_exec run -d -p 12345:80 --name fakeagent alpine httpd -f -p 80 -h /etc/ > /dev/null

  AGENT_INTERNAL_IP=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' fakeagent)
  AGENT_INTERNAL_PORT=80
  AGENT_EXTERNAL_IP=$GLOBAL_GET_DOCKER_HOST_IP
  AGENT_EXTERNAL_PORT=12345


  ### TEST 1: Simulate browser ==> workspace agent HTTP connectivity
  HTTP_CODE=$(curl -I $(get_nami_hostname):${AGENT_EXTERNAL_PORT}/alpine-release \
                          -s -o /dev/null --connect-timeout 5 \
                          --write-out "%{http_code}") || echo "28" > /dev/null

  if [ "${HTTP_CODE}" = "200" ]; then
      info "Browser             => Workspace Agent (Hostname)   : Connection succeeded"
  else
      info "Browser             => Workspace Agent (Hostname)   : Connection failed"
  fi

  ### TEST 1a: Simulate browser ==> workspace agent HTTP connectivity
  HTTP_CODE=$(curl -I ${AGENT_EXTERNAL_IP}:${AGENT_EXTERNAL_PORT}/alpine-release \
                          -s -o /dev/null --connect-timeout 5 \
                          --write-out "%{http_code}") || echo "28" > /dev/null

  if [ "${HTTP_CODE}" = "200" ]; then
      info "Browser             => Workspace Agent (External IP): Connection succeeded"
  else
      info "Browser             => Workspace Agent (External IP): Connection failed"
  fi

  ### TEST 2: Simulate Che server ==> workspace agent (external IP) connectivity 
  export HTTP_CODE=$(docker run --rm --name fakeserver \
                                --entrypoint=curl \
                                ${NAMI_SERVER_IMAGE_NAME}:${NAMI_VERSION} \
                                  -I ${AGENT_EXTERNAL_IP}:${AGENT_EXTERNAL_PORT}/alpine-release \
                                  -s -o /dev/null \
                                  --write-out "%{http_code}")
  
  if [ "${HTTP_CODE}" = "200" ]; then
      info "Che Server          => Workspace Agent (External IP): Connection succeeded"
  else
      info "Che Server          => Workspace Agent (External IP): Connection failed"
  fi

  ### TEST 3: Simulate Che server ==> workspace agent (internal IP) connectivity 
  export HTTP_CODE=$(docker run --rm --name fakeserver \
                                --entrypoint=curl \
                                ${NAMI_SERVER_IMAGE_NAME}:${NAMI_VERSION} \
                                  -I ${AGENT_INTERNAL_IP}:${AGENT_INTERNAL_PORT}/alpine-release \
                                  -s -o /dev/null \
                                  --write-out "%{http_code}")

  if [ "${HTTP_CODE}" = "200" ]; then
      info "Che Server          => Workspace Agent (Internal IP): Connection succeeded"
  else
      info "Che Server          => Workspace Agent (Internal IP): Connection failed"
  fi

  docker rm -f fakeagent > /dev/null
}
