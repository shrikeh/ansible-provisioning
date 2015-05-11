#!/usr/bin/env bash

function _echo() {
  echo -e "\033[1m\n${1}\n\033[0m";
  tput sgr0;
}

# Get the prereqs for setting up a virtualenv
function _get_virtualenv() {
  _echo 'Updating pip';
  pip install --upgrade pip;

  _echo 'Installing virtualenv';
  pip install --upgrade virtualenv virtualenvwrapper;
}

# Start and run the virtualenv
function _start_venv() {
  local VENV=${1};

  echo "Creating virtualenv ${VENV}";
  mkvirtualenv "${VENV}";
  workon "${VENV}";
}

# Read through the roles file and put roles in
# ${GALAXY_ROLES_PATH}

function _get_ansible_galaxy_roles() {
  local GALAXY_ROLES_FILE=${1};
  local GALAXY_ROLES_PATH=${2};

  _echo 'Installing ansible roles from Galaxy';
  mkdir -p "${GALAXY_ROLES_PATH}";
  ansible-galaxy install \
    -r "${GALAXY_ROLES_FILE}" \
    -p "${GALAXY_ROLES_PATH}" \
    --force \
  ;
}

function _get_pip_requirements() {
  local REQUIREMENTS_FILE=${1};
  _echo 'Installing module requirements via pip';
  pip install -r "${REQUIREMENTS_FILE}";
}

# Runs the playbook itself

function _run_playbook() {
  local INVENTORY_FILE="${2}";
  local PLAYBOOK_PATH="${3}";
  local PROVISION_HOSTNAME="${4}";
  local VAULT_PASSWORD_FILE="${5}";

  _echo "Running playbook ${PLAYBOOK_PATH}";

  ( export ANSIBLE_ROLES_PATH=${1}; \
    export ANSIBLE_HOST_KEY_CHECKING='no'; \
    ansible-playbook -i "${INVENTORY_FILE}" \
      -vvvv \
      --user="${REMOTE_USER}" \
      --vault-password-file  "${VAULT_PASSWORD_FILE}"\
      "${PLAYBOOK_PATH}" \
  );
}

function provision_box() {

  local ANSIBLE_ROLES_FILE='requirements.yml';
  local ANSIBLE_ROLES_PATH='./galaxy'
  local REMOTE_USER='root';
  local REQUIREMENTS_PIP_FILE='./requirements.pip.txt';
  local INVENTORY_FILE='./inventory.sample';
  local PLAYBOOK_PATH='./provision.yml';
  local ANSIBLE_VENV='ansible-provision';

  local ANSIBLE_VAULT_PASSWORD_FILE=~/.provision_vault_password
  local SKIP_VENV=false;

  local -a ARGV=("${!1}");

  while [[ ${#} > 0 ]]; do
    key="${1}"
    case $key in
      -h|--host)
        local PROVISION_HOSTNAME="${2}";
      shift
      ;;
      -i|--inventory)
        INVENTORY_FILE="${2}";
      shift
      ;;
      -u|--user)
        REMOTE_USER="${2}";
      shift
      ;;
      --skipvenv)
       SKIP_VENV=true;
      shift
      ;;
      -p|--playbook)
        PLAYBOOK_PATH="${2}";
      shift
      ;;
      --rfile)
        ANSIBLE_ROLES_FILE="${2}";
      shift
      ;;
      --rpath)
        ANSIBLE_ROLES_PATH="${2}";
      shift
      ;;
      --venv)
        ANSIBLE_VENV="${2}";
      shift
      ;;
      -v|--vaultpassword)
        ANSIBLE_VAULT_PASSWORD_FILE="${2}";
      shift
      ;;
      --pfile)
        REQUIREMENTS_PIP_FILE="${2}";
      shift
      ;;
      --default)
        DEFAULT=YES
      shift
      ;;
      *)
              # unknown option
      ;;
  esac
    shift
  done

  # Make sure we have virtualenv
    _get_virtualenv;

  # Start it
  _start_venv "${ANSIBLE_VENV}";

  # Install all the virtualenv requirements
  _get_pip_requirements "${REQUIREMENTS_PIP_FILE}";

  # Get the galaxy roles and install them
  _get_ansible_galaxy_roles "${ANSIBLE_ROLES_FILE}" "${ANSIBLE_ROLES_PATH}";

  _run_playbook \
    "${ANSIBLE_ROLES_PATH}" \
    "${INVENTORY_FILE}" \
    "${PLAYBOOK_PATH}" \
    "${PROVISION_HOSTNAME}" \
    "${ANSIBLE_VAULT_PASSWORD_FILE}" \
    ;

  _echo 'Deactivating virtual env';
  deactivate;
}

provision_box "${@}"
