#!/usr/bin/env bash

function _echo() {
  echo -e "\033[1m\n${1}\n\033[0m";
  tput sgr0;
}

function _get_ansible_plugins() {
  local ANSIBLE_ACTION_PLUGINS_DIR=${1};
  if [ ! -d "${ANSIBLE_ACTION_PLUGINS_DIR}" ]; then
    mkdir -p ${ANSIBLE_ACTION_PLUGINS_DIR};
    git clone https://github.com/jurgenhaas/ansible-plugin-serverdensity.git "${ANSIBLE_ACTION_PLUGINS_DIR}/server-density";
  fi
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
    --ignore-errors \
  ;
}

# Runs the playbook itself

function _run_playbook() {
  local INVENTORY_FILE="${3}";
  local PLAYBOOK_PATH="${4}";
  local PROVISION_HOSTNAME="${5}";
  local VAULT_PASSWORD_FILE="${6}";

  _echo "Running playbook ${PLAYBOOK_PATH} with inventory ${INVENTORY_FILE}";

  ( export ANSIBLE_ROLES_PATH=${1}; \
    export ANSIBLE_ACTION_PLUGINS=${2}; \
    export ANSIBLE_HOST_KEY_CHECKING='no'; \
    export RAX_USERNAME='leftfielddigital'; \
    export RAX_API_KEY='bbb3943746f0d83ec9102333c4a9c716'; \
    export RAX_REGION='DFW'; \
    ansible-playbook -i "${INVENTORY_FILE}" \
      --user="${REMOTE_USER}" \
      --vault-password-file  "${VAULT_PASSWORD_FILE}" \
      "${PLAYBOOK_PATH}" \
  );
}

function provision_box() {

  local ANSIBLE_ROLES_FILE='./ansible/requirements.yml';
  local ANSIBLE_ROLES_PATH='./ansible/galaxy';
  local ANSIBLE_ACTION_PLUGINS_PATH='./ansible/plugins/action_plugins';
  local REMOTE_USER='root';
  local REQUIREMENTS_PIP_FILE='./requirements.pip.txt';
  local INVENTORY_FILE='./inventory';
  local PLAYBOOK_PATH='./ansible/provision.yml';
  local ANSIBLE_VENV='venv';

  local ANSIBLE_VAULT_PASSWORD_FILE=~/.provision_vault_password;
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
        ANSIBLE_VAULT_PASSWORD="${2}";
      shift
      ;;
      --vfile)
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

  # Test files needed exist

  if [ ! -e "${INVENTORY_FILE}" ]; then
    _echo "Could not find inventory file ${INVENTORY_FILE}. Please specify a path using -i or --inventory followed by the path";
    return 1;
  fi

  if [ ! -e "${PLAYBOOK_PATH}" ]; then
    _echo "Could not find playbook to run at ${PLAYBOOK_PATH}. Please specify a path using -p or --playbook followed by the path";
    return 1;
  fi

  if [ ! -e "${ANSIBLE_ROLES_FILE}" ]; then
    _echo "Could not find roles to install at ${ANSIBLE_ROLES_FILE}. Please specify a path using --rfile followed by the path";
    return 1;
  fi

  if [ ! -e "${ANSIBLE_VAULT_PASSWORD_FILE}" ]; then
    if [ -z "${ANSIBLE_VAULT_PASSWORD}" ]; then
      _echo "No vault password file exists at and you did not supply a vault password".
      read -p 'Please enter the vault file password' ANSIBLE_VAULT_PASSWORD
    fi
    _echo "Creating vault password file at ${ANSIBLE_VAULT_PASSWORD_FILE}";
    echo "${ANSIBLE_VAULT_PASSWORD}" > "${ANSIBLE_VAULT_PASSWORD_FILE}";

  fi

  # Make sure we have virtualenv
  _echo 'Updating pip';
  pip install --upgrade --quiet pip;

  _echo 'Installing virtualenv';
  pip install --quiet --upgrade virtualenv virtualenvwrapper;

  # Start and run the virtualenv

    _echo "Creating virtualenv ${ANSIBLE_VENV}";
    /usr/local/bin/virtualenv ${ANSIBLE_VENV};
    source ./${ANSIBLE_VENV}/bin/activate


  # Install all the virtualenv requirements
  _echo "Installing module requirements via pip from ${REQUIREMENTS_PIP_FILE}";
  pip install --quiet -r "${REQUIREMENTS_PIP_FILE}";

  _echo "Installing ansible plugins to ${ANSIBLE_ACTION_PLUGINS_PATH}";
  _get_ansible_plugins "${ANSIBLE_ACTION_PLUGINS_PATH}";

  # Get the galaxy roles and install them
  _get_ansible_galaxy_roles "${ANSIBLE_ROLES_FILE}" "${ANSIBLE_ROLES_PATH}";

  _run_playbook \
    "${ANSIBLE_ROLES_PATH}" \
    "${ANSIBLE_ACTION_PLUGINS_PATH}" \
    "${INVENTORY_FILE}" \
    "${PLAYBOOK_PATH}" \
    "${PROVISION_HOSTNAME}" \
    "${ANSIBLE_VAULT_PASSWORD_FILE}" \
    ;

  _echo 'Deactivating virtual env';
  deactivate;
}

provision_box "${@}";
