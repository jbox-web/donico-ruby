#!/usr/bin/env bash
# shellcheck shell=bash
#
# Library sourced by exe/inspec. Not meant to be executed directly.

##########
# CONFIG #
##########

INSPEC_IMAGE=harbor.thetuxhouse.org/jbox/base/inspec:latest

#############
# FUNCTIONS #
#############

# Run bash export on arguments passed to this function.
# Arguments are a space separated list of key=value
function load_env() {
  local val key value

  for val in "${@}"; do
    # Split on the FIRST separator only: 'cut -f 2' truncated any value holding
    # an '=' (base64 padding, JWTs, query strings).
    key="${val%%=*}"
    value="${val#*=}"

    [ -z "${key}" ] && continue

    export "${key}=${value}"
  done
}


function container_spin() {
  local test_mode=${1}
  local image=${2}
  local test_inputs=${3}

  # If <project>/bin/inspec-container-up script exists in the project run it,
  # otherwise use our builtin function
  container_up_override="$(pwd)/bin/inspec-container-up"

  if [ -f "${container_up_override}" ]; then
    command="${container_up_override}"
  else
    command="container_up"
  fi

  "${command}" "${test_mode}" "${image}" "${test_inputs}"
}


# This function is called on the EXIT signal, which also covers INT and any
# error exit under 'set -o errexit'. Trapping ERR as well made it run twice and
# fire a second 'docker kill' against an already destroyed container.
function container_clean() {
  # If <project>/bin/inspec-container-down script exists in project run it,
  # otherwise use our builtin function
  container_down_override="$(pwd)/bin/inspec-container-down"

  if [ -f "${container_down_override}" ]; then
    command="${container_down_override}"
  else
    command="container_down"
  fi

  "${command}" "${container_id}"
}


# Spin a Docker container up to test our built images
function container_up() {
  local image=${2}

  docker run --rm -d "${image}" /bin/bash -c "while true; do sleep 1; done"
}


# Destroy the Docker container used for testing
function container_down() {
  local container_id=${1}

  # -n on the value, not '${var+x}': the parameter is always *set* here (it is a
  # positional argument), so the +x form was always true and ran 'docker kill'
  # with an empty argument whenever the container failed to start.
  #
  # Must return 0 when there is nothing to clean: this runs from the EXIT trap and
  # a non-zero status there overrides the exit status of the whole script.
  if [ -n "${container_id}" ]; then
    echo "Cleanup docker containers"
    docker kill "${container_id}"
  fi

  return 0
}


# Pull docker image before launching tests when running in Kaniko mode
function pull_image() {
  local image=${1}

  docker pull "${image}"
}


# Prepare inputs arguments for Inspec
function split_test_inputs() {
  # If no inputs are given we return ""
  if [ "${#}" -eq 0 ] || [ -z "${*}" ]; then
    echo ""
  else
    local out="--input"
    local val

    for val in "${@}"; do
      out="${out} ${val}"
    done

    echo "${out}"
  fi
}


# Call Inspec
function run_spec() {
  local test_mode=${1}
  local container_id=${2}
  local test_inputs
  # shellcheck disable=SC2086 # the inputs are a space separated list to split
  test_inputs=$(split_test_inputs ${3})

  local args="--chef-license accept-silent --no-create-lockfile --show-progress"

  # If <project>/.inspecrc file exists in the project read it
  inspec_args_override="$(pwd)/.inspecrc"

  if [ -f "${inspec_args_override}" ]; then
    # -r keeps backslashes literal; the '|| [ -n "$line" ]' fallback keeps the
    # last line of a file that does not end with a newline.
    while IFS= read -r line || [ -n "${line}" ]; do
      args="${args} ${line}"
    done <"${inspec_args_override}"
  fi

  case "${test_mode}" in
    donico)
      local dir=/app/test/

      # We use Docker-in-Docker to run Inspec so mount the Docker socket
      # Mount the current app to test within Inspec container
      # Launch Inspec
      # shellcheck disable=SC2086 # args and test_inputs are argument lists to split
      docker run \
        --rm \
        --mount type=bind,source="$(pwd)",target=/app \
        --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
        ${INSPEC_IMAGE} \
        inspec exec ${dir} -t "docker://${container_id}" ${args} ${test_inputs}
    ;;

    *)
      echo "Unknow test mode: ${test_mode}"
      exit 1
    ;;
  esac
}
