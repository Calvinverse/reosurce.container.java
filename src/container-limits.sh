#!/bin/sh

#
# Original from here: https://github.com/fabric8io-images/java/blob/master/images/jboss/openjdk8/jdk/container-limits
# Licensed with the Apache 2.0 license as of 2017-10-22
#

# Detected container limits
# If found these are exposed as the following environment variables:
#
# - CONTAINER_MAX_MEMORY
# - CONTAINER_CORE_LIMIT
#
# This script is meant to be sourced.

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
  local cpu_period_file="/sys/fs/cgroup/cpu/cpu.cfs_period_us"
  local cpu_quota_file="/sys/fs/cgroup/cpu/cpu.cfs_quota_us"
  if [ -r "${cpu_period_file}" ]; then
    local cpu_period="$(cat ${cpu_period_file})"

    if [ -r "${cpu_quota_file}" ]; then
      local cpu_quota="$(cat ${cpu_quota_file})"
      # cfs_quota_us == -1 --> no restrictions
      if [ "x$cpu_quota" != "x-1" ]; then
        ceiling "$cpu_quota" "$cpu_period"
      fi
    fi
  fi
}

max_memory() {
  # High number which is the max limit unit which memory is supposed to be
  # unbounded.
  local max_mem_unbounded="$(cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes)"
  local mem_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
  if [ -r "${mem_file}" ]; then
    local max_mem="$(cat ${mem_file})"
    if [ ${max_mem} -lt ${max_mem_unbounded} ]; then
      echo "${max_mem}"
    fi
  fi
}

limit="$(core_limit)"
if [ x$limit != x ]; then
   export CONTAINER_CORE_LIMIT="${limit}"
fi
unset limit

limit="$(max_memory)"
if [ x$limit != x ]; then
  export CONTAINER_MAX_MEMORY="$limit"
fi
unset limit
