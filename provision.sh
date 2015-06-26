#!/usr/bin/env bash

function _echo() {
  echo -e "\033[1m\n${1}\n\033[0m";
  tput sgr0;
}

function _get_ansible_plugins() {
  local ANSIBLE_ACTION_PLUGINS_DIR=${1};

  mkdir -p ${ANSIBLE_ACTION_PLUGINS_DIR};
  git clone https://github.com/jurgenhaas/ansible-plugin-serverdensity.git "${ANSIBLE_ACTION_PLUGINS_DIR}/server-density";
}

# Read through the roles file and put roles in
# ${GALAXY_ROLES_PATH}

function _get_ansible_galaxy_roles() {
  local GALAXY_ROLES_FILE=${1};
  local GALAXY_ROLES_PATH=${2};

  _echo 'Installing ansible roles from Galaxy';
  mkdir -p "${GALAXY_ROLES_PATH}";
  ./venv/bin/ansible-galaxy install \
    -r "${GALAXY_ROLES_FILE}" \
    -p "${GALAXY_ROLES_PATH}" \
    --force \
  ;
}

# Runs the playbook itself

function _run_playbook() {
  local INVENTORY_FILE="${3}";
  local PLAYBOOK_PATH="${4}";
  local PROVISION_HOSTNAME="${5}";
  local VAULT_PASSWORD_FILE="${6}";

  _echo "Running playbook ${PLAYBOOK_PATH}";

  ( export ANSIBLE_ROLES_PATH=${1}; \
    export ANSIBLE_ACTION_PLUGINS=${2}; \
    export ANSIBLE_HOST_KEY_CHECKING='no'; \
    export RAX_USERNAME='leftfielddigital'; \
    export RAX_API_KEY='bbb3943746f0d83ec9102333c4a9c716'; \
    export RAX_REGION='DFW'; \
    ./venv/bin/ansible-playbook -i "${INVENTORY_FILE}" \
      -vvvv \
      --user="${REMOTE_USER}" \
      --vault-password-file  "${VAULT_PASSWORD_FILE}"\
      "${PLAYBOOK_PATH}" \
  );
}

function provision_box() {

  local ANSIBLE_ROLES_FILE='requirements.yml';
  local ANSIBLE_ROLES_PATH='./galaxy'
  local ANSIBLE_ACTION_PLUGINS_PATH='./plugins/action_plugins';
  local REMOTE_USER='root';
  local REQUIREMENTS_PIP_FILE='./requirements.pip.txt';
  local INVENTORY_FILE='./inventory';
  local PLAYBOOK_PATH='./provision.yml';
  local ANSIBLE_VENV='venv';

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
  _echo 'Updating pip';
  pip install --upgrade pip;

  _echo 'Installing virtualenv';
  pip install --upgrade virtualenv virtualenvwrapper;

  # Start and run the virtualenv

    echo "Creating virtualenv ${ANSIBLE_VENV}";
    /usr/local/bin/virtualenv --clear ${ANSIBLE_VENV};
    source ./${ANSIBLE_VENV}/bin/activate


  # Install all the virtualenv requirements
  _echo "Installing module requirements via pip from ${REQUIREMENTS_PIP_FILE}";
  pip install -r "${REQUIREMENTS_PIP_FILE}";

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

provision_box "${@}"
