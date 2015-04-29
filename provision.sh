#!/usr/bin/env bash

function provision_box() {
  local REQUIREMENTS_PIP_FILE='./requirements.pip.txt';
  local ANSIBLE_ROLES_FILE='requirements.yml';
  local ANSIBLE_ROLES_PATH='./galaxy'
  local INVENTORY_FILE='inventory';
  local PLAYBOOK_PATH='./provision.yml';
  local PROVISION_HOSTNAME='radley-qa-web1';
  local REMOTE_USER='root';
  local ANSIBLE_VENV='ansible-provision';

  echo 'Updating pip';
  pip install --upgrade pip;

  echo 'Installing virtualenv';
  pip install --upgrade virtualenv virtualenvwrapper;

  echo "Creating virtualenv ${ANSIBLE_VENV}"
  mkvirtualenv "${ANSIBLE_VENV}"
  workon "${ANSIBLE_VENV}"

  echo 'Installing module requirements via pip';
  pip install -r "${REQUIREMENTS_PIP_FILE}";

  echo 'Installing ansible roles from Galaxy';

  mkdir -p "${ANSIBLE_ROLES_PATH}";
  ansible-galaxy install \
    -r "${ANSIBLE_ROLES_FILE}" \
    -p "${ANSIBLE_ROLES_PATH}" \
    --force
  ;

  export ANSIBLE_ROLES_PATH="./galaxy"

  ansible-playbook -i "${INVENTORY_FILE}" \
    -vvvv \
    --user="${REMOTE_USER}" \
    --ask-vault-pass \
    "${PLAYBOOK_PATH}" \
    --extra-vars hostname_name="${PROVISION_HOSTNAME}"
    ;

  echo 'Deactivating virtual env'

  deactivate;
}

provision_box
