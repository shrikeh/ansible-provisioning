#!/usr/bin/env bash

function provision_box() {
  local REQUIREMENTS_ROLES_FILE='requirements.yml'
  local INVENTORY_FILE='inventory'
  ansible-galaxy install --force -r "${REQUIREMENTS_ROLES_FILE}"
  ansible-playbook -i "${INVENTORY_FILE}" ./do.yml --ask-vault-pass
}
