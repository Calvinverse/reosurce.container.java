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

ceiling() {
  awk -vnumber="$1" -vdiv="$2" '
    function ceiling(x){
      return x%1 ? int(x)+1 : x
    }
    BEGIN{
      print ceiling(number/div)
    }
  '
}

# Based on the cgroup limits, figure out the max number of core we should utilize
core_limit() {
  cpu_period_file="/sys/fs/cgroup/cpu/cpu.cfs_period_us"
  cpu_quota_file="/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
  if [ -r "${cpu_period_file}" ]; then
    cpu_period="$(cat ${cpu_period_file})"

    if [ -r "${cpu_quota_file}" ]; then
      cpu_quota="$(cat ${cpu_quota_file})"
      # cfs_quota_us == -1 --> no restrictions
      if [ "x$cpu_quota" != "x-1" ]; then
        ceiling "$cpu_quota" "$cpu_period"
      fi
    fi
  fi
}

max_memory() {
  mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
  if [ -r "${mem_file}" ]; then
    max_mem="$(cat ${mem_file})"
    echo "${max_mem}"
  else
    echo "0"
  fi
}

# Start JVM
startup() {
  # Initialize environment
  local_dir="/opt/java/run"

  exec_args=""
  echo "'JAVA_EXEC_ARGS': ${JAVA_EXEC_ARGS} ..."
  if [ "x${JAVA_EXEC_ARGS}" != "x" ]; then
    exec_args="${JAVA_EXEC_ARGS}"
  fi

  echo "Determining core limits ..."
  java_core_limits=""
  container_core_limit="$(core_limit)"
  if [ "x$container_core_limit" != "x0" ]; then
    if [ "x$container_core_limit" != x ]; then
      echo "Setting core limits with ${container_core_limit} ..."
      java_core_limits="-XX:ParallelGCThreads=${container_core_limit} " \
          "-XX:ConcGCThreads=${container_core_limit} " \
          "-Djava.util.concurrent.ForkJoinPool.common.parallelism=${container_core_limit}"
    fi
  fi

  # Check whether -Xmx is already given in JAVA_OPTIONS. Then we dont
  # do anything here
  echo "Determining max memory usage ..."
  java_max_memory=""
  if echo "${JAVA_OPTIONS}" | grep -q -- "-Xmx"; then
    echo "-Xmx already specified"
  else
    # Check for the 'real memory size' and caluclate mx from a ratio
    # given (default is 50%)
    max_mem="$(max_memory)"
    if [ "x${max_mem}" != "x0" ]; then
      ratio=${JAVA_MAX_MEM_RATIO:-50}
      mx=$(echo "${max_mem} ${ratio} 1048576" | awk '{printf "%d\n" , ($1*$2)/(100*$3) + 0.5}')
      java_max_memory="-Xmx${mx}m"

      echo "Maximum memory for container set to ${max_mem}. Setting max memory for java to ${mx} Mb"
    fi
  fi

  java_diagnostics=""
  if [ "x$JAVA_DIAGNOSTICS" != "x" ]; then
    java_diagnostics="-XX:NativeMemoryTracking=summary -XX:+PrintGC -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+UnlockDiagnosticVMOptions"
  fi

  user_java_opts=""
  echo "Searching for 'run-java-options.sh' in /opt ..."
  if [ -f "/opt/run-java-options.sh" ]; then
    echo "Determining custom options ..."
    user_java_opts=$(/opt/run-java-options.sh)

    echo "Custom java options: ${user_java_opts}"
  fi

  user_java_jar_opts=""
  echo "Searching for 'run-java-jar-options.sh' in /opt ..."
  if [ -f "/opt/run-java-jar-options.sh" ]; then
    echo "Determining custom jar options ..."
    user_java_jar_opts=$(/opt/run-java-jar-options.sh)

    echo "Custom java jar options: ${user_java_jar_opts}"
  fi

  echo exec ${exec_args} java ${JAVA_OPTIONS} ${user_java_opts} ${java_max_memory} ${java_diagnostics} ${java_core_limits} -jar ${JAVA_APP_JAR} ${user_java_jar_opts}
  exec ${exec_args} java ${JAVA_OPTIONS} ${user_java_opts} ${java_max_memory} ${java_diagnostics} ${java_core_limits} -jar ${JAVA_APP_JAR} ${user_java_jar_opts}
}

# =============================================================================
# Fire up
startup $*
