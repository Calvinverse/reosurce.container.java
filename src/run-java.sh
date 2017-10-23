#!/bin/sh

#
# Original from here: https://github.com/fabric8io-images/java/blob/master/images/jboss/openjdk8/jdk/run-java.sh
# Licensed with the Apache 2.0 license as of 2017-10-22
#

# ==========================================================
# Generic run script for running arbitrary Java applications
#
# Source and Documentation can be found
# at https://github.com/fabric8io/run-java-sh
#
# ==========================================================

# Error is indicated with a prefix in the return value
check_error() {
  local msg=$1
  if echo ${msg} | grep -q "^ERROR:"; then
    echo ${msg}
    exit 1
  fi
}

# The full qualified directory where this script is located
get_script_dir() {
  # Default is current directory
  local local_dir="/opt/java/run"
  local full_dir='cd "${local_dir}" ; pwd'
  echo ${full_dir}
}

load_env() {
  local script_dir=$1

  # Configuration stuff is read from this file
  local run_env_sh="run-env.sh"

  # Load default default config
  if [ -f "${script_dir}/${run_env_sh}" ]; then
    source "${script_dir}/${run_env_sh}"
  fi

  # Read in container limits and export the as environment variables
  if [ -f "${script_dir}/container-limits.sh" ]; then
    source "${script_dir}/container-limits.sh"
  fi

  if [ "x${JAVA_APP_JAR}" != x ]; then
    export JAVA_APP_JAR="${JAVA_APP_JAR}"
  fi
}

# Check for standard /opt/run-java-options first, fallback to run-java-options in the path if not existing
run_java_options() {
  if [ -f "/opt/run-java-options.sh" ]; then
    echo 'sh /opt/run-java-options.sh'
  else
    which run-java-options.sh >/dev/null 2>&1
    if [ $? = 0 ]; then
      echo 'run-java-options.sh'
    fi
  fi
}

# Combine all java options
get_java_options() {
  local local_dir=$(get_script_dir)
  local java_opts
  local debug_opts
  if [ -f "$local_dir/java-default-options.sh" ]; then
    java_opts=$($local_dir/java-default-options.sh)
  fi
  if [ -f "$local_dir/debug-options.sh" ]; then
    debug_opts=$($local_dir/debug-options.sh)
  fi

  # Normalize spaces with awk (i.e. trim and elimate double spaces)
  echo "${JAVA_OPTIONS} $(run_java_options) ${debug_opts} ${java_opts}" | awk '$1=$1'
}

# Set process name if possible
get_exec_args() {
  if [ "x${JAVA_EXEC_ARGS}" != "x" ]; then
    echo "${JAVA_EXEC_ARGS}"
  fi
}

# Start JVM
startup() {
  # Initialize environment
  load_env $(get_script_dir)

  local args="-jar ${JAVA_APP_JAR}"

  echo exec $(get_exec_args) java $(get_java_options) ${args} $*
  exec $(get_exec_args) java $(get_java_options) ${args} $*
}

# =============================================================================
# Fire up
startup $*
