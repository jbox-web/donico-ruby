##########
# CONFIG #
##########

INSPEC_IMAGE=harbor.jbox-cloud.fr/jbox/base/inspec:latest

#############
# FUNCTIONS #
#############

# Run bash export on arguments passed to this function.
# Arguments are a space separated list of key=value
function load_env() {
  for val in ${@}; do
    key=$(echo ${val} | cut -d '=' -f 1)
    value=$(echo ${val} | cut -d '=' -f 2)
    export ${key}=${value}
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


# This function is called on Linux signals: INT ERR EXIT
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

  docker run --rm -d ${image} /bin/bash -c "while true; do sleep 1; done"
}


# Destroy the Docker container used for testing
function container_down() {
  local container_id=${1}

  [ ! -z "${container_id+x}" ] && (echo "Cleanup docker containers" && docker kill ${container_id})
}


# Pull docker image before launching tests when running in Kaniko mode
function pull_image() {
  local image=${1}

  docker pull ${image}
}


# Prepare inputs arguments for Inspec
function split_test_inputs() {
  # If no inputs are given we return ""
  # ${var+x} is a parameter expansion which evaluates to nothing if var is unset, and substitutes the string x otherwise
  # See: https://stackoverflow.com/a/13864829/616095
  if [ -z "${@+x}" ]; then
    echo ""
  else
    out="--input"

    for val in ${@}; do
      out="${out} ${val}"
    done

    echo ${out}
  fi
}


# Call Inspec
function run_spec() {
  local test_mode=${1}
  local container_id=${2}
  local test_inputs=$(split_test_inputs ${3})

  local args="--chef-license accept-silent --no-create-lockfile --show-progress"

  # If <project>/.inspecrc file exists in the project read it
  inspec_args_override="$(pwd)/.inspecrc"

  if [ -f "${inspec_args_override}" ]; then
    while read line; do
      args="${args} ${line}"
    done <"${inspec_args_override}"
  fi

  case "${test_mode}" in
    donico)
      local dir=/app/test/

      # We use Docker-in-Docker to run Inspec so mount the Docker socket
      # Mount the current app to test within Inspec container
      # Launch Inspec
      docker run \
        --rm \
        --mount type=bind,source="$(pwd)",target=/app \
        --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
        ${INSPEC_IMAGE} \
        inspec exec ${dir} -t docker://${container_id} ${args} ${test_inputs}
    ;;

    *)
      echo "Unknow test mode: ${test_mode}"
      exit 1
    ;;
  esac
}
