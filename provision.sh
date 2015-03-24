#!/usr/bin/env bash

function provision_box() {
  local REQUIREMENTS_PIP_FILE='./requirements.pip.txt';
  local REQUIREMENTS_ROLES_FILE='requirements.yml';
  local INVENTORY_FILE='inventory';
  local PLAYBOOK_PATH='./provision.yml';

  pip install -r "${REQUIREMENTS_PIP_FILE}";
  ansible-galaxy install --force -r "${REQUIREMENTS_ROLES_FILE}";
  ansible-playbook -i "${INVENTORY_FILE}" \
  --ask-vault-pass \
  "${PLAYBOOK_PATH}" -vvvv
}

provision_box
