#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202308281720-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.pro
# @@License          :  WTFPL
# @@ReadME           :  nginx.sh --help
# @@Copyright        :  Copyright: (c) 2023 Jason Hempstead, Casjays Developments
# @@Created          :  Monday, Aug 28, 2023 17:20 EDT
# @@File             :  nginx.sh
# @@Description      :
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  other/start-service
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
[ "$DEBUGGER" = "on" ] && echo "Enabling debugging" && set -o pipefail -x$DEBUGGER_OPTIONS || set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
printf '%s
' "# - - - Initializing nginx - - - #"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SERVICE_NAME="nginx"
SCRIPT_NAME="$(basename "$0" 2>/dev/null)"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
export PATH="/usr/local/etc/docker/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run trap command on exit
trap 'retVal=$?;[ "$SERVICE_IS_RUNNING" != "true" ] && [ -f "$SERVICE_PID_FILE" ] && rm -Rf "$SERVICE_PID_FILE";exit $retVal' SIGINT SIGTERM EXIT
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import the functions file
if [ -f "/usr/local/etc/docker/functions/entrypoint.sh" ]; then
  . "/usr/local/etc/docker/functions/entrypoint.sh"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# import variables
for set_env in "/root/env.sh" "/usr/local/etc/docker/env"/*.sh "/config/env"/*.sh; do
  [ -f "$set_env" ] && . "$set_env"
done
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Run any pre-execution checks
__run_pre_execute_checks() {
  local exitStatus=0

  true
  exitStatus=$?
  if [ $exitStatus -ne 0 ]; then
    echo "The pre-execution check has failed"
    exit ${exitStatus:-20}
  fi
  return $exitStatus
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Custom functions

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Script to execute
START_SCRIPT="/usr/local/etc/docker/exec/$SERVICE_NAME"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Reset environment before executing service
RESET_ENV="yes"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Show message before execute
PRE_EXEC_MESSAGE=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the database directory
DATABASE_DIR="${DATABASE_DIR_NGINX:-/data/db/sqlite}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set webroot
WWW_ROOT_DIR="/usr/local/share/httpd/default"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Default predefined variables
DATA_DIR="/data/nginx"   # set data directory
CONF_DIR="/config/nginx" # set config directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set the containers etc directory
ETC_DIR="/etc/nginx"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
TMP_DIR="/tmp/nginx"
RUN_DIR="/run/nginx"       # set scripts pid dir
LOG_DIR="/data/logs/nginx" # set log directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the working dir
WORK_DIR="" # set working directory
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Where to save passwords to
ROOT_FILE_PREFIX="/config/secure/auth/root" # directory to save username/password for root user
USER_FILE_PREFIX="/config/secure/auth/user" # directory to save username/password for normal user
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# root/admin user info password/random]
root_user_name="${NGINX_ROOT_USER_NAME:-}" # root user name
root_user_pass="${NGINX_ROOT_PASS_WORD:-}" # root user password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Normal user info [password/random]
user_name="${NGINX_USER_NAME:-}"      # normal user name
user_pass="${NGINX_USER_PASS_WORD:-}" # normal user password
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Overwrite variables from files
__file_exists_with_content "${USER_FILE_PREFIX}/${SERVICE_NAME}_name" && user_name="$(<"${USER_FILE_PREFIX}/${SERVICE_NAME}_name")"
__file_exists_with_content "${USER_FILE_PREFIX}/${SERVICE_NAME}_pass" && user_pass="$(<"${USER_FILE_PREFIX}/${SERVICE_NAME}_pass")"
__file_exists_with_content "${ROOT_FILE_PREFIX}/${SERVICE_NAME}_name" && root_user_name="$(<"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_name")"
__file_exists_with_content "${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass" && root_user_pass="$(<"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# port which service is listening on
SERVICE_PORT="80"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User to use to launch service - IE: postgres
RUNAS_USER="root" # normally root
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# User and group in which the service switches to - IE: nginx,apache,mysql,postgres
SERVICE_USER="nginx"  # execute command as another user
SERVICE_GROUP="nginx" # Set the service group
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set user and group ID
SERVICE_UID="0" # set the user id
SERVICE_GID="0" # set the group id
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# execute command variables - keep single quotes variables will be expanded later
EXEC_CMD_BIN='nginx'                   # command to execute
EXEC_CMD_ARGS='-c $ETC_DIR/nginx.conf' # command arguments
EXEC_PRE_SCRIPT=''                     # execute script before
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Is this service a web server
IS_WEB_SERVER="yes"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Is this service a database server
IS_DATABASE_SERVICE="no"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Load variables from config
[ -f "$CONF_DIR/env/nginx.sh" ] && . "$CONF_DIR/env/nginx.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional predefined variables
if [ -d "/app" ]; then
  __is_dir_empty "/app" && __file_copy "$WWW_ROOT_DIR/." "/app/"
  rm -Rf "$WWW_ROOT_DIR" && ln -sf "/app" "$WWW_ROOT_DIR"
  WWW_ROOT_DIR="/app" WORK_DIR="/app"
elif [ -d "/data/htdocs" ]; then
  __is_dir_empty "/data/htdocs" && __file_copy "$WWW_ROOT_DIR/." "/data/htdocs/"
  rm -Rf "$WWW_ROOT_DIR" && ln -sf "/app" "$WWW_ROOT_DIR"
  WWW_ROOT_DIR="/data/htdocs" WORK_DIR="/data/htdocs"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional variables
RANDOM_APP_HASH="$(__random_password 24))"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Specifiy custom directories to be created
ADD_APPLICATION_FILES=""
ADD_APPLICATION_DIRS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPLICATION_FILES="$LOG_DIR/nginx.log"
APPLICATION_DIRS="$RUN_DIR $ETC_DIR $CONF_DIR $LOG_DIR $TMP_DIR"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Additional config dirs - will be Copied to /etc/$name
ADDITIONAL_CONFIG_DIRS=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# define variables that need to be loaded into the service - escape quotes - var=\"value\",other=\"test\"
CMD_ENV=""
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Overwrite based on file/directory

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to update config files - IE: change port
__update_conf_files() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname

  # CD into temp to bybass any permission errors
  cd /tmp || false # lets keep shellcheck happy by adding false

  # delete files
  #__rm ""

  # Initialize templates
  if [ -e "$DEFAULT_DATA_DIR/$SERVICE_NAME" ]; then
    if [ -d "$DEFAULT_DATA_DIR/$SERVICE_NAME" ]; then
      mkdir -p "$DATA_DIR"
      __copy_templates "$DEFAULT_DATA_DIR/$SERVICE_NAME/." "$DATA_DIR/"
    else
      __copy_templates "$DEFAULT_DATA_DIR/$SERVICE_NAME" "$DATA_DIR"
    fi
  fi
  if [ -e "$DEFAULT_CONF_DIR/$SERVICE_NAME" ]; then
    if [ -d "$DEFAULT_CONF_DIR/$SERVICE_NAME" ]; then
      mkdir -p "$CONF_DIR"
      __copy_templates "$DEFAULT_CONF_DIR/$SERVICE_NAME/." "$CONF_DIR/"
    else
      __copy_templates "$DEFAULT_CONF_DIR/$SERVICE_NAME" "$CONF_DIR"
    fi
  elif [ -e "$ETC_DIR" ]; then
    if [ -d "$ETC_DIR" ]; then
      mkdir -p "$CONF_DIR"
      __copy_templates "$ETC_DIR/." "$CONF_DIR/"
    else
      __copy_templates "$ETC_DIR" "$CONF_DIR"
    fi
  fi
  [ -d "/usr/local/etc/docker/exec" ] || mkdir -p "/usr/local/etc/docker/exec"

  # define actions

  # create default directories
  for filedirs in $ADD_APPLICATION_DIRS $APPLICATION_DIRS; do
    if [ -n "$filedirs" ] && [ ! -d "$filedirs" ]; then
      (
        echo "Creating directory $filedirs with permissions 777"
        mkdir -p "$filedirs" && chmod -Rf 777 "$filedirs"
      ) |& tee -a "$LOG_DIR/init.txt" &>/dev/null
    fi
  done
  # create default files
  for application_files in $ADD_APPLICATION_FILES $APPLICATION_FILES; do
    if [ -n "$application_files" ] && [ ! -e "$application_files" ]; then
      (
        echo "Creating file $application_files with permissions 777"
        touch "$application_files" && chmod -Rf 777 "$application_files"
      ) |& tee -a "$LOG_DIR/init.txt" &>/dev/null
    fi
  done
  # create directories if variable is yes"
  if [ "$IS_WEB_SERVER" = "yes" ]; then
    APPLICATION_DIRS="$APPLICATION_DIRS $WWW_ROOT_DIR"
    if __is_dir_empty "$WWW_ROOT_DIR" || [ ! -d "$WWW_ROOT_DIR" ]; then
      (echo "Creating directory $WWW_ROOT_DIR with permissions 777" && mkdir -p "$WWW_ROOT_DIR" && chmod -f 777 "$WWW_ROOT_DIR") |& tee -a "$LOG_DIR/init.txt" &>/dev/null
    fi
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Copy html files
    __initialize_www_root
    __initialize_web_health "$WWW_ROOT_DIR"
  fi
  if [ "$IS_DATABASE_SERVICE" = "yes" ]; then
    APPLICATION_DIRS="$APPLICATION_DIRS $DATABASE_DIR"
    if __is_dir_empty "$DATABASE_DIR" || [ ! -d "$DATABASE_DIR" ]; then
      (echo "Creating directory $DATABASE_DIR with permissions 777" && mkdir -p "$DATABASE_DIR" && chmod -f 777 "$DATABASE_DIR") |& tee -a "$LOG_DIR/init.txt" &>/dev/null
    fi
  fi
  # replace variables
  # __replace "" "" "$CONF_DIR/nginx.conf"
  # replace variables recursively
  #  __find_replace "" "" "$CONF_DIR"

  # execute if directory is empty
  #__is_dir_empty "" && true || false

  # custom commands

  # unset unneeded variables
  unset application_files filedirs

  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# function to run before executing
__pre_execute() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname

  # define commands

  # execute if directories is empty
  #__is_dir_empty "" && true || false

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # create user if needed
  __create_service_user "$SERVICE_USER" "$SERVICE_GROUP" "${WORK_DIR:-/home/$SERVICE_USER}" "${SERVICE_UID:-3000}" "${SERVICE_GID:-3000}"

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Modify user if needed
  __set_user_group_id $SERVICE_USER ${SERVICE_UID:-3000} ${SERVICE_GID:-3000}

  # Run Custom command

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copy /config to /etc
  for config_2_etc in $CONF_DIR $ADDITIONAL_CONFIG_DIRS; do
    __initialize_system_etc "$config_2_etc" |& tee -a "$LOG_DIR/init.txt" &>/dev/null |& tee -a "$LOG_DIR/init.txt" &>/dev/null
  done
  unset config_2_etc ADDITIONAL_CONFIG_DIRS
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # set user on files/folders
  if [ -n "$SERVICE_USER" ] && [ "$SERVICE_USER" != "root" ]; then
    if grep -sq "^$SERVICE_USER:" "/etc/passwd"; then
      for permissions in $ADD_APPLICATION_DIRS $APPLICATION_DIRS; do
        if [ -n "$permissions" ] && [ -e "$permissions" ]; then
          (chown -Rf $SERVICE_USER:${SERVICE_GROUP:-$SERVICE_USER} "$permissions" && echo "changed ownership on $permissions to user:$SERVICE_USER and group:${SERVICE_GROUP:-$SERVICE_USER}") |& tee -a "$LOG_DIR/init.txt" &>/dev/null
        fi
      done
    fi
  fi
  if [ -n "$SERVICE_GROUP" ] && [ "$SERVICE_GROUP" != "root" ]; then
    if grep -sq "^$SERVICE_GROUP:" "/etc/group"; then
      for permissions in $ADD_APPLICATION_DIRS $APPLICATION_DIRS; do
        if [ -n "$permissions" ] && [ -e "$permissions" ]; then
          (chgrp -Rf $SERVICE_GROUP "$permissions" && echo "changed group ownership on $permissions to group $SERVICE_GROUP") |& tee -a "$LOG_DIR/init.txt" &>/dev/null
        fi
      done
    fi
  fi

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Replace the applications user and group
  __find_replace "REPLACE_WWW_USER" "${SERVICE_USER:-root}" "$ETC_DIR"
  __find_replace "REPLACE_WWW_GROUP" "${SERVICE_GROUP:-${SERVICE_USER:-root}}" "$ETC_DIR"
  __find_replace "REPLACE_APP_USER" "${SERVICE_USER:-root}" "$ETC_DIR"
  __find_replace "REPLACE_APP_GROUP" "${SERVICE_GROUP:-${SERVICE_USER:-root}}" "$ETC_DIR"
  # Replace variables
  __initialize_replace_variables "$ETC_DIR"
  __initialize_replace_variables "$CONF_DIR"
  __initialize_replace_variables "$WWW_ROOT_DIR"
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Run checks
  __run_pre_execute_checks

  # unset unneeded variables
  unset filesperms filename
  # Lets wait a few seconds before continuing
  sleep 10
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# function to run after executing
__post_execute() {
  local exitCode=0                                               # default exit code
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname

  sleep 60                     # how long to wait before executing
  echo "Running post commands" # message
  # execute commands
  (
    sleep 20
    true
  ) |& tee -a "$LOG_DIR/init.txt" &>/dev/null &
  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to update config files - IE: change port
__pre_message() {
  local exitCode=0
  [ -n "$user_name" ] && echo "username:               $user_name" && echo "$user_name" >"${USER_FILE_PREFIX}/${SERVICE_NAME}_name"
  [ -n "$user_pass" ] && __printf_space "40" "password:" "saved to ${USER_FILE_PREFIX}/${SERVICE_NAME}_pass" && echo "$user_pass" >"${USER_FILE_PREFIX}/${SERVICE_NAME}_pass"
  [ -n "$root_user_name" ] && echo "root username:     $root_user_name" && echo "$root_user_name" >"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_name"
  [ -n "$root_user_pass" ] && __printf_space "40" "root password:" "saved to ${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass" && echo "$root_user_pass" >"${ROOT_FILE_PREFIX}/${SERVICE_NAME}_pass"

  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# use this function to setup ssl support
__update_ssl_conf() {
  local exitCode=0
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname

  return $exitCode
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__create_service_env() {
  cat <<EOF | tee "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" &>/dev/null
#ENV_SERVICE_UID="${ENV_UID:-${ENV_SERVICE_UID:-$SERVICE_UID}}"      # Set UID
#ENV_SERVICE_GID="${ENV_GID:-${ENV_SERVICE_GID:-$SERVICE_GID}}"      # Set GID
#ENV_RUNAS_USER="${ENV_RUNAS_USER:-$RUNAS_USER}"                     # normally root
#ENV_WORKDIR="${ENV_WORK_DIR:-$WORK_DIR}"                            # change to directory
#ENV_WWW_DIR="${ENV_WWW_ROOT_DIR:-$WWW_ROOT_DIR}"                    # set default web dir
#ENV_ETC_DIR="${ENV_ETC_DIR:-$ETC_DIR}"                              # set default etc dir
#ENV_DATA_DIR="${ENV_DATA_DIR:-$DATA_DIR}"                           # set default data dir
#ENV_CONF_DIR="${ENV_CONF_DIR:-$CONF_DIR}"                           # set default config dir
#ENV_DATABASE_DIR="${ENV_DATABASE_DIR:-$DATABASE_DIR}"               # set database dir
#ENV_SERVICE_USER="${ENV_SERVICE_USER:-$SERVICE_USER}"               # execute command as another user
#ENV_SERVICE_PORT="${ENV_SERVICE_PORT:-$SERVICE_PORT}"               # port which service is listening on
#ENV_EXEC_PRE_SCRIPT="${ENV_EXEC_PRE_SCRIPT:-$EXEC_PRE_SCRIPT}"      # execute before commands
#ENV_EXEC_CMD_BIN="${ENV_EXEC_CMD_BIN:-$EXEC_CMD_BIN}"               # command to execute
#ENV_EXEC_CMD_ARGS="${ENV_EXEC_CMD_ARGS:-$EXEC_CMD_ARGS}"            # command arguments
#ENV_EXEC_CMD_NAME="$(basename "$EXEC_CMD_BIN")"                     # set the binary name
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# root/admin user info [password/random]
#ENV_ROOT_USER_NAME="${ENV_ROOT_USER_NAME:-$NGINX_ROOT_USER_NAME}"   # root user name
#ENV_ROOT_USER_PASS="${ENV_ROOT_USER_NAME:-$NGINX_ROOT_PASS_WORD}"   # root user password
#root_user_name="${ENV_ROOT_USER_NAME:-$root_user_name}"                              #
#root_user_pass="${ENV_ROOT_USER_PASS:-$root_user_pass}"                              #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#Normal user info [password/random]
#ENV_USER_NAME="${ENV_USER_NAME:-$NGINX_USER_NAME}"                  #
#ENV_USER_PASS="${ENV_USER_PASS:-$NGINX_USER_PASS_WORD}"             #
#user_name="${ENV_USER_NAME:-$user_name}"                                             # normal user name
#user_pass="${ENV_USER_PASS:-$user_pass}"                                             # normal user password

EOF
  __file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" || return 1
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# script to start server
__run_start_script() {
  local runExitCode=0
  local workdir="$(eval echo "${WORK_DIR:-}")"                   # expand variables
  local cmd="$(eval echo "${EXEC_CMD_BIN:-}")"                   # expand variables
  local args="$(eval echo "${EXEC_CMD_ARGS:-}")"                 # expand variables
  local name="$(eval echo "${EXEC_CMD_NAME:-}")"                 # expand variables
  local pre="$(eval echo "${EXEC_PRE_SCRIPT:-}")"                # expand variables
  local extra_env="$(eval echo "${CMD_ENV//,/ }")"               # expand variables
  local lc_type="$(eval echo "${LANG:-${LC_ALL:-$LC_CTYPE}}")"   # expand variables
  local home="$(eval echo "${workdir//\/root/\/tmp\/docker}")"   # expand variables
  local path="$(eval echo "$PATH")"                              # expand variables
  local message="$(eval echo "")"                                # expand variables
  local sysname="${SERVER_NAME:-${FULL_DOMAIN_NAME:-$HOSTNAME}}" # set hostname
  [ -f "$CONF_DIR/$SERVICE_NAME.exec_cmd.sh" ] && . "$CONF_DIR/$SERVICE_NAME.exec_cmd.sh"
  if [ -z "$cmd" ]; then
    __post_execute 2>"/dev/stderr" | tee -p -a "$LOG_DIR/init.txt" >/dev/null
    retVal=$?
    echo "Initializing $SCRIPT_NAME has completed"
    exit $retVal
  else
    # ensure the command exists
    if [ ! -x "$cmd" ]; then
      echo "$name is not a valid executable"
      return 2
    fi
    # set working directories
    [ -z "$home" ] && home="${workdir:-/tmp/docker}"
    [ "$home" = "/root" ] && home="/tmp/docker"
    [ "$home" = "$workdir" ] && workdir=""
    # create needed directories
    [ -n "$home" ] && { [ -d "$home" ] || { mkdir -p "$home" && chown -Rf $SERVICE_USER:$SERVICE_GROUP "$home"; }; }
    [ -n "$workdir" ] && { [ -d "$workdir" ] || { mkdir -p "$workdir" && chown -Rf $SERVICE_USER:$SERVICE_GROUP "$workdir"; }; }

    [ "$user" != "root " ] && [ -d "$home" ] && chmod -f 777 "$home"
    [ "$user" != "root " ] && [ -d "$workdir" ] && chmod -f 777 "$workdir"
    # check and exit if already running
    if __proc_check "$name" || __proc_check "$cmd"; then
      echo "$name is already running" >&2
      return 0
    else
      # cd to dir
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      __cd "${workdir:-$home}"
      # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      # show message if env exists
      if [ -n "$cmd" ]; then
        [ -n "$SERVICE_USER" ] && echo "Setting up $cmd to run as $SERVICE_USER" || SERVICE_USER="root"
        [ -n "$SERVICE_PORT" ] && echo "$name will be running on $SERVICE_PORT" || SERVICE_PORT=""
      fi
      if [ -n "$pre" ] && [ -n "$(command -v "$pre" 2>/dev/null)" ]; then
        export cmd_exec="$pre $cmd $args"
        message="Starting service: $name $args through $pre $message"
      else
        export cmd_exec="$cmd $args"
        message="Starting service: $name $args $message"
      fi
      [ -f "$START_SCRIPT" ] && printf '#!/usr/bin/env sh\n# %s\n%s\n' "$message" "$cmd_exec &" >"$START_SCRIPT"
      [ -f "$START_SCRIPT" ] && chmod 755 -Rf "$START_SCRIPT"
      [ -n "$su_exec" ] && echo "using $su_exec"
      echo "$message"
      su_cmd touch "$SERVICE_PID_FILE"
      __post_execute |& tee -p -a "$LOG_DIR/init.txt" &>/dev/null &
      if [ "$RESET_ENV" = "yes" ]; then
        env_command="$(eval echo "env -i HOME=\"$home\" LC_CTYPE=\"$lc_type\" PATH=\"$path\" HOSTNAME=\"$sysname\" USER=\"${SERVICE_USER:-$RUNAS_USER}\" $extra_env")"
        echo "$env_command"
        su_cmd $env_command sh -c "$START_SCRIPT" || eval $env_command sh -c "$START_SCRIPT"
        runExitCode=$?
      else
        su_cmd "$START_SCRIPT" || eval "$START_SCRIPT"
        runExitCode=$?
      fi
      return $runExitCode
    fi
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# username and password actions
__run_secure_function() {
  if [ -n "$user_name" ] || [ -n "$user_pass" ]; then
    for filesperms in "${USER_FILE_PREFIX}"/*; do
      if [ -e "$filesperms" ]; then
        chmod -Rf 600 "$filesperms"
        chown -Rf $SERVICE_USER:$SERVICE_USER "$filesperms"
      fi
    done |& tee -a "$LOG_DIR/init.txt" &>/dev/null
  fi
  if [ -n "$root_user_name" ] || [ -n "$root_user_pass" ]; then
    for filesperms in "${ROOT_FILE_PREFIX}"/*; do
      if [ -e "$filesperms" ]; then
        chmod -Rf 600 "$filesperms"
        chown -Rf $SERVICE_USER:$SERVICE_USER "$filesperms"
      fi
    done |& tee -a "$LOG_DIR/init.txt" &>/dev/null
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# simple cd function
__cd() { mkdir -p "$1" && builtin cd "$1" || exit 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# process check functions
__pcheck() { [ -n "$(type -P pgrep 2>/dev/null)" ] && pgrep -x "$1" &>/dev/null && return 0 || return 10; }
__pgrep() { __pcheck "${1:-$EXEC_CMD_BIN}" || __ps aux 2>/dev/null | grep -Fw " ${1:-$EXEC_CMD_BIN}" | grep -qv ' grep' | grep '^' && return 0 || return 10; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# check if process is already running
__proc_check() {
  cmd_bin="$(type -P "${1:-$EXEC_CMD_BIN}")"
  cmd_name="$(basename "${cmd_bin:-$EXEC_CMD_NAME}")"
  if __pgrep "$cmd_bin" || __pgrep "$cmd_name"; then
    SERVICE_IS_RUNNING="true"
    touch "$SERVICE_PID_FILE"
    echo "$cmd_name is already running"
    return 0
  else
    return 1
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow ENV_ variable - Import env file
__file_exists_with_content "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
SERVICE_EXIT_CODE=0                                           # default exit code
SERVICE_USER="${ENV_SERVICE_USER:-$SERVICE_USER}"             # execute command as another user
SERVICE_UID="${ENV_UID:-${ENV_SERVICE_UID:-$SERVICE_UID}}"    # Set UID
SERVICE_GID="${ENV_GID:-${ENV_SERVICE_GID:-$SERVICE_GID}}"    # Set GID
SERVICE_PORT="${ENV_SERVICE_PORT:-$SERVICE_PORT}"             # port which service is listening on
RUNAS_USER="${ENV_RUNAS_USER:-$RUNAS_USER}"                   # normally root
WORK_DIR="${ENV_WORK_DIR:-$WORK_DIR}"                         # change to directory
WWW_ROOT_DIR="${ENV_WWW_ROOT_DIR:-$WWW_ROOT_DIR}"             # set default web dir
ETC_DIR="${ENV_ETC_DIR:-$ETC_DIR}"                            # set default etc dir
DATA_DIR="${ENV_DATA_DIR:-$DATA_DIR}"                         # set default data dir
CONF_DIR="${ENV_CONF_DIR:-$CONF_DIR}"                         # set default config dir
DATABASE_DIR="${ENV_DATABASE_DIR:-$DATABASE_DIR}"             # set database dir
PRE_EXEC_MESSAGE="${ENV_PRE_EXEC_MESSAGE:-$PRE_EXEC_MESSAGE}" # Show message before execute
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# application specific
EXEC_PRE_SCRIPT="${ENV_EXEC_PRE_SCRIPT:-$EXEC_PRE_SCRIPT}"                 # Pre
EXEC_CMD_BIN="${ENV_EXEC_CMD_BIN:-$EXEC_CMD_BIN}"                          # command to execute
EXEC_CMD_NAME="$(basename "$EXEC_CMD_BIN")"                                # set the binary name
SERVICE_PID_FILE="/run/init.d/$EXEC_CMD_NAME.pid"                          # set the pid file location
EXEC_CMD_ARGS="${ENV_EXEC_CMD_ARGS:-$EXEC_CMD_ARGS}"                       # command arguments
SERVICE_PID_NUMBER="$(__pgrep)"                                            # check if running
EXEC_CMD_BIN="$(type -P "$EXEC_CMD_BIN" || echo "$EXEC_CMD_BIN")"          # set full path
EXEC_PRE_SCRIPT="$(type -P "$EXEC_PRE_SCRIPT" || echo "$EXEC_PRE_SCRIPT")" # set full path
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# create auth directories
[ -n "$USER_FILE_PREFIX" ] && { [ -d "$USER_FILE_PREFIX" ] || mkdir -p "$USER_FILE_PREFIX"; }
[ -n "$ROOT_FILE_PREFIX" ] && { [ -d "$ROOT_FILE_PREFIX" ] || mkdir -p "$ROOT_FILE_PREFIX"; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
[ "$IS_WEB_SERVER" = "yes" ] && RESET_ENV="yes"
[ "$IS_DATABASE_SERVICE" = "yes" ] && RESET_ENV="no"
[ -n "$RUNAS_USER" ] || RUNAS_USER="root"
[ -n "$SERVICE_USER" ] || SERVICE_USER="${RUNAS_USER:-root}"
[ -n "$SERVICE_GROUP" ] || SERVICE_GROUP="${RUNAS_USER:-root}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow per init script usernames and passwords
__file_exists_with_content "$ETC_DIR/auth/user/name" && user_name="$(<"$ETC_DIR/auth/user/name")"
__file_exists_with_content "$ETC_DIR/auth/user/pass" && user_pass="$(<"$ETC_DIR/auth/user/pass")"
__file_exists_with_content "$ETC_DIR/auth/root/name" && root_user_name="$(<"$ETC_DIR/auth/root/name")"
__file_exists_with_content "$ETC_DIR/auth/root/pass" && root_user_pass="$(<"$ETC_DIR/auth/root/pass")"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow setting initial users and passwords via environment
user_name="${ENV_USER_NAME:-$user_name}"
user_pass="${ENV_USER_PASS:-$user_pass}"
root_user_name="${ENV_ROOT_USER_NAME:-$root_user_name}"
root_user_pass="${ENV_ROOT_USER_PASS:-$root_user_pass}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Env vars from dockermgr script
SERVICE_UID="${ENV_PUID:-${PUID:-$SERVICE_UID}}"
SERVICE_GID="${ENV_PGID:-${PGID:-$SERVICE_GID}}"
EMAIL_RELAY="${ENV_EMAIL_RELAY:-$EMAIL_RELAY}"
EMAIL_ADMIN="${ENV_EMAIL_ADMIN:-$EMAIL_ADMIN}"
EMAIL_DOMAIN="${ENV_EMAIL_DOMAIN:-$EMAIL_DOMAIN}"
SERVICE_PROTOCOL="${ENV_CONTAINER_PROTOCOL:-$CONTAINER_PROTOCOL}"
WWW_ROOT_DIR="${CONTAINER_HTML_ENV:-${ENV_WWW_ROOT_DIR:-$WWW_ROOT_DIR}}"
DATABASE_DIR="${ENV_DATABASE_DIR_CUSTOM:-${DATABASE_DIR_CUSTOM:-${DATABASE_DIR_SQLITE:-$DATABASE_DIR}}}"
user_name="${ENV_DATABASE_USER_NORMAL:-${DATABASE_USER_NORMAL:-${CONTAINER_ENV_USER_NAME:-$user_name}}}"
user_pass="${ENV_DATABASE_PASS_NORMAL:-${DATABASE_PASS_NORMAL:-${CONTAINER_ENV_PASS_NAME:-$user_pass}}}"
root_user_name="${ENV_DATABASE_USER_ROOT:-${DATABASE_USER_ROOT:-$root_user_name}}"
root_user_pass="${ENV_DATABASE_PASS_ROOT:-${DATABASE_PASS_ROOT:-$root_user_pass}}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set password to random if variable is random
if [ "$user_pass" = "random" ]; then
  user_pass="$(__random_password)"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ "$root_user_pass" = "random" ]; then
  root_user_pass="$(__random_password)"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Allow variables via imports - Overwrite existing
[ -f "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh" ] && . "/config/env/${SERVICE_NAME:-$SCRIPT_NAME}.sh"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Only run check
if [ "$1" = "check" ]; then
  __proc_check "$EXEC_CMD_NAME" || __proc_check "$EXEC_CMD_BIN"
  exit $?
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# set switch user command
if [ "$RUNAS_USER" = "root" ]; then
  su_cmd() { eval "$@" || return 1; }
elif [ "$(builtin type -P gosu)" ]; then
  su_cmd() { gosu $RUNAS_USER "$@" || return 1; }
elif [ "$(builtin type -P runuser)" ]; then
  su_cmd() { runuser -u $RUNAS_USER "$@" || return 1; }
elif [ "$(builtin type -P sudo)" ]; then
  su_cmd() { sudo -u $RUNAS_USER "$@" || return 1; }
elif [ "$(builtin type -P su)" ]; then
  su_cmd() { su -s /bin/sh - $RUNAS_USER -c "$@" || return 1; }
else
  su_cmd() { echo "Can not switch to $RUNAS_USER: attempting to run as root" && eval "$@" || return 1; }
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Change to working directory
[ "$HOME" = "/root" ] && [ "$RUNAS_USER" != "root" ] && __cd "/tmp" && echo "Changed to $PWD"
[ "$HOME" = "/root" ] && [ "$SERVICE_USER" != "root" ] && __cd "/tmp" && echo "Changed to $PWD"
[ -n "$WORK_DIR" ] && [ -n "$EXEC_CMD_BIN" ] && __cd "$WORK_DIR" && echo "Changed to $PWD"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# show init message
__pre_message
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Initialize ssl
__update_ssl_conf
__update_ssl_certs
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Updating config files
__create_service_env
__update_conf_files
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# run the pre execute commands
[ -n "$PRE_EXEC_MESSAGE" ] && eval echo "$PRE_EXEC_MESSAGE"
__pre_execute
__run_secure_function
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
__run_start_script "$@" |& tee -a "/data/logs/entrypoint.log" &>/dev/null
if [ "$?" -ne 0 ] && [ -n "$EXEC_CMD_BIN" ]; then
  eval echo "Failed to execute: ${cmd_exec:-$EXEC_CMD_BIN $EXEC_CMD_ARGS}" |& tee -a "/data/logs/entrypoint.log" "$LOG_DIR/init.txt"
  rm -Rf "$SERVICE_PID_FILE"
  SERVICE_EXIT_CODE=10
  SERVICE_IS_RUNNING="false"
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $SERVICE_EXIT_CODE
